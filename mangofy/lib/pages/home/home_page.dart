import 'package:flutter/material.dart';
import 'summary_card.dart';
import 'recommended_actions_card.dart';
import 'severity_distributions_card.dart';
import '../../services/database_service.dart'; 
import '../../model/scan_summary_model.dart';

// Main home page of the app displaying the dashboard overview.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Start fetching the summary data immediately
    final Future<ScanSummary> _summaryFuture = 
        DatabaseService.instance.getScanSummary();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        // Use FutureBuilder to wait for the database results
        child: FutureBuilder<ScanSummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            // Default summary data in case of error or while loading
            final ScanSummary summaryData = snapshot.data ?? 
                ScanSummary(totalScans: 0, healthyCount: 0, moderateCount: 0, severeCount: 0);

            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a loading indicator while fetching data
              return const Center(child: CircularProgressIndicator());
            }

            // After data is loaded (or if there's an error/empty data)
            // Build the main dashboard layout
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Pass the fetched summary data
                      SummaryCard(summary: summaryData),
                    ],
                  ),
                ),

                // Scrollable section for Recommended Actions and Severity Distributions
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recommended Actions
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

                        // Pass the summary data needed for action recommendations
                        RecommendedActionsCard(summary: summaryData),

                        const SizedBox(height: 30),

                        // Severity Distributions
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

                        // Pass the summary data for distributions
                        SeverityDistributionsCard(summary: summaryData),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}