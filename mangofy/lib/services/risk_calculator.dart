import 'dart:math' as math;

import '../model/risk_assessment.dart';
import '../model/weather_data.dart';

class RiskCalculator {
  const RiskCalculator._();

  static RiskAssessment computeRisk({
    required Map<String, int> stageSummary,
    required List<Map<String, dynamic>> weeklyTrend,
    WeatherData? weather,
  }) {
    final early = stageSummary['early'] ?? 0;
    final advanced = stageSummary['advanced'] ?? 0;
    final total = stageSummary['total'] ?? 0;

    final prior = _clampDouble(
      total <= 0 ? 0.05 : (early + advanced) / total,
      0.05,
      0.95,
    );

    final trendSlope = _linearRegressionSlope(
      weeklyTrend.map((row) => _toDouble(row['count'])).toList(growable: false),
    );
    final lastWeekCount = weeklyTrend.isNotEmpty
        ? _toDouble(weeklyTrend.last['count'])
        : 1.0;
    final trendDelta = _clampDouble(
      trendSlope / math.max(1.0, lastWeekCount),
      -0.4,
      0.6,
    );
    final trendLikelihood = 1.0 + trendDelta;

    final weatherLikelihood = _weatherLikelihood(weather);

    final unnormalized = prior * trendLikelihood * weatherLikelihood;
    final inverseTrend = _clampDouble(2.0 - trendLikelihood, 0.4, 2.2);
    final inverseWeather = _clampDouble(2.0 - weatherLikelihood, 0.4, 2.2);
    final denominator =
        unnormalized + ((1 - prior) * inverseTrend * inverseWeather);

    final posterior = denominator <= 0 ? prior : (unnormalized / denominator);
    final infectionProbability = _clampDouble(posterior, 0.01, 0.99);

    final earlyPct = total <= 0 ? 0.0 : early / total;
    final advancedPct = total <= 0 ? 0.0 : advanced / total;
    final estimatedYieldLoss = _clampDouble(
      (advancedPct * 0.75) + (earlyPct * 0.30),
      0.0,
      1.0,
    );

    final riskLevel = infectionProbability >= 0.70
        ? RiskLevel.critical
        : infectionProbability >= 0.45
        ? RiskLevel.high
        : infectionProbability >= 0.20
        ? RiskLevel.moderate
        : RiskLevel.low;

    final weatherContribution = _clampDouble(
      (weatherLikelihood - 0.5) / 1.5,
      0,
      1,
    );
    final trendContribution = _clampDouble((trendLikelihood - 0.6) / 1.0, 0, 1);
    final dataConfidence = _clampDouble(total / 30.0, 0, 1);

    return RiskAssessment(
      infectionProbability: infectionProbability,
      estimatedYieldLoss: estimatedYieldLoss,
      riskLevel: riskLevel,
      weatherContribution: weatherContribution,
      trendContribution: trendContribution,
      dataConfidence: dataConfidence,
    );
  }

  static double weatherRiskFactor(WeatherData? weather) {
    if (weather == null) return 0.5;

    final temp = weather.temperatureCelsius;
    final humidity = weather.humidityPct;
    final rain = weather.rainfallMm;

    final tempFactor = (temp >= 25 && temp <= 32)
        ? 1.5
        : (temp >= 20 && temp <= 35)
        ? 1.1
        : 0.7;
    final humidityFactor = humidity > 85
        ? 1.8
        : humidity > 70
        ? 1.3
        : 0.8;
    final rainFactor = rain > 0 ? 2.0 : 1.0;

    final normalized = ((humidityFactor * tempFactor * rainFactor) - 1.0) / 3.0;
    return _clampDouble(normalized, 0.0, 1.0);
  }

  static double _weatherLikelihood(WeatherData? weather) {
    final normalized = weatherRiskFactor(weather);
    return _clampDouble(0.5 + (normalized * 1.5), 0.5, 2.0);
  }

  static double _linearRegressionSlope(List<double> values) {
    if (values.length < 2) return 0;

    final sample = values.length > 5
        ? values.sublist(values.length - 5)
        : values;

    final n = sample.length;
    final xMean = (n - 1) / 2.0;
    final yMean = sample.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double denominator = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = sample[i];
      numerator += (x - xMean) * (y - yMean);
      denominator += (x - xMean) * (x - xMean);
    }

    if (denominator == 0) return 0;
    return numerator / denominator;
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _clampDouble(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
