import 'scan_summary_model.dart';

class OrchardSnapshot {
  final ScanSummary summary;
  final List<Map<String, dynamic>> diseaseDistributionRows;
  final Map<String, int> anthracnoseStageSummary;
  final List<Map<String, dynamic>> anthracnoseTrendSeries;
  final String primaryDisease;
  final String? latestScanDate;
  final Map<String, int> rowCompleteness;

  const OrchardSnapshot({
    required this.summary,
    required this.diseaseDistributionRows,
    required this.anthracnoseStageSummary,
    required this.anthracnoseTrendSeries,
    required this.primaryDisease,
    required this.latestScanDate,
    required this.rowCompleteness,
  });
}
