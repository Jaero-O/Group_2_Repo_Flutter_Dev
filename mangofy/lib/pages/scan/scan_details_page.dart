import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanDetailsPage extends StatelessWidget {
  final String scanTitle;
  final String disease;
  final String dateScanned;
  final String severityValue;
  final Color severityColor;

  const ScanDetailsPage({
    super.key,
    required this.scanTitle,
    required this.disease,
    required this.dateScanned,
    required this.severityValue,
    required this.severityColor,
  });

  static const String kLongDescription =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.';
  
  static const String kRecommendedActions =
      'Apply a broad-spectrum fungicide (such as chlorothalonil or mancozeb) every 7-14 days. Ensure proper tree pruning to improve air circulation and sunlight penetration. Rake and dispose of all fallen infected leaves to reduce the source of fungal spores.';
  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios, color: Color(0xFF48742C), size: 20),
                Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF48742C),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'Scan Details',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 60), 
        ],
      ),
    );
  }

  Widget _buildDiseaseTag(String disease) {
    final Color tagBackgroundColor = severityColor.withValues(alpha: 0.2); 

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagBackgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        disease.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: severityColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomAppBar(context),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 200,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300, width: 0.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'images/leaf.png', 
                                  fit: BoxFit.cover,
                                  height: 200,
                                  width: double.infinity,
                                ),
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '$severityValue%', 
                                  style: GoogleFonts.inter( 
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: severityColor,
                                    height: 1.0, 
                                  ),
                                ),
                                const SizedBox(width: 8), 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildDiseaseTag(disease),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SEVERITY LEVEL',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 32),

                            Text(
                              'Description',
                              style: GoogleFonts.inter( 
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kLongDescription,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 32),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date Scanned',
                                  style: GoogleFonts.inter( 
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  dateScanned,
                                  style: GoogleFonts.inter( 
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            Text(
                              'Recommended Actions',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kRecommendedActions, 
                              style: GoogleFonts.inter( 
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}