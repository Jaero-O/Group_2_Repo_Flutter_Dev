import 'package:flutter/material.dart';
import 'threat_level_card.dart';
import 'weekly_trend_card.dart';
import 'prediction_card.dart';
import 'recommended_actions_card.dart';
import 'severity_distributions_card.dart';
import 'disease_data.dart';
import 'notifications_page.dart'; // Ensure this file is created
import '../../services/local_db.dart';
import '../../services/sync_service.dart';
import '../../model/scan_summary_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<ScanSummary> _summaryFuture;
  late Future<List<DiseaseData>> _distributionFuture;
  late Future<List<double>> _trendFuture;
  late Future<String> _primaryDiseaseFuture;
  bool _isRefreshing = false;
  bool _hasPendingRefresh = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = LocalDb.instance.getScanSummary();
    _distributionFuture = _loadDiseaseDistribution();
    _trendFuture = LocalDb.instance.getWeeklyTrend();
    _primaryDiseaseFuture = LocalDb.instance.getPrimaryDiseaseName();
    SyncService.instance.lastSyncNotifier.addListener(_onSyncUpdated);
  }

  @override
  void dispose() {
    SyncService.instance.lastSyncNotifier.removeListener(_onSyncUpdated);
    super.dispose();
  }

  void _onSyncUpdated() {
    _refresh();
  }

  ThreatLevel _resolveThreatLevel(ScanSummary summary) {
    final int total = summary.totalScans;
    if (total == 0) return ThreatLevel.low;
    final double advancedStageRatio = summary.advancedStageCount / total;
    if (advancedStageRatio > 0.5) return ThreatLevel.critical;
    if (advancedStageRatio > 0.3) return ThreatLevel.high;
    if (advancedStageRatio > 0.1) return ThreatLevel.moderate;
    return ThreatLevel.low;
  }

  List<double> _resolveTrendData(ScanSummary summary) {
    return [
      summary.healthyCount.toDouble(),
      summary.earlyStageCount.toDouble(),
      summary.advancedStageCount.toDouble(),
    ];
  }

  Future<void> _refresh() async {
    if (_isRefreshing) {
      _hasPendingRefresh = true;
      return;
    }

    _isRefreshing = true;

    try {
      final summaryFuture = LocalDb.instance.getScanSummary();
      final distributionFuture = _loadDiseaseDistribution();
      final trendFuture = LocalDb.instance.getWeeklyTrend();
      final primaryDiseaseFuture = LocalDb.instance.getPrimaryDiseaseName();

      if (mounted) {
        setState(() {
          _summaryFuture = summaryFuture;
          _distributionFuture = distributionFuture;
          _trendFuture = trendFuture;
          _primaryDiseaseFuture = primaryDiseaseFuture;
        });
      }

      await Future.wait([
        summaryFuture,
        distributionFuture,
        trendFuture,
        primaryDiseaseFuture,
      ], eagerError: false);
    } finally {
      _isRefreshing = false;
      if (_hasPendingRefresh) {
        _hasPendingRefresh = false;
        _refresh();
      }
    }
  }

  Future<List<DiseaseData>> _loadDiseaseDistribution() async {
    final rows = await LocalDb.instance.getDiseaseDistribution();
    if (rows.isEmpty) return <DiseaseData>[];

    final List<DiseaseData> items = [];
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

    if (items.length <= 4) return items;

    final top = items.sublist(0, 3);
    final othersCount = items
        .sublist(3)
        .fold<int>(0, (sum, item) => sum + item.count);
    top.add(
      DiseaseData(
        name: 'Others',
        count: othersCount,
        color: const Color(0xFFBDBDBD),
      ),
    );
    return top;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<ScanSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
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

              final ScanSummary summaryData =
                  snapshot.data ??
                  ScanSummary(
                    totalScans: 0,
                    healthyCount: 0,
                    earlyStageCount: 0,
                    advancedStageCount: 0,
                  );

              final int diseasedCount =
                  summaryData.earlyStageCount + summaryData.advancedStageCount;
              final ThreatLevel level = _resolveThreatLevel(summaryData);
              final List<double> trendData = _resolveTrendData(summaryData);

              return SizedBox(
                height: constraints.maxHeight,
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
                        // Summary heading with notification icon
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
                                          const NotificationsPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Primary Threat Card
                        FutureBuilder<String>(
                          future: _primaryDiseaseFuture,
                          builder: (context, diseaseSnapshot) {
                            final primaryDisease =
                                diseaseSnapshot.data ?? 'No Active Disease';
                            return PrimaryThreatCard(
                              diseaseName: primaryDisease,
                              scientificName:
                                  'Detected from synced RasPi scans',
                              activeCases: diseasedCount,
                              threatLevel: level,
                              weeklyTrendPercent: summaryData.totalScans > 0
                                  ? (summaryData.advancedStageCount /
                                        summaryData.totalScans *
                                        100)
                                  : 0,
                              trendData: trendData,
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Disease Distribution Card
                        FutureBuilder<List<DiseaseData>>(
                          future: _distributionFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 260,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return const DiseaseDistributionCard(
                                diseases: [],
                                totalCases: 0,
                              );
                            }
                            final diseases = snapshot.data!;
                            final total = diseases.fold<int>(
                              0,
                              (sum, item) => sum + item.count,
                            );
                            return DiseaseDistributionCard(
                              diseases: diseases,
                              totalCases: total,
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // Outbreak Prediction Card (Title moved outside within the widget)
                        FutureBuilder<List<double>>(
                          future: _trendFuture,
                          builder: (context, trendSnapshot) {
                            final trendData = trendSnapshot.data ?? [];
                            return OutbreakPredictionCard(
                              weeklyData: trendData,
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // 30-Day AI Prediction Card (Title moved outside within the widget)
                        const PredictionCard(),

                        const SizedBox(height: 30),

                        // Recommended Actions heading
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

                        RecommendedActionsCard(summary: summaryData),

                        const SizedBox(height: 30),

                        // Severity Distributions heading
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

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
