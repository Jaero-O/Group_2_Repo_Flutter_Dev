import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class RecommendedActionsCard extends StatelessWidget {
  const RecommendedActionsCard({super.key});

  // Builds a single row representing a recommended action with its percentage and description
  Widget _buildActionRow({
    required String percentage, // Percentage value to display
    required Color color, // Color for the percentage text
    required String description, // Description of the action
    Color descriptionColor = const Color(0xFF555555), // Optional color for description text
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Display percentage
        SizedBox(
          width: 80.0,
          child: Text(
            percentage,
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Display action description
        Expanded(
          child: Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: descriptionColor,
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // Card background and shape
      color: const Color(0xFFFAFAFA), 
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Donut Pie Chart showing percentage distribution
          Positioned(
            top: 30,
            right: 20,
            child: SizedBox(
              height: 150,
              width: 150,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 50, // Inner circle radius
                  sectionsSpace: 1, // Space between chart sections
                  sections: [
                    // Each section of the chart
                    PieChartSectionData(
                      value: 75,
                      color: const Color(0xFF06850C),
                      radius: 35,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: 20,
                      color: const Color(0xFF85D133),
                      radius: 35,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: 5,
                      color: const Color(0xFFA5E358),
                      radius: 35,
                      title: '',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main content: action text and percentage
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top action with large percentage and detailed description
                Padding(
                  padding: const EdgeInsets.only(right: 150.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large percentage text
                      Text(
                        '75%',
                        style: GoogleFonts.inter(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF06850C),
                        ),
                      ),

                      // Description of top action
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Apply organic fungicide: Use neem oil or sulfur-based spray.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(), // Divider between actions

                // Other recommended actions
                _buildActionRow(
                  percentage: '20%',
                  color: const Color(0xFF85D133),
                  description:
                      'Improve irrigation drainage: Avoid water accumulation near roots.',
                ),
                const Divider(),
                _buildActionRow(
                  percentage: '5%',
                  color: const Color(0xFFA5E358),
                  description:
                      'Remove infected leaves: Dispose of affected areas properly.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
