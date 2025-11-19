import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scan_details_page.dart';
import '../../ui/green_header_background.dart';
import 'scan_constants.dart';
import '../../services/database_service.dart';
import '../../model/scan_model.dart';

// Displays history of leaf scans, fetching data from the database.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // State variables
  List<ScanRecord> _scanHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _seedDummyDataIfEmpty();
  }

  // Helper to determine status based on severity value
  String _getStatusFromValue(double value) {
    if (value > 40.0) {
      return 'Severe';
    } else if (value > 5.0) {
      return 'Moderate';
    } else {
      return 'Healthy';
    }
  }

  // Seeds dummy data if the database is empty, then loads the history.
  Future<void> _seedDummyDataIfEmpty() async {
    final dbRecords = await DatabaseService.instance.getAllScans();
    if (dbRecords.isEmpty) {
      final List<Map<String, dynamic>> dummyData = [
        {'value': 0.1, 'disease': 'Healthy', 'date': 'Dec 20, 2025'},
        {'value': 50.1, 'disease': 'Anthracnose', 'date': 'Dec 19, 2025'},
        {'value': 89.2, 'disease': 'Anthracnose', 'date': 'Dec 18, 2025'},
        {'value': 4.5, 'disease': 'Healthy', 'date': 'Dec 17, 2025'},
        {'value': 25.8, 'disease': 'Anthracnose', 'date': 'Dec 16, 2025'},
        {'value': 95.0, 'disease': 'Anthracnose', 'date': 'Dec 15, 2025'},
        {'value': 1.2, 'disease': 'Healthy', 'date': 'Dec 14, 2025'},
        {'value': 62.3, 'disease': 'Anthracnose', 'date': 'Dec 13, 2025'},
        {'value': 15.0, 'disease': 'Anthracnose', 'date': 'Dec 12, 2025'},
      ];

      for (var data in dummyData) {
        // FIX: Cast to 'num' first, then call .toDouble() to safely convert
        // both int (45) and double values to double.
        final double severityValue = (data['value'] as num).toDouble();
        final String status = _getStatusFromValue(severityValue);

        await DatabaseService.instance.insertScan(
          disease: data['disease'] as String,
          severityValue: severityValue,
          status: status,
          date: data['date'] as String,
        );
      }
    }
    _loadScanHistory();
  }

  // Loads all scan records from the database.
  Future<void> _loadScanHistory() async {
    final dbRecords = await DatabaseService.instance.getAllScans();

    final List<ScanRecord> history = dbRecords
        .map((map) => ScanRecord.fromMap(map))
        .toList();

    if (mounted) {
      setState(() {
        _scanHistory = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate Summary Stats
    final int totalScans = _scanHistory.length;
    // Count items where status is explicitly 'Healthy'
    final int healthyScans = _scanHistory
        .where((record) => record.status == 'Healthy')
        .length;
    // Infected is everything else (Moderate + Severe)
    final int infectedScans = totalScans - healthyScans;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GreenHeaderBackground(height: ScanConstants.kTopHeaderHeight),

          Positioned(
            top: 25,
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
            top:
                ScanConstants.kTopHeaderHeight -
                ScanConstants.kContainerOverlap,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ScanConstants.kTopRadius),
                  bottom: Radius.circular(ScanConstants.kBottomRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height:
                        ScanConstants.kCardAreaHeight +
                        ScanConstants.kButtonAreaHeight,
                  ),

                  // Scrollable list of scans
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _scanHistory.isEmpty
                        ? Center(
                            child: Text(
                              'No scan history found.',
                              style: GoogleFonts.inter(color: Colors.grey[500]),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _scanHistory.length,
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              ScanConstants.kBottomRadius + 16,
                            ),
                            itemBuilder: (context, index) {
                              final item = _scanHistory[index];
                              return _buildScanHistoryItem(
                                context,
                                severityValue: item.severityValue
                                    .toStringAsFixed(1),
                                status: item.status,
                                primaryColor: item.primaryColor,
                                disease: item.disease,
                                date: item.date,
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

          // Summary cards row (Total, Healthy, Infected)
          Positioned(
            top:
                ScanConstants.kTopHeaderHeight -
                ScanConstants.kCardOverlapHeight,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard(
                    title: 'Total Scans',
                    value: totalScans.toString(),
                    diseaseName: null,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    title: 'Healthy',
                    value: healthyScans.toString(),
                    diseaseName: null,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    title: 'Infected',
                    value: infectedScans.toString(),
                    diseaseName: 'Anthracnose',
                  ),
                ],
              ),
            ),
          ),

          // Filter and Sort buttons
          Positioned(
            top:
                ScanConstants.kTopHeaderHeight -
                ScanConstants.kCardOverlapHeight +
                ScanConstants.kCardAreaHeight,
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
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
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
      onPressed: () {
        // Placeholder onPressed action
      },
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
                          color: primaryColor.withOpacity(0.2),
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
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    disease.toLowerCase() == 'healthy'
                        ? 'No Disease Detected'
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
                      color: Colors.black54,
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
