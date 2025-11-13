import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF007700),
              Color(0xFF238F19),
              Color(0xFFC9FF8E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '26',
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
                      Text(
                        '1,999',
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
                      Text(
                        '1,999',
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