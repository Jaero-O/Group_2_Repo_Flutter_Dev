import 'package:flutter/material.dart';

import '../../model/risk_assessment.dart';
import '../../model/weather_data.dart';
import '../../services/local_db.dart';
import '../../services/risk_calculator.dart';

class AnthracnoseRiskForecastCard extends StatefulWidget {
  final int? treeId;
  final WeatherData? weather;

  const AnthracnoseRiskForecastCard({super.key, this.treeId, this.weather});

  @override
  State<AnthracnoseRiskForecastCard> createState() =>
      _AnthracnoseRiskForecastCardState();
}

class _AnthracnoseRiskForecastCardState
    extends State<AnthracnoseRiskForecastCard> {
  late Future<_AnalyticsData> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _loadAnalytics();
  }

  @override
  void didUpdateWidget(covariant AnthracnoseRiskForecastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.treeId != widget.treeId ||
        oldWidget.weather != widget.weather) {
      setState(() {
        _analyticsFuture = _loadAnalytics();
      });
    }
  }

  Future<_AnalyticsData> _loadAnalytics() async {
    final results = await Future.wait([
      LocalDb.instance.getAnthracnoseStageSummary(treeId: widget.treeId),
      LocalDb.instance.getDiseaseWeeklyTrendSeries(
        diseaseKeyword: 'anthracnose',
        treeId: widget.treeId,
      ),
    ]);

    final stage = results[0] as Map<String, int>;
    final trend = results[1] as List<Map<String, dynamic>>;

    final assessment = RiskCalculator.computeRisk(
      stageSummary: stage,
      weeklyTrend: trend,
      weather: widget.weather,
    );

    final latestWeekCount = _countAt(trend, trend.length - 1);
    final trendDirection = _resolveTrendDirection(trend);

    return _AnalyticsData(
      stage: stage,
      trend: trend,
      latestWeekCount: latestWeekCount,
      trendDirection: trendDirection,
      assessment: assessment,
      weather: widget.weather,
    );
  }

  int _countAt(List<Map<String, dynamic>> rows, int index) {
    if (index < 0 || index >= rows.length) return 0;
    final value = rows[index]['count'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  TrendDirection _resolveTrendDirection(List<Map<String, dynamic>> trend) {
    if (trend.length < 2) return TrendDirection.stable;

    final latest = _countAt(trend, trend.length - 1);
    final baseline = _countAt(trend, trend.length - 3);
    final change = latest - baseline;

    if (change > 0) return TrendDirection.worsening;
    if (change < 0) return TrendDirection.improving;
    return TrendDirection.stable;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AnalyticsData>(
      future: _analyticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 210,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ?? _AnalyticsData.empty();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
              child: Text(
                'Anthracnose Risk & Forecast',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555555),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Anthracnose model',
                          style: TextStyle(
                            color: Color(0xFF00695C),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: data.weather == null
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          data.weather == null
                              ? 'Weather unavailable'
                              : 'Weather cached',
                          style: TextStyle(
                            color: data.weather == null
                                ? const Color(0xFFEF6C00)
                                : const Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Infection Risk',
                          value:
                              '${(data.assessment.infectionProbability * 100).toStringAsFixed(1)}%',
                          subtitle: data.riskLevelLabel,
                          valueColor: data.riskColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Yield Loss Est.',
                          value:
                              '${(data.assessment.estimatedYieldLoss * 100).toStringAsFixed(1)}%',
                          subtitle: 'Potential fruit loss',
                          valueColor: const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Weather Factor',
                          value: data.weatherFactorLabel,
                          subtitle: data.weatherFactorSubtitle,
                          valueColor: data.weatherFactorColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Data Confidence',
                          value:
                              '${(data.assessment.dataConfidence * 100).toStringAsFixed(0)}%',
                          subtitle: '${data.latestWeekCount} this week',
                          valueColor: const Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StageBar(
                    healthy: data.healthy,
                    early: data.early,
                    advanced: data.advanced,
                    total: data.total,
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      data.insightText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

enum TrendDirection { improving, stable, worsening }

class _AnalyticsData {
  final Map<String, int> stage;
  final List<Map<String, dynamic>> trend;
  final int latestWeekCount;
  final TrendDirection trendDirection;
  final RiskAssessment assessment;
  final WeatherData? weather;

  const _AnalyticsData({
    required this.stage,
    required this.trend,
    required this.latestWeekCount,
    required this.trendDirection,
    required this.assessment,
    required this.weather,
  });

  factory _AnalyticsData.empty() {
    return const _AnalyticsData(
      stage: <String, int>{'healthy': 0, 'early': 0, 'advanced': 0, 'total': 0},
      trend: <Map<String, dynamic>>[],
      latestWeekCount: 0,
      trendDirection: TrendDirection.stable,
      assessment: RiskAssessment(
        infectionProbability: 0.01,
        estimatedYieldLoss: 0.0,
        riskLevel: RiskLevel.low,
        weatherContribution: 0.5,
        trendContribution: 0.5,
        dataConfidence: 0,
      ),
      weather: null,
    );
  }

  int get healthy => stage['healthy'] ?? 0;
  int get early => stage['early'] ?? 0;
  int get advanced => stage['advanced'] ?? 0;
  int get total => stage['total'] ?? 0;

  String get riskLevelLabel {
    switch (assessment.riskLevel) {
      case RiskLevel.low:
        return 'Low risk';
      case RiskLevel.moderate:
        return 'Moderate risk';
      case RiskLevel.high:
        return 'High risk';
      case RiskLevel.critical:
        return 'Critical risk';
    }
  }

  Color get riskColor {
    switch (assessment.riskLevel) {
      case RiskLevel.low:
        return const Color(0xFF2E7D32);
      case RiskLevel.moderate:
        return const Color(0xFFF9A825);
      case RiskLevel.high:
        return const Color(0xFFEF6C00);
      case RiskLevel.critical:
        return const Color(0xFFC62828);
    }
  }

  String get weatherFactorLabel {
    final value = assessment.weatherContribution;
    if (value >= 0.66) return 'High';
    if (value >= 0.33) return 'Moderate';
    return 'Low';
  }

  String get weatherFactorSubtitle {
    if (weather == null) {
      return 'No weather input';
    }
    return 'H:${weather!.humidityPct.toStringAsFixed(0)}% '
        'T:${weather!.temperatureCelsius.toStringAsFixed(1)}C '
        'R:${weather!.rainfallMm.toStringAsFixed(1)}mm';
  }

  Color get weatherFactorColor {
    final value = assessment.weatherContribution;
    if (value >= 0.66) return const Color(0xFFC62828);
    if (value >= 0.33) return const Color(0xFFEF6C00);
    return const Color(0xFF2E7D32);
  }

  String get insightText {
    if (total <= 0) {
      return 'No anthracnose stage history is available yet. Continue regular scanning to improve the prediction model confidence.';
    }

    final riskPct = (assessment.infectionProbability * 100).toStringAsFixed(1);
    final yieldPct = (assessment.estimatedYieldLoss * 100).toStringAsFixed(1);

    if (assessment.riskLevel == RiskLevel.critical ||
        assessment.riskLevel == RiskLevel.high) {
      return 'High infection probability detected ($riskPct%). Estimated yield loss could reach around $yieldPct%. Prioritize rapid fungicide action and remove heavily infected tissues.';
    }

    if (trendDirection == TrendDirection.worsening) {
      return 'Trend is worsening with projected infection risk at $riskPct%. Tighten sanitation and canopy management now to limit further fruit loss.';
    }

    if (trendDirection == TrendDirection.improving) {
      return 'Trend is improving. Current infection risk is $riskPct% with estimated yield loss near $yieldPct%. Maintain treatment consistency and weekly inspections.';
    }

    return 'Risk remains stable at $riskPct% with estimated yield loss near $yieldPct%. Keep monitoring conditions and sustain preventive controls.';
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _StageBar extends StatelessWidget {
  final int healthy;
  final int early;
  final int advanced;
  final int total;

  const _StageBar({
    required this.healthy,
    required this.early,
    required this.advanced,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 0) {
      return const Text(
        'No anthracnose records yet.',
        style: TextStyle(fontSize: 12, color: Colors.black45),
      );
    }

    final healthyFlex = healthy <= 0 ? 1 : healthy;
    final earlyFlex = early <= 0 ? 1 : early;
    final advancedFlex = advanced <= 0 ? 1 : advanced;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stage mix (scan history)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: healthyFlex,
                  child: const ColoredBox(color: Color(0xFF2E7D32)),
                ),
                Expanded(
                  flex: earlyFlex,
                  child: const ColoredBox(color: Color(0xFFF9A825)),
                ),
                Expanded(
                  flex: advancedFlex,
                  child: const ColoredBox(color: Color(0xFFC62828)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Healthy: $healthy   Early: $early   Advanced: $advanced',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
