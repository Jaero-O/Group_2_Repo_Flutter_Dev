import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Define gradient colors for different severity levels
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

  // Builds a single severity bar with label, percentage, range, and gradient color
  Widget _buildSeverityBar({
    required String label, // Severity label
    required String percentage, // Displayed percentage string 
    required String range, // Range description
    required LinearGradient gradient, // Gradient for the progress bar
  }) {
    // Convert percentage string to numeric value
    final String numericString = percentage.replaceAll(RegExp(r'[^\d.]'), '');
    final double value = double.tryParse(numericString) ?? 0.0;
    final double progressValue = value / 100.0; // Convert to 0-1 scale
    const double radius = 12.0; // Border radius for progress bar

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row containing label, range, and percentage text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Severity label
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Range text
                  Text(
                    range,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF555555),
                    ),
                  ),
                ],
              ),
              // Percentage text
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

          // Progress bar container
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // Background bar
                Container(height: 16, color: Colors.grey[300]),

                // Foreground colored progress bar based on percentage
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progressValue.clamp(0.0, 1.0), // Clamp to 0-1
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
      // Card background and rounded edges
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
            // Healthy severity bar
            _buildSeverityBar(
              label: 'Healthy',
              percentage: '35%',
              range: '(0% - 5%)',
              gradient: healthyGradient,
            ),

            // Moderate severity bar
            _buildSeverityBar(
              label: 'Moderate',
              percentage: '20%',
              range: '(6% - 40%)',
              gradient: moderateGradient,
            ),

            // Severe severity bar
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
