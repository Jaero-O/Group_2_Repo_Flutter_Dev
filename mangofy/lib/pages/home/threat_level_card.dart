import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../services/local_db.dart';

enum ThreatLevel { low, moderate, high, critical }

extension ThreatLevelStyle on ThreatLevel {
  String get label {
    switch (this) {
      case ThreatLevel.low:
        return 'LOW';
      case ThreatLevel.moderate:
        return 'MODERATE';
      case ThreatLevel.high:
        return 'HIGH';
      case ThreatLevel.critical:
        return 'CRITICAL';
    }
  }

  Color get foreground {
    switch (this) {
      case ThreatLevel.low:
        return Colors.green;
      case ThreatLevel.moderate:
        return Colors.orange;
      case ThreatLevel.high:
        return Colors.red;
      case ThreatLevel.critical:
        return const Color(0xFF8B0000);
    }
  }

  Color get background {
    switch (this) {
      case ThreatLevel.low:
        return const Color(0xFFE6F4EA);
      case ThreatLevel.moderate:
        return const Color(0xFFFFF3E0);
      case ThreatLevel.high:
        return const Color(0xFFFFE5E5);
      case ThreatLevel.critical:
        return const Color(0xFFFFCDD2);
    }
  }
}

class PrimaryThreatCard extends StatefulWidget {
  final String diseaseName;
  final String scientificName;
  final int activeCases;
  final ThreatLevel threatLevel;
  final int weeklyTrendDelta;
  final List<double> trendData;
  final List<Map<String, dynamic>> stageSeries;
  final List<Map<String, dynamic>> perTreeImageSeries;
  final int? treeId;
  final int refreshKey;

  const PrimaryThreatCard({
    super.key,
    required this.diseaseName,
    required this.scientificName,
    required this.activeCases,
    required this.threatLevel,
    required this.weeklyTrendDelta,
    required this.trendData,
    this.stageSeries = const <Map<String, dynamic>>[],
    this.perTreeImageSeries = const <Map<String, dynamic>>[],
    this.treeId,
    this.refreshKey = 0,
  });

  @override
  State<PrimaryThreatCard> createState() => _PrimaryThreatCardState();
}

class _PrimaryThreatCardState extends State<PrimaryThreatCard> {
  final GlobalKey<_AnthracnoseStageChartState> _chartKey =
      GlobalKey<_AnthracnoseStageChartState>();

  @override
  Widget build(BuildContext context) {
    final bool isTrendUp = widget.weeklyTrendDelta > 0;
    final bool isTrendDown = widget.weeklyTrendDelta < 0;
    final Color trendColor = isTrendUp
        ? Colors.red
        : (isTrendDown ? Colors.green : Colors.blueGrey);
    final IconData trendIcon = isTrendUp
        ? Icons.arrow_upward
        : (isTrendDown ? Icons.arrow_downward : Icons.trending_flat);
    final String trendLabel;
    if (widget.weeklyTrendDelta > 0) {
      trendLabel = '+${widget.weeklyTrendDelta} cases this week';
    } else if (widget.weeklyTrendDelta < 0) {
      trendLabel = '${widget.weeklyTrendDelta} cases this week';
    } else {
      trendLabel = 'Stable this week';
    }
    final filterLabel = _chartKey.currentState?.filterLabel ?? 'Last 8 weeks';

    // FIX: need at least 2 points to draw the chart
    final bool hasChartData = widget.trendData.length >= 2;

    return Container(
      // FIX: removed margin — home_page handles spacing via SizedBox and padding
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.diseaseName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.scientificName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.activeCases}',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: widget.threatLevel.foreground,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'diseased scans',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(trendIcon, color: trendColor, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        trendLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: trendColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _chartKey.currentState?.openFilterSheet(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_list,
                        size: 12,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        filterLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _AnthracnoseStageChart(
            key: _chartKey,
            initialSeries: widget.stageSeries,
            initialPerTreeSeries: widget.perTreeImageSeries,
            treeId: widget.treeId,
            refreshKey: widget.refreshKey,
            onFilterChanged: () {
              if (!mounted) return;
              setState(() {});
            },
          ),
          if (widget.stageSeries.isEmpty && hasChartData)
            const SizedBox(height: 8),
          if (widget.stageSeries.isEmpty && hasChartData)
            _TrendChart(
              dataPoints: widget.trendData,
              color: widget.threatLevel.foreground,
            ),
        ],
      ),
    );
  }
}

class _AnthracnoseStageChart extends StatefulWidget {
  final List<Map<String, dynamic>> initialSeries;
  final List<Map<String, dynamic>> initialPerTreeSeries;
  final int? treeId;
  final int refreshKey;
  final VoidCallback? onFilterChanged;

  const _AnthracnoseStageChart({
    super.key,
    required this.initialSeries,
    required this.initialPerTreeSeries,
    required this.treeId,
    required this.refreshKey,
    this.onFilterChanged,
  });

  @override
  State<_AnthracnoseStageChart> createState() => _AnthracnoseStageChartState();
}

class _AnthracnoseStageChartState extends State<_AnthracnoseStageChart> {
  static const int _weekWindow = 8;

  int? _selectedMonth;
  int? _selectedYear;
  int? _hoveredIndex;
  bool _isLoading = false;
  List<Map<String, dynamic>> _monthOptions = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _series = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _perTreeSeries = const <Map<String, dynamic>>[];

  String get filterLabel => (_selectedMonth == null || _selectedYear == null)
      ? 'Last $_weekWindow weeks'
      : '${_monthName(_selectedMonth!)} $_selectedYear';

  void openFilterSheet() => _showFilterSheet();

  @override
  void initState() {
    super.initState();
    if (widget.initialSeries.length > _weekWindow) {
      _series = widget.initialSeries.sublist(
        widget.initialSeries.length - _weekWindow,
      );
    } else {
      _series = widget.initialSeries;
    }
    _perTreeSeries = widget.initialPerTreeSeries;
    _loadMonthOptions();
  }

  @override
  void didUpdateWidget(covariant _AnthracnoseStageChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.treeId != widget.treeId ||
        oldWidget.refreshKey != widget.refreshKey) {
      _hoveredIndex = null;
      _loadMonthOptions();
      _reloadSeries();
      return;
    }

    if (oldWidget.initialSeries != widget.initialSeries &&
        _selectedMonth == null &&
        _selectedYear == null) {
      setState(() {
        _series = widget.initialSeries;
        _perTreeSeries = widget.initialPerTreeSeries;
        _hoveredIndex = null;
      });
    }

    if (oldWidget.initialPerTreeSeries != widget.initialPerTreeSeries &&
        _selectedMonth == null &&
        _selectedYear == null) {
      setState(() {
        _perTreeSeries = widget.initialPerTreeSeries;
      });
    }
  }

  Future<void> _loadMonthOptions() async {
    final options = await LocalDb.instance.getSeverityTrendMonthOptions(
      treeId: widget.treeId,
      usePhotoTimestamps: true,
    );
    if (!mounted) return;
    setState(() {
      _monthOptions = options;
    });
  }

  Future<void> _reloadSeries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        LocalDb.instance.getAnthracnoseWeeklyStageSeries(
          treeId: widget.treeId,
          weekWindow: _weekWindow,
          month: _selectedMonth,
          year: _selectedYear,
        ),
        LocalDb.instance.getAnthracnosePerTreeImageSeries(
          treeId: widget.treeId,
          month: _selectedMonth,
          year: _selectedYear,
          limit: 200,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _series = results[0];
        _perTreeSeries = results[1];
        _hoveredIndex = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter({int? month, int? year}) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = year;
    });
    widget.onFilterChanged?.call();
    _reloadSeries();
  }

  void _setHoveredFromDx({
    required double dx,
    required double width,
    required int count,
  }) {
    if (count < 2 || width <= 0) return;
    final clamped = dx.clamp(0, width).toDouble();
    final tapped = ((clamped / width) * (count - 1)).round();
    setState(() {
      _hoveredIndex = tapped;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Anthracnose Trend Filter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Last 8 weeks'),
                  trailing: (_selectedMonth == null && _selectedYear == null)
                      ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _applyFilter();
                  },
                ),
                if (_monthOptions.isNotEmpty) const Divider(height: 8),
                ..._monthOptions.map((item) {
                  final year = (item['year'] as int?) ?? 0;
                  final month = (item['month'] as int?) ?? 0;
                  final label = item['label']?.toString() ?? '$month/$year';
                  final isSelected =
                      _selectedYear == year && _selectedMonth == month;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                        : null,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _applyFilter(month: month, year: year);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  int _toInt(Map<String, dynamic> row, String key) {
    final raw = row[key];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) return month.toString();
    return names[month - 1];
  }

  String _compactCountLabel(double value) {
    final intVal = value.round();
    if (intVal >= 1000) {
      final k = intVal / 1000;
      return k == k.roundToDouble()
          ? '${k.toInt()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return intVal.toString();
  }

  double _toDouble(Map<String, dynamic> row, String key) {
    final raw = row[key];
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0.0;
  }

  DateTime? _parseImageDate(String raw) {
    if (raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw) ??
        DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  List<_PerTreePoint> _buildPerTreePoints(List<Map<String, dynamic>> rows) {
    final points = <_PerTreePoint>[];
    for (final row in rows) {
      final dateRaw = row['image_date']?.toString() ?? '';
      final parsedDate = _parseImageDate(dateRaw);
      if (parsedDate == null) continue;
      final normalizedDate = parsedDate.isUtc ? parsedDate.toLocal() : parsedDate;
      final treeName = (row['tree_name']?.toString().trim().isNotEmpty ?? false)
          ? row['tree_name'].toString().trim()
          : 'Unknown Tree';
      final stage = (row['stage']?.toString().trim().isNotEmpty ?? false)
          ? row['stage'].toString().trim()
          : 'healthy';

      points.add(
        _PerTreePoint(
          treeName: treeName,
          date: normalizedDate,
          severityPct: _toDouble(row, 'severity_pct').clamp(0.0, 100.0),
          stage: stage,
        ),
      );
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final perTreePoints = _buildPerTreePoints(_perTreeSeries);

    if (_isLoading) {
      return const SizedBox(
        height: 112,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
      );
    }

    if (perTreePoints.length >= 2) {
      return _PerTreeImageChart(points: perTreePoints);
    }

    final healthy = _series
        .map((row) => _toInt(row, 'healthy').toDouble())
        .toList(growable: false);
    final early = _series
        .map((row) => _toInt(row, 'early').toDouble())
        .toList(growable: false);
    final advanced = _series
        .map((row) => _toInt(row, 'advanced').toDouble())
        .toList(growable: false);
    final labels = _series
        .map((row) => row['label']?.toString() ?? '')
        .toList(growable: false);

    final count = math.min(
      healthy.length,
      math.min(early.length, advanced.length),
    );
    final maxVal = count < 1
        ? 1.0
        : [
            ...healthy.take(count),
            ...early.take(count),
            ...advanced.take(count),
          ].reduce(math.max);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    final yTicks = <double>[safeMax, safeMax / 2, 0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: const [
            _StageLegendItem(label: 'Healthy', color: Color(0xFF2E7D32)),
            _StageLegendItem(label: 'Early Stage', color: Color(0xFFF9A825)),
            _StageLegendItem(label: 'Advanced Stage', color: Color(0xFFC62828)),
          ],
        ),
        const SizedBox(height: 8),
        if (count < 2)
          const SizedBox(
            height: 136,
            child: Center(
              child: Text(
                'No anthracnose trend data for this filter.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 136,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const chartHeight = 92.0;
                    const chartTopOffset = 30.0;
                    const yAxisWidth = 30.0;
                    const axisGap = 6.0;

                    double yFor(double value) {
                      final normalized = value / safeMax;
                      return chartTopOffset +
                          (chartHeight - normalized * chartHeight);
                    }

                    final int? hovered =
                        (_hoveredIndex != null &&
                            _hoveredIndex! >= 0 &&
                            _hoveredIndex! < count)
                        ? _hoveredIndex
                        : null;

                    final double chartWidth =
                        constraints.maxWidth - yAxisWidth - axisGap;
                    final double selectedX = (hovered != null && count > 1)
                        ? (hovered / (count - 1)) * chartWidth
                        : 0;

                    final double selectedY = hovered != null
                        ? math.min(
                            yFor(healthy[hovered]),
                            math.min(
                              yFor(early[hovered]),
                              yFor(advanced[hovered]),
                            ),
                          )
                        : 0;

                    final double tooltipLeft = hovered != null
                        ? math.max(
                            0,
                            math.min(chartWidth - 154, selectedX - 77),
                          )
                        : 0;
                    final double tooltipTop = hovered != null
                        ? math.max(0, math.min(72, selectedY - 58))
                        : 0;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: yAxisWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: chartTopOffset),
                            child: SizedBox(
                              height: chartHeight,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: yTicks
                                    .map(
                                      (v) => Text(
                                        _compactCountLabel(v),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: axisGap),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              _setHoveredFromDx(
                                dx: details.localPosition.dx,
                                width: chartWidth,
                                count: count,
                              );
                            },
                            onHorizontalDragStart: (details) {
                              _setHoveredFromDx(
                                dx: details.localPosition.dx,
                                width: chartWidth,
                                count: count,
                              );
                            },
                            onHorizontalDragUpdate: (details) {
                              _setHoveredFromDx(
                                dx: details.localPosition.dx,
                                width: chartWidth,
                                count: count,
                              );
                            },
                            child: Stack(
                              children: [
                                Positioned(
                                  top: chartTopOffset,
                                  left: 0,
                                  right: 0,
                                  height: chartHeight,
                                  child: CustomPaint(
                                    painter: _StageTrendChartPainter(
                                      healthyData: healthy.sublist(0, count),
                                      earlyData: early.sublist(0, count),
                                      advancedData: advanced.sublist(0, count),
                                      hoveredIndex: hovered,
                                    ),
                                    size: Size.infinite,
                                  ),
                                ),
                                if (hovered != null)
                                  Positioned(
                                    left: tooltipLeft,
                                    top: tooltipTop,
                                    child: Container(
                                      width: 154,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5FFF5),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFC8E6C9),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            labels[hovered],
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'H: ${_toInt(_series[hovered], 'healthy')}  E: ${_toInt(_series[hovered], 'early')}  A: ${_toInt(_series[hovered], 'advanced')}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                children: List<Widget>.generate(count, (i) {
                  final showLabel =
                      count <= 6 || i == 0 || i == count - 1 || i.isEven;
                  return Expanded(
                    child: Text(
                      showLabel ? labels[i] : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
      ],
    );
  }
}

class _PerTreePoint {
  final String treeName;
  final DateTime date;
  final double severityPct;
  final String stage;

  const _PerTreePoint({
    required this.treeName,
    required this.date,
    required this.severityPct,
    required this.stage,
  });
}

class _PerTreeImageChart extends StatelessWidget {
  final List<_PerTreePoint> points;

  const _PerTreeImageChart({required this.points});

  String _dateLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _timestampLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '${_dateLabel(date)} $hour:$minute:$second';
  }

  List<MapEntry<String, double>> _buildShownDateLabels({
    required int minMs,
    required int rangeMs,
    int maxLabels = 5,
  }) {
    final seenLabels = <String>{};
    final allLabels = <MapEntry<String, double>>[];

    for (final point in points) {
      final label = _timestampLabel(point.date);
      if (seenLabels.add(label)) {
        final ratio = ((point.date.millisecondsSinceEpoch - minMs) / rangeMs)
            .clamp(0.0, 1.0)
            .toDouble();
        allLabels.add(MapEntry(label, ratio));
      }
    }

    if (allLabels.length <= maxLabels) {
      return allLabels;
    }

    final indices = <int>{0, allLabels.length - 1};
    final interiorSlots = maxLabels - 2;
    if (interiorSlots > 0) {
      final step = (allLabels.length - 1) / (interiorSlots + 1);
      for (int slot = 1; slot <= interiorSlots; slot++) {
        final idx = (slot * step).round().clamp(0, allLabels.length - 1) as int;
        indices.add(idx);
      }
    }

    final ordered = indices.toList()..sort();
    return ordered.map((index) => allLabels[index]).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(
        height: 136,
        child: Center(
          child: Text(
            'No Pi image trend data for this filter.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      );
    }

    const palette = <Color>[
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFFC62828),
      Color(0xFF6A1B9A),
      Color(0xFFEF6C00),
      Color(0xFF00838F),
      Color(0xFF5D4037),
      Color(0xFF37474F),
    ];

    final treeOrder = <String>[];
    for (final point in points) {
      if (!treeOrder.contains(point.treeName)) {
        treeOrder.add(point.treeName);
      }
    }

    final treeColors = <String, Color>{};
    for (int i = 0; i < treeOrder.length; i++) {
      treeColors[treeOrder[i]] = palette[i % palette.length];
    }

    final int minMs = points.first.date.millisecondsSinceEpoch;
    final int maxMs = points.last.date.millisecondsSinceEpoch;
    final int rangeMs = maxMs == minMs ? 1 : maxMs - minMs;
    final shownDateLabels = _buildShownDateLabels(
      minMs: minMs,
      rangeMs: rangeMs,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pi image timestamps per tree',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: treeOrder
              .map(
                (treeName) => _TreeLegendItem(
                  label: treeName,
                  color: treeColors[treeName] ?? const Color(0xFF1565C0),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const chartTopOffset = 12.0;
              const chartHeight = 104.0;
              const yAxisWidth = 30.0;
              const axisGap = 6.0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: yAxisWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(top: chartTopOffset),
                      child: SizedBox(
                        height: chartHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              '100%',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '50%',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '0%',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: axisGap),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: chartTopOffset),
                      child: SizedBox(
                        height: chartHeight,
                        child: CustomPaint(
                          painter: _PerTreeImageChartPainter(
                            points: points,
                            treeColors: treeColors,
                            minMs: minMs,
                            maxMs: maxMs,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(
          height: 20,
          child: Row(
            children: [
              const SizedBox(width: 36),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const labelWidth = 70.0;
                    final maxLeft = math.max(
                      0.0,
                      constraints.maxWidth - labelWidth,
                    );

                    return Stack(
                      children: shownDateLabels
                          .map((entry) {
                            final left =
                                (entry.value * constraints.maxWidth -
                                        (labelWidth / 2))
                                    .clamp(0.0, maxLeft)
                                    .toDouble();
                            return Positioned(
                              left: left,
                              child: SizedBox(
                                width: labelWidth,
                                child: Text(
                                  entry.key,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TreeLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _TreeLegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PerTreeImageChartPainter extends CustomPainter {
  final List<_PerTreePoint> points;
  final Map<String, Color> treeColors;
  final int minMs;
  final int maxMs;

  const _PerTreeImageChartPainter({
    required this.points,
    required this.treeColors,
    required this.minMs,
    required this.maxMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFDFE8DF)
      ..strokeWidth = 1;
    for (final step in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = size.height - (step * size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final int rangeMs = maxMs == minMs ? 1 : maxMs - minMs;
    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final timeRatio =
          ((points[i].date.millisecondsSinceEpoch - minMs) / rangeMs)
              .clamp(0.0, 1.0)
              .toDouble();
      final x = timeRatio * size.width;
      final normalized = (points[i].severityPct / 100.0).clamp(0.0, 1.0);
      final y = size.height - normalized * size.height;
      offsets.add(Offset(x, y));
    }

    final groupedOffsets = <String, List<Offset>>{};
    for (int i = 0; i < points.length; i++) {
      groupedOffsets
          .putIfAbsent(points[i].treeName, () => <Offset>[])
          .add(offsets[i]);
    }

    groupedOffsets.forEach((treeName, treePoints) {
      final color = treeColors[treeName] ?? const Color(0xFF1565C0);
      if (treePoints.length >= 2) {
        final path = Path()..moveTo(treePoints.first.dx, treePoints.first.dy);
        for (int i = 1; i < treePoints.length; i++) {
          path.lineTo(treePoints[i].dx, treePoints[i].dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.9)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }

      for (final point in treePoints) {
        canvas.drawCircle(
          point,
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          point,
          2.8,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      }
    });
  }

  @override
  bool shouldRepaint(covariant _PerTreeImageChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.treeColors != treeColors ||
        oldDelegate.minMs != minMs ||
        oldDelegate.maxMs != maxMs;
  }
}

class _StageLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _StageLegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StageTrendChartPainter extends CustomPainter {
  final List<double> healthyData;
  final List<double> earlyData;
  final List<double> advancedData;
  final int? hoveredIndex;

  const _StageTrendChartPainter({
    required this.healthyData,
    required this.earlyData,
    required this.advancedData,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pointCount = math.min(
      healthyData.length,
      math.min(earlyData.length, advancedData.length),
    );
    if (pointCount < 2) return;

    final maxVal = [
      ...healthyData.take(pointCount),
      ...earlyData.take(pointCount),
      ...advancedData.take(pointCount),
    ].reduce(math.max);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    final gridPaint = Paint()
      ..color = const Color(0xFFDFE8DF)
      ..strokeWidth = 1;
    final gridY = <double>[0, size.height / 2, size.height];
    for (final y in gridY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    List<Offset> buildPoints(List<double> values) {
      return List<Offset>.generate(pointCount, (i) {
        final x = i / (pointCount - 1) * size.width;
        final normalized = values[i] / safeMax;
        final y = size.height - normalized * size.height;
        return Offset(x, y);
      });
    }

    Path smoothPath(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
        final cp2 = Offset(
          (points[i].dx + points[i + 1].dx) / 2,
          points[i + 1].dy,
        );
        path.cubicTo(
          cp1.dx,
          cp1.dy,
          cp2.dx,
          cp2.dy,
          points[i + 1].dx,
          points[i + 1].dy,
        );
      }
      return path;
    }

    void drawSeries(List<Offset> points, Color color) {
      final linePath = smoothPath(points);

      final fillPath = Path.from(linePath)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.24),
              color.withValues(alpha: 0.04),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        linePath,
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      for (final point in points) {
        canvas.drawCircle(
          point,
          2,
          Paint()..color = color.withValues(alpha: 0.75),
        );
      }
    }

    final advancedPoints = buildPoints(advancedData);
    final earlyPoints = buildPoints(earlyData);
    final healthyPoints = buildPoints(healthyData);

    drawSeries(advancedPoints, const Color(0xFFC62828));
    drawSeries(earlyPoints, const Color(0xFFF9A825));
    drawSeries(healthyPoints, const Color(0xFF2E7D32));

    final hovered = hoveredIndex;
    if (hovered != null && hovered >= 0 && hovered < pointCount) {
      final x = healthyPoints[hovered].dx;
      final hoverLinePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..strokeWidth = 1;
      const dash = 4.0;
      const gap = 3.0;
      double y = 0;
      while (y < size.height) {
        final end = math.min(y + dash, size.height);
        canvas.drawLine(Offset(x, y), Offset(x, end), hoverLinePaint);
        y += dash + gap;
      }

      final points = [
        MapEntry(healthyPoints[hovered], const Color(0xFF2E7D32)),
        MapEntry(earlyPoints[hovered], const Color(0xFFF9A825)),
        MapEntry(advancedPoints[hovered], const Color(0xFFC62828)),
      ];
      for (final entry in points) {
        canvas.drawCircle(
          entry.key,
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          entry.key,
          4,
          Paint()
            ..color = entry.value
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StageTrendChartPainter old) {
    return old.healthyData != healthyData ||
        old.earlyData != earlyData ||
        old.advancedData != advancedData ||
        old.hoveredIndex != hoveredIndex;
  }
}

class _TrendChart extends StatelessWidget {
  final List<double> dataPoints;
  final Color color;

  const _TrendChart({required this.dataPoints, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: CustomPaint(
        painter: _TrendChartPainter(dataPoints: dataPoints, color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  const _TrendChartPainter({required this.dataPoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final double minVal = dataPoints.reduce(math.min);
    final double maxVal = dataPoints.reduce(math.max);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    List<Offset> points = [];
    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i / (dataPoints.length - 1) * size.width;
      final double normalized = (dataPoints[i] - minVal) / range;
      final double y = size.height * 0.85 - normalized * (size.height * 0.75);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        points[i + 1].dy,
      );
      path.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final point in points) {
      canvas.drawCircle(
        point,
        3,
        Paint()..color = color.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter old) =>
      old.dataPoints != dataPoints || old.color != color;
}
