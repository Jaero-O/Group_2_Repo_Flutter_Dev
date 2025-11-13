import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class RecommendedActionsCard extends StatelessWidget {
  const RecommendedActionsCard({super.key});

  Widget _buildActionRow({
    required String percentage,
    required Color color,
    required String description,
    Color descriptionColor = const Color(0xFF555555),
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
      color: const Color(0xFFFAFAFA), 
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Donut Chart
          Positioned(
            top: 30,
            right: 20,
            child: SizedBox(
              height: 150,
              width: 150,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 50,
                  sectionsSpace: 1,
                  sections: [
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 150.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '75%',
                        style: GoogleFonts.inter(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF06850C),
                        ),
                      ),
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
                const Divider(),
                _buildActionRow(
                  percentage: '25%',
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