import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scan_details_page.dart';
import 'scan_constants.dart';
import '../../ui/green_header_background.dart';
import '../../services/local_db.dart';
import '../../services/sync_service.dart';
import '../../model/scan_item.dart';

// Displays history of leaf scans, fetching data from the database.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

enum SortOption { dateNewest, dateOldest, severityHigh, severityLow }

enum FilterOption { all, healthy, moderate, severe }

class _ScanPageState extends State<ScanPage> {
  // State variables
  List<ScanItem> _scanHistory = [];
  List<ScanItem> _displayScanHistory = []; // The list shown to the user
  bool _isLoading = true;

  // Sort and Filter state
  SortOption _currentSort = SortOption.dateNewest;
  FilterOption _currentFilter = FilterOption.all;

  @override
  void initState() {
    super.initState();
    _seedDummyDataIfEmpty();
    SyncService.instance.lastSyncNotifier.addListener(_loadScanHistory);
  }

  @override
  void dispose() {
    SyncService.instance.lastSyncNotifier.removeListener(_loadScanHistory);
    super.dispose();
  }

  String _statusFor(ScanItem item) {
    final v = item.severityValue;
    if (v > 40.0) return 'Severe';
    if (v > 5.0) return 'Moderate';
    return 'Healthy';
  }

  Color _primaryColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return const Color(0xFF4CAF50);
      case 'moderate':
        return const Color(0xFFF2DA00);
      case 'severe':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String _dateLabelFor(ScanItem item) {
    final parsed = DateTime.tryParse(item.timestamp);
    if (parsed == null) return item.timestamp;
    final local = parsed.toLocal();
    final yyyy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  // Loads the scan history without inserting placeholder data.
  Future<void> _seedDummyDataIfEmpty() async {
    await _loadScanHistory();
  }

  // Loads all scan records from the database.
  Future<void> _loadScanHistory() async {
    final List<ScanItem> history = await LocalDb.instance.getAllScans();

    if (mounted) {
      setState(() {
        _scanHistory = history;
        _isLoading = false;
        _applySortAndFilter(); // Apply initial sort/filter after loading
      });
    }
  }

  // Filtering and Sorting Logic

  void _applySortAndFilter() {
    // Start with the full history list
    List<ScanItem> filteredList = List.from(_scanHistory);

    // Apply Filtering
    if (_currentFilter != FilterOption.all) {
      final String filterStatus = _currentFilter.toString().split('.').last;
      filteredList = filteredList
          .where((record) => _statusFor(record).toLowerCase() == filterStatus)
          .toList();
    }

    // Apply Sorting
    filteredList.sort((a, b) {
      switch (_currentSort) {
        case SortOption.dateNewest:
          // To sort Newest First (Descending by ID): b.id > a.id
          return a.id.compareTo(b.id);

        case SortOption.dateOldest:
          // To sort Oldest First (Ascending by ID): a.id < b.id
          return b.id.compareTo(a.id);

        case SortOption.severityHigh:
          // High to Low: b.value > a.value
          return b.severityValue.compareTo(a.severityValue);

        case SortOption.severityLow:
          // Low to High: a.value > b.value
          return a.severityValue.compareTo(b.severityValue);
      }
    });

    setState(() {
      _displayScanHistory = filteredList;
    });
  }

  // UI Methods for Sort/Filter Selection

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (BuildContext context) {
        return _buildOptionsSheet<SortOption>(
          title: 'Sort By',
          currentOption: _currentSort,
          options: {
            SortOption.dateNewest: 'Date (Newest First)',
            SortOption.dateOldest: 'Date (Oldest First)',
            SortOption.severityHigh: 'Severity (High to Low)',
            SortOption.severityLow: 'Severity (Low to High)',
          },
          onSelect: (option) {
            setState(() {
              _currentSort = option;
              _applySortAndFilter();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (BuildContext context) {
        return _buildOptionsSheet<FilterOption>(
          title: 'Filter By Status',
          currentOption: _currentFilter,
          options: {
            FilterOption.all: 'All Scans',
            FilterOption.healthy: 'Healthy',
            FilterOption.moderate: 'Moderate',
            FilterOption.severe: 'Severe',
          },
          onSelect: (option) {
            setState(() {
              _currentFilter = option;
              _applySortAndFilter();
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildOptionsSheet<T extends Enum>({
    required String title,
    required T currentOption,
    required Map<T, String> options,
    required Function(T) onSelect,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      // Top padding for the title, bottom padding for safe area spacing
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF005200),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          ...options.entries.map((entry) {
            final option = entry.key;
            final label = entry.value;
            final isSelected = option == currentOption;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.5),
              child: InkWell(
                onTap: () => onSelect(option),
                borderRadius: BorderRadius.circular(12),
                // Hover/Pressed feedback color
                highlightColor: Colors.grey.withOpacity(0.1),
                splashColor: Colors.grey.withOpacity(0.05),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    // Highlight with gray when selected
                    color: isSelected ? Colors.grey[200] : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      // Bold and Green text if selected, otherwise normal
                      // fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      // color: isSelected ? const Color(0xFF007700) : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate Summary Stats
    final int totalScans = _scanHistory.length;
    // Count items where status is explicitly 'Healthy'
    final int healthyScans = _scanHistory
        .where((record) => _statusFor(record) == 'Healthy')
        .length;
    // Infected - Moderate + Severe
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Scan History',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status text moved to center of scan list page for better visibility
                    const SizedBox(height: 0),
                    const SizedBox(height: 0),  // status line hidden for clean UI
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
                        : _displayScanHistory.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Text(
                                        'No scans yet.',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 40),
                                        child: Text(
                                          'Scan QR code to import images automatically.',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 90),
                                  ],
                                ),
                              )
                        : ListView.separated(
                            itemCount: _displayScanHistory.length,
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              ScanConstants.kBottomRadius + 16,
                            ),
                            itemBuilder: (context, index) {
                              final item = _displayScanHistory[index];
                              final status = _statusFor(item);
                              final color = _primaryColorForStatus(status);
                              return _buildScanHistoryItem(
                                context,
                                severityValue: item.severityValue.toStringAsFixed(1),
                                status: status,
                                primaryColor: color,
                                disease: item.disease.isNotEmpty ? item.disease : item.title,
                                date: _dateLabelFor(item),
                                index: index,
                                photoId: item.photoId,
                                localImagePath: item.imagePath,
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
                    _getSortLabel(),
                    Icons.sort,
                    onPressed: _showSortOptions,
                    backgroundColor: const Color(0xFF007700),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    _getFilterLabel(),
                    Icons.filter_list,
                    onPressed: _showFilterOptions,
                    // Keep the background color constant regardless of filter state
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

  // Gets the displayed label for the Sort button
  String _getSortLabel() {
    switch (_currentSort) {
      case SortOption.dateNewest:
        return 'Sorted: Newest';
      case SortOption.dateOldest:
        return 'Sorted: Oldest';
      case SortOption.severityHigh:
        return 'Sorted: High Sev.';
      case SortOption.severityLow:
        return 'Sorted: Low Sev.';
    }
  }

  // Gets the displayed label for the Filter button
  String _getFilterLabel() {
    switch (_currentFilter) {
      case FilterOption.all:
        return 'Filter: All';
      case FilterOption.healthy:
        return 'Filter: Healthy';
      case FilterOption.moderate:
        return 'Filter: Moderate';
      case FilterOption.severe:
        return 'Filter: Severe';
    }
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
    required VoidCallback onPressed,
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
      onPressed: onPressed,
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
    int? photoId,
    String? localImagePath,
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
              photoId: photoId,
              localImagePath: localImagePath,
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
                          color: primaryColor.withAlpha(51),
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
