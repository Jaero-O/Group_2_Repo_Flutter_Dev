import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/scan_summary_model.dart';

const healthyGradient = LinearGradient(
  colors: [Color(0xFF85D133), Color(0xFF06850C)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const earlyStageGradient = LinearGradient(
  colors: [Color(0xFF85D133), Color(0xFFFFCC00)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const advancedStageGradient = LinearGradient(
  colors: [Color(0xFFFFCC00), Color(0xFFFF0000)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class SeverityDistributionsCard extends StatelessWidget {
  final ScanSummary summary;

  const SeverityDistributionsCard({super.key, required this.summary});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF555555),
                      ),
                    ),
                    Text(
                      range,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
    final int stageTotal =
        summary.healthyCount +
        summary.earlyStageCount +
        summary.advancedStageCount;

    int hInt = 0;
    int earlyStageInt = 0;
    int advancedStageInt = 0;

    if (stageTotal > 0) {
      hInt = ((summary.healthyCount / stageTotal) * 100).round();
      earlyStageInt = ((summary.earlyStageCount / stageTotal) * 100).round();
      advancedStageInt = 100 - hInt - earlyStageInt;

      if (advancedStageInt < 0) {
        if (hInt > earlyStageInt) {
          hInt += advancedStageInt;
        } else {
          earlyStageInt += advancedStageInt;
        }
        advancedStageInt = 0;
      }
    }

    return Card(
      color: const Color(0xFFFAFAFA),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeverityBar(
              label: 'Healthy',
              percentage: '$hInt%',
              range: '(No visible damage)',
              gradient: healthyGradient,
            ),

            _buildSeverityBar(
              label: 'Early Stage',
              percentage: '$earlyStageInt%',
              range: '(Early infection signs)',
              gradient: earlyStageGradient,
            ),

            _buildSeverityBar(
              label: 'Advanced Stage',
              percentage: '$advancedStageInt%',
              range: '(Advanced infection)',
              gradient: advancedStageGradient,
            ),
          ],
        ),
      ),
    );
  }
}
