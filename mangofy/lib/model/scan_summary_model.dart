// model/scan_summary_model.dart

// Represents the aggregated summary data for all disease scans.
class ScanSummary {
  final int totalScans;
  final int anthracnoseTotal;
  final int healthyCount;
  final int earlyStageCount;
  final int advancedStageCount;

  ScanSummary({
    required this.totalScans,
    this.anthracnoseTotal = 0,
    required this.healthyCount,
    required this.earlyStageCount,
    required this.advancedStageCount,
  });

  @Deprecated('Use earlyStageCount instead.')
  int get moderateCount => earlyStageCount;

  @Deprecated('Use advancedStageCount instead.')
  int get severeCount => advancedStageCount;
}
