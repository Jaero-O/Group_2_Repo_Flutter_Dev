enum RiskLevel { low, moderate, high, critical }

class RiskAssessment {
  final double infectionProbability;
  final double estimatedYieldLoss;
  final RiskLevel riskLevel;
  final double weatherContribution;
  final double trendContribution;
  final double dataConfidence;

  const RiskAssessment({
    required this.infectionProbability,
    required this.estimatedYieldLoss,
    required this.riskLevel,
    required this.weatherContribution,
    required this.trendContribution,
    required this.dataConfidence,
  });
}
