import 'package:flutter/material.dart';
import 'threat_level_card.dart';
import 'weekly_trend_card.dart';
import 'prediction_card.dart';
import 'recommended_actions_card.dart';
import 'severity_distributions_card.dart';
import 'notifications_page.dart'; // Ensure this file is created
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../model/scan_summary_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<ScanSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = DatabaseService.instance.getScanSummary();
    SyncService.instance.lastSyncNotifier.addListener(_refresh);
  }

  @override
  void dispose() {
    SyncService.instance.lastSyncNotifier.removeListener(_refresh);
    super.dispose();
  }

  ThreatLevel _resolveThreatLevel(ScanSummary summary) {
    final int total = summary.totalScans;
    if (total == 0) return ThreatLevel.low;
    final double severeRatio = summary.severeCount / total;
    if (severeRatio > 0.5) return ThreatLevel.critical;
    if (severeRatio > 0.3) return ThreatLevel.high;
    if (severeRatio > 0.1) return ThreatLevel.moderate;
    return ThreatLevel.low;
  }

  List<double> _resolveTrendData(ScanSummary summary) {
    return [
      summary.healthyCount.toDouble(),
      summary.moderateCount.toDouble(),
      summary.severeCount.toDouble(),
    ];
  }

  Future<void> _refresh() async {
    setState(() {
      _summaryFuture = DatabaseService.instance.getScanSummary();
    });
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
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
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

              final ScanSummary summaryData = snapshot.data ??
                  ScanSummary(
                    totalScans: 0,
                    healthyCount: 0,
                    moderateCount: 0,
                    severeCount: 0,
                  );

              final int diseasedCount =
                  summaryData.moderateCount + summaryData.severeCount;
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
                                      builder: (context) => const NotificationsPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Primary Threat Card
                        PrimaryThreatCard(
                          diseaseName: 'Anthracnose',
                          scientificName: 'Colletotrichum gloeosporioides',
                          activeCases: diseasedCount,
                          threatLevel: level,
                          weeklyTrendPercent: summaryData.totalScans > 0
                              ? (summaryData.severeCount /
                                      summaryData.totalScans *
                                      100)
                              : 0,
                          trendData: trendData,
                        ),

                        const SizedBox(height: 30),

                        // Outbreak Prediction Card (Title moved outside within the widget)
                        const OutbreakPredictionCard(),

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