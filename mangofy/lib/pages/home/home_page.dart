import 'package:flutter/material.dart';
import 'summary_card.dart';
import 'recommended_actions_card.dart';
import 'severity_distributions_card.dart';

// Main home page of the app displaying the dashboard overview.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section with Summary heading and summary card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section title: Summary
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

                  // Widget displaying summarized key metrics
                  const SummaryCard(),
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
                    // Section title: Recommended Actions
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

                    // Widget displaying recommended actions for the user
                    const RecommendedActionsCard(),

                    const SizedBox(height: 30),

                    // Section title: Severity Distributions
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

                    // Widget displaying severity distribution charts or stats
                    const SeverityDistributionsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
