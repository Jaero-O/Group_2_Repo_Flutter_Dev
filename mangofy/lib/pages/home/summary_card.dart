import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/scan_summary_model.dart';

class SummaryCard extends StatelessWidget {
  final ScanSummary summary; 

  // Update constructor to require the summary data
  const SummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    // Calculate diseased leaves count
    final int diseasedLeaves = summary.moderateCount + summary.severeCount;

    return Card(
      // Card elevation and rounded corners
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        // Apply gradient background and rounded corners
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF007700), // Dark green
              Color(0xFF238F19), // Medium green
              Color(0xFFC9FF8E), // Light green
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Statistics text
            Padding(
              padding: const EdgeInsets.only(
                left: 30,
                top: 20,
                right: 0,
                bottom: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Column for different leaf stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total leaves scanned 
                      Text(
                        summary.totalScans.toString(), 
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Leaves Scanned',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Healthy leaves 
                      Text(
                        summary.healthyCount.toString(), 
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Healthy Leaves',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Diseased leaves 
                      Text(
                        diseasedLeaves.toString(), 
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Diseased Leaves',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'images/mangoleaves.png',
                height: 110,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}