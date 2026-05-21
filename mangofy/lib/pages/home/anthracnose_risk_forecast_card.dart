import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../model/risk_assessment.dart';
import '../../model/weather_data.dart';
import '../../services/local_db.dart';
import '../../services/risk_calculator.dart';

class AnthracnoseRiskForecastCard extends StatefulWidget {
  final int? treeId;
  final WeatherData? weather;
  final List<Map<String, dynamic>> stageSeries;

  const AnthracnoseRiskForecastCard({
    super.key,
    this.treeId,
    this.weather,
    this.stageSeries = const <Map<String, dynamic>>[],
  });

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
        oldWidget.weather != widget.weather ||
        !_sameStageSeries(oldWidget.stageSeries, widget.stageSeries)) {
      setState(() {
        _analyticsFuture = _loadAnalytics();
      });
    }
  }

  bool _sameStageSeries(
    List<Map<String, dynamic>> left,
    List<Map<String, dynamic>> right,
  ) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;

    int readInt(Map<String, dynamic> row, String key) {
      final value = row[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    for (int i = 0; i < left.length; i++) {
      final a = left[i];
      final b = right[i];
      if ((a['week']?.toString() ?? '') != (b['week']?.toString() ?? '')) {
        return false;
      }
      if (readInt(a, 'healthy') != readInt(b, 'healthy')) return false;
      if (readInt(a, 'early') != readInt(b, 'early')) return false;
      if (readInt(a, 'advanced') != readInt(b, 'advanced')) return false;
      if (readInt(a, 'total') != readInt(b, 'total')) return false;
    }
    return true;
  }

  Future<_AnalyticsData> _loadAnalytics() async {
    final result = await Future.wait<dynamic>([
      LocalDb.instance.getAnthracnoseStageSummary(treeId: widget.treeId),
      LocalDb.instance.getAnthracnoseSeverityAverages(treeId: widget.treeId),
    ]);
    final stage = result[0] as Map<String, int>;
    final severityAverages = result[1] as Map<String, double>;
    final trend = widget.stageSeries;

    final assessment = RiskCalculator.computeRisk(
      stageSummary: stage,
      weeklyTrend: trend,
      stageTrend: trend,
      weather: widget.weather,
      averageEarlySeverityPct: severityAverages['early'],
      averageAdvancedSeverityPct: severityAverages['advanced'],
    );

    final latestWeekCount = _countAt(trend, trend.length - 1);
    final trendDirection = _resolveTrendDirection(trend);
    final forecast = RiskCalculator.computeDailyForecast(
      baseAssessment: assessment,
      weather: widget.weather,
      days: 7,
    );
    final today = DateTime.now();
    final forecastStart = DateTime(today.year, today.month, today.day);
    final dailyForecast = List<_DailyForecast>.generate(
      forecast.length,
      (index) => _DailyForecast(
        probability: forecast[index],
        date: forecastStart.add(Duration(days: index)),
      ),
      growable: false,
    );

    return _AnalyticsData(
      stage: stage,
      trend: trend,
      latestWeekCount: latestWeekCount,
      trendDirection: trendDirection,
      assessment: assessment,
      weather: widget.weather,
      dailyForecast: dailyForecast,
    );
  }

  int _countAt(List<Map<String, dynamic>> rows, int index) {
    if (index < 0 || index >= rows.length) return 0;
    final value = rows[index]['total'] ?? rows[index]['count'];
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
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  if (data.dailyForecast.isNotEmpty) ...[
                    const Text(
                      '7-DAY INFECTION FORECAST',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ForecastTimeline(
                      forecast: data.dailyForecast,
                      peakIndex: data.peakDayIndex,
                      sprayStartIndex: data.sprayStartIndex,
                    ),
                    const SizedBox(height: 10),
                    const _ForecastLegend(),
                    if (data.sprayStartDate != null &&
                        data.sprayEndDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1B5E20),
                                height: 1.45,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Recommended spray window\n',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${_monthDayLabel(data.sprayStartDate!)} - ${_monthDayLabel(data.sprayEndDate!)} - Apply fungicide before peak risk. Conditions favour rapid spore spread during this window.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (data.shouldShowPeakRiskAlert)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1B5E20),
                                height: 1.45,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Peak risk: ${_monthDayLabel(data.peakDate!)}\n',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      'Projected infection probability reaches ${(data.peakProbability * 100).toStringAsFixed(0)}% (${data.peakRiskLabel}). Minimize leaf wetness and avoid pruning on this day.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
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
  final List<_DailyForecast> dailyForecast;

  const _AnalyticsData({
    required this.stage,
    required this.trend,
    required this.latestWeekCount,
    required this.trendDirection,
    required this.assessment,
    required this.weather,
    required this.dailyForecast,
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
      dailyForecast: <_DailyForecast>[],
    );
  }

  int get healthy => stage['healthy'] ?? 0;
  int get early => stage['early'] ?? 0;
  int get advanced => stage['advanced'] ?? 0;
  int get total => stage['total'] ?? 0;

  int get peakDayIndex {
    if (dailyForecast.isEmpty) return -1;
    int bestIndex = 0;
    double bestValue = dailyForecast.first.probability;
    for (int i = 1; i < dailyForecast.length; i++) {
      final value = dailyForecast[i].probability;
      if (value > bestValue) {
        bestValue = value;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  int? get sprayStartIndex {
    for (int i = 0; i < dailyForecast.length; i++) {
      if (dailyForecast[i].probability >= 0.45) return i;
    }
    return null;
  }

  int? get sprayEndIndex {
    final start = sprayStartIndex;
    if (start == null) return null;

    int end = start;
    for (int i = start + 1; i < dailyForecast.length; i++) {
      if (dailyForecast[i].probability >= 0.45) {
        end = i;
      } else {
        break;
      }
    }
    return end;
  }

  DateTime? get sprayStartDate {
    final index = sprayStartIndex;
    if (index == null || index < 0 || index >= dailyForecast.length) {
      return null;
    }
    return dailyForecast[index].date;
  }

  DateTime? get sprayEndDate {
    final index = sprayEndIndex;
    if (index == null || index < 0 || index >= dailyForecast.length) {
      return null;
    }
    return dailyForecast[index].date;
  }

  bool get shouldShowPeakRiskAlert => peakProbability >= 0.45;

  DateTime? get peakDate {
    final index = peakDayIndex;
    if (index < 0 || index >= dailyForecast.length) return null;
    return dailyForecast[index].date;
  }

  double get peakProbability {
    final index = peakDayIndex;
    if (index < 0 || index >= dailyForecast.length) return 0.0;
    return dailyForecast[index].probability;
  }

  String get peakRiskLabel {
    final value = peakProbability;
    if (value >= 0.70) return 'Critical';
    if (value >= 0.45) return 'High';
    if (value >= 0.20) return 'Moderate';
    return 'Low';
  }

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

class _DailyForecast {
  final double probability;
  final DateTime date;

  const _DailyForecast({required this.probability, required this.date});
}

class _ForecastTimeline extends StatefulWidget {
  final List<_DailyForecast> forecast;
  final int peakIndex;
  final int? sprayStartIndex;

  const _ForecastTimeline({
    required this.forecast,
    required this.peakIndex,
    required this.sprayStartIndex,
  });

  @override
  State<_ForecastTimeline> createState() => _ForecastTimelineState();
}

class _ForecastTimelineState extends State<_ForecastTimeline> {
  int? _selectedIndex;
  Timer? _tooltipHideTimer;

  void _cancelHideTooltip() {
    _tooltipHideTimer?.cancel();
    _tooltipHideTimer = null;
  }

  void _scheduleHideTooltip() {
    _cancelHideTooltip();
    _tooltipHideTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _selectedIndex == null) return;
      setState(() {
        _selectedIndex = null;
      });
    });
  }

  @override
  void dispose() {
    _cancelHideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forecast.isEmpty) {
      return const SizedBox.shrink();
    }

    const chartHeight = 160.0;
    const leftPad = 28.0;
    const rightPad = 8.0;
    const topPad = 20.0;
    const bottomPad = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = math.max(
          constraints.maxWidth - leftPad - rightPad,
          1.0,
        );
        final segmentWidth = chartWidth / widget.forecast.length;

        double xForIndex(int index) {
          return leftPad + ((index + 0.5) * segmentWidth);
        }

        double yForProbability(double probability) {
          final clamped = probability.clamp(0.0, 1.0);
          final chartTop = topPad;
          final chartBottom = chartHeight - bottomPad;
          final usableHeight = chartBottom - chartTop;
          return chartBottom - (clamped * usableHeight);
        }

        int nearestIndex(double localX) {
          final normalizedX = (localX - leftPad).clamp(0.0, chartWidth);
          final raw = (normalizedX / segmentWidth) - 0.5;
          return raw.round().clamp(0, widget.forecast.length - 1);
        }

        void updateSelection(double localX) {
          _cancelHideTooltip();
          final next = nearestIndex(localX);
          if (_selectedIndex != next) {
            setState(() {
              _selectedIndex = next;
            });
          }
        }

        final selected = _selectedIndex;

        final hasPeak =
            widget.peakIndex >= 0 && widget.peakIndex < widget.forecast.length;
        final hasSpray =
            widget.sprayStartIndex != null &&
            widget.sprayStartIndex! >= 0 &&
            widget.sprayStartIndex! < widget.forecast.length;
        final sameIndex =
            hasPeak && hasSpray && widget.peakIndex == widget.sprayStartIndex;

        return Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => updateSelection(details.localPosition.dx),
              onTapUp: (_) => _scheduleHideTooltip(),
              onTapCancel: _scheduleHideTooltip,
              onHorizontalDragStart: (details) =>
                  updateSelection(details.localPosition.dx),
              onHorizontalDragUpdate: (details) =>
                  updateSelection(details.localPosition.dx),
              onHorizontalDragEnd: (_) => _scheduleHideTooltip(),
              onHorizontalDragCancel: _scheduleHideTooltip,
              child: SizedBox(
                height: chartHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ForecastTimelinePainter(
                          forecast: widget.forecast,
                          peakIndex: widget.peakIndex,
                          sprayStartIndex: widget.sprayStartIndex,
                          highlightedIndex: selected,
                        ),
                      ),
                    ),
                    if (hasPeak)
                      Positioned(
                        left: xForIndex(widget.peakIndex) - 20,
                        top: math.max(
                          0,
                          yForProbability(
                                widget.forecast[widget.peakIndex].probability,
                              ) -
                              32,
                        ),
                        child: const _ForecastTag(
                          label: 'Peak',
                          color: Color(0xFFC62828),
                        ),
                      ),
                    if (hasSpray)
                      Positioned(
                        left: xForIndex(widget.sprayStartIndex!) - 22,
                        top: math.max(
                          0,
                          yForProbability(
                                widget
                                    .forecast[widget.sprayStartIndex!]
                                    .probability,
                              ) -
                              (sameIndex ? 14 : 32),
                        ),
                        child: const _ForecastTag(
                          label: 'Spray',
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    if (selected != null)
                      Positioned(
                        left: (xForIndex(selected) - 36).clamp(2.0, chartWidth),
                        top: math.max(
                          0,
                          yForProbability(
                                widget.forecast[selected].probability,
                              ) -
                              54,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(widget.forecast[selected].probability * 100).toStringAsFixed(1)}% - ${_monthDayLabel(widget.forecast[selected].date)}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final item in widget.forecast)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _weekdayLabel(item.date),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFEF6C00),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _monthDayLabel(item.date),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF777777),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ForecastTimelinePainter extends CustomPainter {
  static const _leftPad = 28.0;
  static const _rightPad = 8.0;
  static const _topPad = 20.0;
  static const _bottomPad = 10.0;

  final List<_DailyForecast> forecast;
  final int peakIndex;
  final int? sprayStartIndex;
  final int? highlightedIndex;

  _ForecastTimelinePainter({
    required this.forecast,
    required this.peakIndex,
    required this.sprayStartIndex,
    required this.highlightedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (forecast.isEmpty) return;

    final chartRect = Rect.fromLTRB(
      _leftPad,
      _topPad,
      size.width - _rightPad,
      size.height - _bottomPad,
    );

    if (chartRect.width <= 0 || chartRect.height <= 0) return;

    final chartBackground = Paint()..color = const Color(0xFFF8F8F8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chartRect, const Radius.circular(10)),
      chartBackground,
    );

    final segmentWidth = chartRect.width / forecast.length;
    final points = <Offset>[];
    for (int i = 0; i < forecast.length; i++) {
      final probability = forecast[i].probability.clamp(0.0, 1.0);
      final x = chartRect.left + ((i + 0.5) * segmentWidth);
      final y = chartRect.bottom - (probability * chartRect.height);
      points.add(Offset(x, y));
    }

    void drawThreshold(double threshold, String label) {
      final y = chartRect.bottom - (threshold * chartRect.height);
      final linePaint = Paint()
        ..color = const Color(0xFFDBDBDB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      const dash = 5.0;
      const gap = 4.0;

      double x = chartRect.left;
      while (x < chartRect.right) {
        final endX = math.min(x + dash, chartRect.right);
        canvas.drawLine(Offset(x, y), Offset(endX, y), linePaint);
        x += dash + gap;
      }

      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9A9A9A),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(
          chartRect.right - labelPainter.width - 2,
          y - labelPainter.height,
        ),
      );
    }

    drawThreshold(0.20, '20%');
    drawThreshold(0.45, '45%');
    drawThreshold(0.70, '70%');

    final peakProbability = peakIndex >= 0 && peakIndex < forecast.length
        ? forecast[peakIndex].probability
        : forecast.fold<double>(
            0,
            (current, item) => math.max(current, item.probability),
          );
    final peakColor = _forecastColor(peakProbability);

    final areaPath = Path()
      ..moveTo(points.first.dx, chartRect.bottom)
      ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      areaPath.lineTo(points[i].dx, points[i].dy);
    }
    areaPath
      ..lineTo(points.last.dx, chartRect.bottom)
      ..close();

    final areaPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          peakColor.withValues(alpha: 0.22),
          peakColor.withValues(alpha: 0.02),
        ],
      ).createShader(chartRect);
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6;
    for (int i = 0; i < points.length - 1; i++) {
      final segmentRisk = math.max(
        forecast[i].probability,
        forecast[i + 1].probability,
      );
      linePaint.color = _forecastColor(segmentRisk);
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    final dotFillPaint = Paint()..style = PaintingStyle.fill;
    final dotStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white;

    final hasPeak = peakIndex >= 0 && peakIndex < forecast.length;
    final hasSpray =
        sprayStartIndex != null &&
        sprayStartIndex! >= 0 &&
        sprayStartIndex! < forecast.length;

    for (int i = 0; i < points.length; i++) {
      final isPeak = hasPeak && i == peakIndex;
      final isSpray = hasSpray && i == sprayStartIndex;

      double radius = 5;
      if (isPeak || isSpray) radius = 7;

      Color color = _forecastColor(forecast[i].probability);
      if (isSpray) color = const Color(0xFF1E88E5);
      if (isPeak) color = const Color(0xFFC62828);

      dotFillPaint.color = color;
      canvas.drawCircle(points[i], radius, dotFillPaint);
      canvas.drawCircle(points[i], radius, dotStrokePaint);

      if (isPeak && isSpray) {
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = const Color(0xFF1E88E5);
        canvas.drawCircle(points[i], radius + 2.3, ringPaint);
      }

      if (highlightedIndex != null && i == highlightedIndex) {
        final guidePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x8C212121);
        canvas.drawLine(
          Offset(points[i].dx, chartRect.top),
          Offset(points[i].dx, chartRect.bottom),
          guidePaint,
        );

        final selectedRing = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF212121);
        canvas.drawCircle(points[i], radius + 3, selectedRing);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ForecastTimelinePainter oldDelegate) {
    if (highlightedIndex != oldDelegate.highlightedIndex) return true;
    if (peakIndex != oldDelegate.peakIndex) return true;
    if (sprayStartIndex != oldDelegate.sprayStartIndex) return true;
    if (forecast.length != oldDelegate.forecast.length) return true;

    for (int i = 0; i < forecast.length; i++) {
      if (forecast[i].probability != oldDelegate.forecast[i].probability) {
        return true;
      }
      if (forecast[i].date != oldDelegate.forecast[i].date) {
        return true;
      }
    }

    return false;
  }
}

class _ForecastTag extends StatelessWidget {
  final String label;
  final Color color;

  const _ForecastTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ForecastLegend extends StatelessWidget {
  const _ForecastLegend();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _LegendItem(color: Color(0xFF4CAF50), label: 'Low <20%'),
          SizedBox(width: 10),
          _LegendItem(color: Color(0xFFF9A825), label: 'Moderate 20-44%'),
          SizedBox(width: 10),
          _LegendItem(color: Color(0xFFEF6C00), label: 'High 45-69%'),
          SizedBox(width: 10),
          _LegendItem(color: Color(0xFFC62828), label: 'Critical 70%+'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
      ],
    );
  }
}

Color _forecastColor(double probability) {
  if (probability >= 0.70) return const Color(0xFFC62828);
  if (probability >= 0.45) return const Color(0xFFEF6C00);
  if (probability >= 0.20) return const Color(0xFFF9A825);
  return const Color(0xFF2E7D32);
}

String _weekdayLabel(DateTime date) {
  const names = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[date.weekday - 1];
}

String _monthDayLabel(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
