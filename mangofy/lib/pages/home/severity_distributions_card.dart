import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const healthyGradient = LinearGradient(
  colors: [Color(0xFF85D133), Color(0xFF06850C)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const moderateGradient = LinearGradient(
  colors: [Color(0xFF85D133), Color(0xFFFFCC00)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const severeGradient = LinearGradient(
  colors: [Color(0xFFFFCC00), Color(0xFFFF0000)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class SeverityDistributionsCard extends StatelessWidget {
  const SeverityDistributionsCard({super.key});

  Widget _buildSeverityBar({
    required String label,
    required String percentage,
    required String range,
    required LinearGradient gradient,
  }) {
    final String numericString = percentage.replaceAll(RegExp(r'[^\d.]'), '');
    final double value = double.tryParse(numericString) ?? 0.0;
    final double progressValue = value / 100.0;
    const double radius = 12.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    range,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF555555),
                    ),
                  ),
                ],
              ),
              Text(
                percentage,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF555555),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                Container(height: 16, color: Colors.grey[300]),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progressValue.clamp(0.0, 1.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeverityBar(
              label: 'Healthy',
              percentage: '35%',
              range: '(0% - 5%)',
              gradient: healthyGradient,
            ),
            _buildSeverityBar(
              label: 'Moderate',
              percentage: '20%',
              range: '(6% - 40%)',
              gradient: moderateGradient,
            ),
            _buildSeverityBar(
              label: 'Severe',
              percentage: '45%',
              range: '(>40%)',
              gradient: severeGradient,
            ),
          ],
        ),
      ),
    );
  }
}