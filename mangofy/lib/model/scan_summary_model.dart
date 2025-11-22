// model/scan_summary_model.dart

// Represents the aggregated summary data for all disease scans.
class ScanSummary {
  final int totalScans;
  final int healthyCount;
  final int moderateCount;
  final int severeCount;

  ScanSummary({
    required this.totalScans,
    required this.healthyCount,
    required this.moderateCount,
    required this.severeCount,
  });
}