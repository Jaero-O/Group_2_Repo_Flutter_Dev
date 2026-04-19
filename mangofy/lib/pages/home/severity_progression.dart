import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/local_db.dart';

class SeverityProgressionChart extends StatefulWidget {
  final int? treeId;
  final int weekWindow;

  const SeverityProgressionChart({
    super.key,
    this.treeId,
    this.weekWindow = 8,
  });

  @override
  State<SeverityProgressionChart> createState() => _SeverityProgressionChartState();
}

class _SeverityProgressionChartState extends State<SeverityProgressionChart> {
  int? _selectedMonth;
  int? _selectedYear;

  late Future<List<Map<String, dynamic>>> _monthOptionsFuture;
  late Future<List<Map<String, dynamic>>> _seriesFuture;

  @override
  void initState() {
    super.initState();
    _monthOptionsFuture = _loadMonthOptions();
    _seriesFuture = _loadSeries();
  }

  @override
  void didUpdateWidget(covariant SeverityProgressionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.treeId != widget.treeId) {
      _selectedMonth = null;
      _selectedYear = null;
      _monthOptionsFuture = _loadMonthOptions();
      _seriesFuture = _loadSeries();
    }
  }

  Future<List<Map<String, dynamic>>> _loadMonthOptions() {
    return LocalDb.instance.getSeverityTrendMonthOptions(treeId: widget.treeId);
  }

  Future<List<Map<String, dynamic>>> _loadSeries() {
    return LocalDb.instance.getSeverityProgressionSeries(
      treeId: widget.treeId,
      month: _selectedMonth,
      year: _selectedYear,
      weekWindow: widget.weekWindow,
    );
  }

  void _onFilterChanged(String? value) {
    setState(() {
      if (value == null || value == 'all') {
        _selectedMonth = null;
        _selectedYear = null;
      } else {
        final parts = value.split('-');
        if (parts.length == 2) {
          _selectedYear = int.tryParse(parts[0]);
          _selectedMonth = int.tryParse(parts[1]);
        }
      }
      _seriesFuture = _loadSeries();
    });
  }

  void _showFilterSheet(List<Map<String, dynamic>> monthOptions) {
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
                  'Select Trend Filter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Latest ${widget.weekWindow} weeks'),
                  trailing: (_selectedMonth == null && _selectedYear == null)
                      ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _onFilterChanged('all');
                  },
                ),
                if (monthOptions.isNotEmpty) const Divider(height: 8),
                ...monthOptions.map((item) {
                  final year = (item['year'] as int?) ?? 0;
                  final month = (item['month'] as int?) ?? 0;
                  final value = '$year-$month';
                  final label = item['label']?.toString() ?? '$month/$year';
                  final isSelected = _selectedYear == year && _selectedMonth == month;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    trailing:
                        isSelected ? const Icon(Icons.check, color: Color(0xFF2E7D32)) : null,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _onFilterChanged(value);
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

  List<LineChartBarData> _buildLineBars(List<Map<String, dynamic>> series) {
    FlDotData dotData(Color color) => FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 3.5,
            color: color,
            strokeColor: Colors.white,
            strokeWidth: 1.2,
          ),
        );

    List<FlSpot> spotsFor(String key) => List<FlSpot>.generate(series.length, (i) {
          final raw = (series[i][key] as num?)?.toDouble() ?? 0.0;
          final safe = raw < 0 ? 0.0 : raw;
          return FlSpot(i.toDouble(), safe);
        });

    return [
      LineChartBarData(
        spots: spotsFor('healthy'),
        isCurved: false,
        color: const Color(0xFF2E7D32),
        barWidth: 2.8,
        dotData: dotData(const Color(0xFF2E7D32)),
      ),
      LineChartBarData(
        spots: spotsFor('early'),
        isCurved: false,
        color: const Color(0xFFF9A825),
        barWidth: 2.8,
        dotData: dotData(const Color(0xFFF9A825)),
      ),
      LineChartBarData(
        spots: spotsFor('advanced'),
        isCurved: false,
        color: const Color(0xFFC62828),
        barWidth: 2.8,
        dotData: dotData(const Color(0xFFC62828)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilterText = (_selectedMonth == null || _selectedYear == null)
        ? 'Latest ${widget.weekWindow} weeks'
        : '${_monthName(_selectedMonth!)} $_selectedYear';

    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _monthOptionsFuture,
        builder: (context, monthSnapshot) {
          final monthOptions = monthSnapshot.data ?? const <Map<String, dynamic>>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'Severity Progression',
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
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              TextButton.icon(
                onPressed: () => _showFilterSheet(monthOptions),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE8F5E9),
                  foregroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(
                  'Filter: $selectedFilterText',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  _LegendItem(color: Color(0xFF2E7D32), label: 'Healthy'),
                  SizedBox(width: 16),
                  _LegendItem(color: Color(0xFFF9A825), label: 'Early'),
                  SizedBox(width: 16),
                  _LegendItem(color: Color(0xFFC62828), label: 'Advanced'),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 260,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _seriesFuture,
                  builder: (context, seriesSnapshot) {
                    if (seriesSnapshot.connectionState == ConnectionState.waiting &&
                        !seriesSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (seriesSnapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Unable to load progression trend.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    final series = seriesSnapshot.data ?? const <Map<String, dynamic>>[];
                    if (series.isEmpty) {
                      return const Center(
                        child: Text(
                          'No timestamped scan data found for this filter.',
                          style: TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final labels = series
                        .map((row) => row['label']?.toString() ?? '')
                        .toList(growable: false);

                    return LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (series.length - 1).toDouble(),
                        minY: 0,
                        maxY: 100,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 20,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: const Color(0xFFE8F0E8),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 20,
                              reservedSize: 38,
                              getTitlesWidget: (value, meta) {
                                if (value % 20 != 0) return const SizedBox.shrink();
                                return Text(
                                  '${value.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[idx],
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: _buildLineBars(series),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: const Color(0xFFF5FFF5),
                            tooltipBorder: const BorderSide(
                              color: Color(0xFFC8E6C9),
                              width: 1,
                            ),
                            getTooltipItems: (touchedSpots) {
                              const seriesLabels = ['Healthy', 'Early', 'Advanced'];
                              const seriesColors = [
                                Color(0xFF2E7D32),
                                Color(0xFFF9A825),
                                Color(0xFFC62828),
                              ];
                              return touchedSpots.map((spot) {
                                final idx = spot.barIndex;
                                return LineTooltipItem(
                                  '${seriesLabels[idx]}: ${spot.y.toStringAsFixed(0)}%',
                                  TextStyle(
                                    color: seriesColors[idx],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    );
                  },
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

  String _monthName(int month) {
    const names = [
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
    if (month < 1 || month > 12) return month.toString();
    return names[month - 1];
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF555555),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}