import 'package:flutter/material.dart';

import '../../model/notification_item.dart';
import '../../model/orchard_snapshot.dart';
import '../../model/scan_summary_model.dart';
import '../../model/weather_data.dart';
import '../../services/local_db.dart';
import '../../services/notification_service.dart';
import '../../services/sync_service.dart';
import '../../services/weather_service.dart';
import 'disease_data.dart';
import 'disease_seasonal_card.dart';
import 'notifications_page.dart';
import 'anthracnose_risk_forecast_card.dart';
import 'recommended_actions_card.dart';
import 'severity_distributions_card.dart';
import 'severity_progression.dart';
import 'threat_level_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<OrchardSnapshot> _snapshotFuture;
  late Future<WeatherData?> _weatherFuture;

  List<Map<String, dynamic>> _trees = [];
  int? _selectedTreeId;
  bool _isRefreshing = false;
  bool _hasPendingRefresh = false;
  bool _isSyncing = false;
  OrchardSnapshot? _lastSnapshot;

  @override
  void initState() {
    super.initState();
    _loadTrees();
    _applyDashboardSnapshot(_selectedTreeId);
    SyncService.instance.lastSyncNotifier.addListener(_onSyncUpdated);
    SyncService.instance.progressNotifier.addListener(_onSyncProgressChanged);
    _isSyncing = SyncService.instance.progressNotifier.value != null;
  }

  @override
  void dispose() {
    SyncService.instance.lastSyncNotifier.removeListener(_onSyncUpdated);
    SyncService.instance.progressNotifier.removeListener(_onSyncProgressChanged);
    super.dispose();
  }

  void _onSyncProgressChanged() {
    final isSyncingNow = SyncService.instance.progressNotifier.value != null;
    if (!mounted || _isSyncing == isSyncingNow) return;
    setState(() {
      _isSyncing = isSyncingNow;
    });
  }

  void _onSyncUpdated() {
    _refresh();
  }

  Future<void> _loadTrees() async {
    final trees = await LocalDb.instance.getDistinctTreesWithScans();
    if (!mounted) return;
    setState(() {
      _trees = trees;
      if (_selectedTreeId != null) {
        final stillExists = trees.any(
          (tree) => _treeIdFromMap(tree) == _selectedTreeId,
        );
        if (!stillExists) {
          _selectedTreeId = null;
        }
      }
    });
  }

  int? _treeIdFromMap(Map<String, dynamic> row) {
    final value = row['id'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _treeNameFromMap(Map<String, dynamic> row) {
    return (row['name']?.toString() ?? '').trim();
  }

  void _applyDashboardSnapshot(int? treeId) {
    _snapshotFuture = LocalDb.instance.getOrchardSnapshot(treeId: treeId);
    _weatherFuture = WeatherService.instance.getWeather();
  }

  void _onTreeChipSelected(int? treeId) {
    if (_selectedTreeId == treeId) return;
    setState(() {
      _selectedTreeId = treeId;
      _applyDashboardSnapshot(treeId);
    });
  }

  ThreatLevel _resolveAnthracnoseThreatLevel({
    required int anthracnoseCases,
    required int totalScans,
  }) {
    if (anthracnoseCases <= 0 || totalScans <= 0) return ThreatLevel.low;
    final ratio = anthracnoseCases / totalScans;
    if (ratio > 0.5) return ThreatLevel.critical;
    if (ratio > 0.3) return ThreatLevel.high;
    if (ratio > 0.1) return ThreatLevel.moderate;
    return ThreatLevel.low;
  }

  double _resolveWeeklyTrendPercentFromSeries(
    List<Map<String, dynamic>> trendSeries,
  ) {
    if (trendSeries.length < 2) return 0;

    final previous =
        (trendSeries[trendSeries.length - 2]['count'] as int?)?.toDouble() ?? 0;
    final current =
        (trendSeries[trendSeries.length - 1]['count'] as int?)?.toDouble() ?? 0;

    if (previous <= 0) {
      return current > 0 ? 100 : 0;
    }
    return ((current - previous) / previous) * 100;
  }

  String _resolveTrendDirection(List<Map<String, dynamic>> trendSeries) {
    if (trendSeries.length < 2) {
      return 'stable';
    }

    int readCountAt(int index) {
      if (index < 0 || index >= trendSeries.length) return 0;
      final value = trendSeries[index]['count'];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final latest = readCountAt(trendSeries.length - 1);
    final baseline = readCountAt(trendSeries.length - 3);
    final delta = latest - baseline;
    if (delta > 0) return 'worsening';
    if (delta < 0) return 'improving';
    return 'stable';
  }

  Future<void> _refresh() async {
    if (_isRefreshing) {
      _hasPendingRefresh = true;
      return;
    }

    _isRefreshing = true;

    try {
      await _loadTrees();
      final selectedTreeId = _selectedTreeId;
      final snapshotFuture = LocalDb.instance.getOrchardSnapshot(
        treeId: selectedTreeId,
      );
      final weatherFuture = WeatherService.instance.getWeather();

      if (mounted) {
        setState(() {
          _snapshotFuture = snapshotFuture;
          _weatherFuture = weatherFuture;
        });
      }

      await Future.wait([snapshotFuture, weatherFuture], eagerError: false);
    } finally {
      _isRefreshing = false;
      if (_hasPendingRefresh) {
        _hasPendingRefresh = false;
        _refresh();
      }
    }
  }

  String _formatLatestScanDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'No scans yet';
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    const months = [
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
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  List<DiseaseData> _mapDiseaseDistributionRows(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) return <DiseaseData>[];

    final List<DiseaseData> items = <DiseaseData>[];
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final name = row['disease']?.toString() ?? 'Unknown';
      final count = row['count'] is int
          ? row['count'] as int
          : int.tryParse(row['count']?.toString() ?? '') ?? 0;
      if (count <= 0) continue;
      items.add(
        DiseaseData(
          name: name,
          count: count,
          color: DiseaseDistributionCard.colorForDisease(name, i),
        ),
      );
    }

    return items;
  }

  List<NotificationItem> _buildNotifications({
    required Map<String, int> stageSummary,
    required List<Map<String, dynamic>> trendSeries,
    required ScanSummary summary,
  }) {
    final anthracnoseCount = stageSummary['total'] ?? 0;
    final generated = NotificationService.generate(
      anthracnoseCount: anthracnoseCount,
      stageBreakdown: stageSummary,
      weeklyTrend: trendSeries,
      summary: summary,
    );

    final syncItem = SyncService.instance.lastSyncNotificationItem;
    if (syncItem == null) return generated;

    return <NotificationItem>[syncItem, ...generated];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<OrchardSnapshot>(
            future: _snapshotFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData &&
                  _lastSnapshot == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError && !snapshot.hasData &&
                  _lastSnapshot == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      const Text('Failed to load data.'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final fallbackSummary = ScanSummary(
                totalScans: 0,
                anthracnoseTotal: 0,
                healthyCount: 0,
                earlyStageCount: 0,
                advancedStageCount: 0,
              );
              final emptySnapshot = OrchardSnapshot(
                summary: fallbackSummary,
                diseaseDistributionRows: const <Map<String, dynamic>>[],
                anthracnoseStageSummary: const <String, int>{
                  'healthy': 0,
                  'early': 0,
                  'advanced': 0,
                  'total': 0,
                },
                anthracnoseTrendSeries: const <Map<String, dynamic>>[],
                primaryDisease: 'No Active Disease',
                latestScanDate: null,
                rowCompleteness: const <String, int>{
                  'total': 0,
                  'incomplete': 0,
                },
              );

              final activeSnapshot = snapshot.data;
              if (activeSnapshot != null) {
                _lastSnapshot = activeSnapshot;
              }
              final snapshotData =
                  activeSnapshot ?? _lastSnapshot ?? emptySnapshot;
              final summaryData = snapshotData.summary;
              final notifications = _buildNotifications(
                stageSummary: snapshotData.anthracnoseStageSummary,
                trendSeries: snapshotData.anthracnoseTrendSeries,
                summary: summaryData,
              );
              final badgeCount = notifications
                  .where(
                    (item) =>
                        item.type == NotificationType.alert ||
                        item.type == NotificationType.warning,
                  )
                  .length;

              final diseases = _mapDiseaseDistributionRows(
                snapshotData.diseaseDistributionRows,
              );
              final distributionTotal = diseases.fold<int>(
                0,
                (sum, item) => sum + item.count,
              );

              final anthracnoseCount =
                  snapshotData.anthracnoseStageSummary['total'] ?? 0;
              final anthracnoseTrendData = snapshotData.anthracnoseTrendSeries
                  .map((row) => ((row['count'] as int?) ?? 0).toDouble())
                  .toList(growable: false);

              final anthracnoseThreatLevel = _resolveAnthracnoseThreatLevel(
                anthracnoseCases: anthracnoseCount,
                totalScans: summaryData.totalScans,
              );
              final weeklyTrendPercent = _resolveWeeklyTrendPercentFromSeries(
                snapshotData.anthracnoseTrendSeries,
              );
              final trendDirection = _resolveTrendDirection(
                snapshotData.anthracnoseTrendSeries,
              );

              return SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    if (_isSyncing)
                      const LinearProgressIndicator(
                        minHeight: 3,
                        color: Color(0xFF2E7D32),
                        backgroundColor: Color(0xFFEAF5EA),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 16,
                      bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.black87,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              NotificationsPage(
                                                notifications: notifications,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (badgeCount > 0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC62828),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          badgeCount > 9 ? '9+' : '$badgeCount',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (_trees.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8,
                              right: 8,
                              top: 8,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  FilterChip(
                                    label: const Text('All Trees'),
                                    selected: _selectedTreeId == null,
                                    showCheckmark: false,
                                    selectedColor: const Color(0xFF2E7D32),
                                    backgroundColor: const Color(0xFFEAF5EA),
                                    labelStyle: TextStyle(
                                      color: _selectedTreeId == null
                                          ? Colors.white
                                          : const Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF2E7D32),
                                    ),
                                    onSelected: (selected) {
                                      if (!selected ||
                                          _selectedTreeId == null) {
                                        return;
                                      }
                                      _onTreeChipSelected(null);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ...(() {
                                    final sortedTrees =
                                        List<Map<String, dynamic>>.from(_trees)
                                          ..sort(
                                            (a, b) => _treeNameFromMap(a)
                                                .toLowerCase()
                                                .compareTo(
                                                  _treeNameFromMap(
                                                    b,
                                                  ).toLowerCase(),
                                                ),
                                          );

                                    return sortedTrees.map((tree) {
                                      final treeId = _treeIdFromMap(tree);
                                      final treeName = _treeNameFromMap(tree);
                                      if (treeId == null || treeName.isEmpty) {
                                        return null;
                                      }

                                      final isSelected =
                                          _selectedTreeId == treeId;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: FilterChip(
                                          label: Text(treeName),
                                          selected: isSelected,
                                          showCheckmark: false,
                                          selectedColor: const Color(
                                            0xFF2E7D32,
                                          ),
                                          backgroundColor: const Color(
                                            0xFFEAF5EA,
                                          ),
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF2E7D32),
                                          ),
                                          onSelected: (selected) {
                                            final newValue = selected
                                                ? treeId
                                                : null;
                                            _onTreeChipSelected(newValue);
                                          },
                                        ),
                                      );
                                    }).whereType<Widget>();
                                  })(),
                                ],
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Text(
                            'Last scan: ${_formatLatestScanDate(snapshotData.latestScanDate)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: 2,
                          ),
                          child: Text(
                            'Rows with missing key fields: ${snapshotData.rowCompleteness['incomplete'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        DiseaseDistributionCard(
                          diseases: diseases,
                          totalCases: distributionTotal,
                        ),

                        const SizedBox(height: 30),

                        const DiseaseSeasonalCard(),

                        const SizedBox(height: 30),

                        PrimaryThreatCard(
                          diseaseName: 'Anthracnose',
                          scientificName: 'C. gloeosporioides',
                          activeCases: anthracnoseCount,
                          threatLevel: anthracnoseThreatLevel,
                          weeklyTrendPercent: weeklyTrendPercent,
                          trendData: anthracnoseTrendData,
                          chartLabel: 'Anthracnose cases (11-week trend)',
                        ),

                        const SizedBox(height: 30),

                        SeverityProgressionChart(treeId: _selectedTreeId),

                        const SizedBox(height: 30),

                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            'Severity Distributions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        SeverityDistributionsCard(summary: summaryData),

                        const SizedBox(height: 30),

                        FutureBuilder<WeatherData?>(
                          future: _weatherFuture,
                          builder: (context, weatherSnapshot) {
                            return AnthracnoseRiskForecastCard(
                              treeId: _selectedTreeId,
                              weather: weatherSnapshot.data,
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            'Recommended Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        RecommendedActionsCard(
                          summary: summaryData,
                          primaryDisease: snapshotData.primaryDisease,
                          trendDirection: trendDirection,
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            ),
              );
            },
          );
        },
      ),
    );
  }
}

