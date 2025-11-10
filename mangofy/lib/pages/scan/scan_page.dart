import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'scan_details_page.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  static const Color topColorStart = Color(0xFF007700);
  static const Color topColorEnd = Color(0xFFC9FF8E);
  static const double kTopHeaderHeight = 190.0;
  static const double kTopRadius = 70.0;
  static const double kContainerOverlap = 60.0;
  static const double kCardOverlapHeight = 100.0;
  static const double kCardAreaHeight = 120.0;
  static const double kButtonAreaHeight = 45.0;
  static const double kBottomRadius = 24.0;

  static const LinearGradient kGreenGradient = LinearGradient(
    colors: [topColorStart, topColorEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final List<Map<String, Object>> severityData = List.generate(
      20,
      (index) => [
        {'value': '0.1', 'label': 'Healthy', 'color': const Color(0xFF4CAF50)},
        {
          'value': '50.1',
          'label': 'Moderate',
          'color': const Color(0xFFF2DA00),
        },
        {'value': '89.2', 'label': 'Severe', 'color': const Color(0xFFF44336)},
      ][index % 3],
    );

    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Color(0xFF007700),
      // ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: kTopHeaderHeight,
            child: Container(
              decoration: const BoxDecoration(gradient: kGreenGradient),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Scan History',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            top: kTopHeaderHeight - kContainerOverlap,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(kTopRadius),
                  bottom: Radius.circular(kBottomRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: kCardAreaHeight + kButtonAreaHeight),
                  Expanded(
                    child: ListView.separated(
                      itemCount: severityData.length,
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        kBottomRadius + 16,
                      ),

                      itemBuilder: (context, index) {
                        final item = severityData[index];
                        return _buildScanHistoryItem(
                          context,
                          severityValue: item['value'] as String,
                          status: item['label'] as String,
                          primaryColor: item['color'] as Color,
                          disease: item['label'] as String != 'Healthy'
                              ? 'Anthracnose'
                              : 'Healthy',
                          date: 'Dec ${20 - index}, 2025',
                          index: index,
                        );
                      },

                      separatorBuilder: (context, index) {
                        return const Divider(
                          color: Color(0xFFEEEEEE),
                          height: 1.0,
                          thickness: 1.0,
                          indent: 0,
                          endIndent: 0,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: kTopHeaderHeight - kCardOverlapHeight,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard(
                    title: 'Total Scans',
                    value: '120',
                    diseaseName: null,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    title: 'Healthy',
                    value: '95',
                    diseaseName: null,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    title: 'Infected',
                    value: '25',
                    diseaseName: 'Anthracnose',
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: kTopHeaderHeight - kCardOverlapHeight + kCardAreaHeight,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildFilterButton(
                    'Sort',
                    Icons.sort,
                    backgroundColor: const Color(0xFF007700),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    'Filters',
                    Icons.filter_list,
                    backgroundColor: const Color(0xFF007700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String? diseaseName,
  }) {
    const Color kValueColor = Color(0xFF005200);

    return Expanded(
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kValueColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12, 
                  color: Colors.grey[600]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    String label,
    IconData icon, {
    required Color backgroundColor,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: const Color(0xFFFAFAFA),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500), 
      ),
      onPressed: () {},
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
    );
  }

  Widget _buildScanHistoryItem(
    BuildContext context, {
    required String severityValue,
    required String status,
    required Color primaryColor,
    required String disease,
    required String date,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanDetailsPage(
              scanTitle: 'Scan Details',
              disease: disease,
              dateScanned: date,
              severityValue: severityValue,
              severityColor: primaryColor,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    severityValue,
                    style: GoogleFonts.inter(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'SEVERITY',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        date,
                        style: GoogleFonts.inter(
                          fontSize: 12, 
                          color: Colors.grey[500]
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    disease == 'No Disease Detected'
                        ? disease
                        : '$disease Detected',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This leaf scan was performed on a young mango tree located in Zone B, Section 3.',
                    style: GoogleFonts.inter(
                      fontSize: 12, 
                      color: Colors.black54
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}