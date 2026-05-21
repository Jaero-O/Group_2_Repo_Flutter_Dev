import 'scan_summary_model.dart';

class OrchardSnapshot {
  final ScanSummary summary;
  final List<Map<String, dynamic>> diseaseDistributionRows;
  final Map<String, int> anthracnoseStageSummary;
  final List<Map<String, dynamic>> anthracnoseTrendSeries;
  final List<Map<String, dynamic>> anthracnoseWeeklyStageSeries;
  final List<Map<String, dynamic>> anthracnosePerTreeImageSeries;
  final String primaryDisease;
  final String? latestScanDate;
  final Map<String, int> rowCompleteness;

  const OrchardSnapshot({
    required this.summary,
    required this.diseaseDistributionRows,
    required this.anthracnoseStageSummary,
    required this.anthracnoseTrendSeries,
    required this.anthracnoseWeeklyStageSeries,
    required this.anthracnosePerTreeImageSeries,
    required this.primaryDisease,
    required this.latestScanDate,
    required this.rowCompleteness,
  });
}
