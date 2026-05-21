import 'scan_item.dart';

const Set<String> _kGenericDiseaseLabels = {
  'imported dataset',
  'dataset',
  'image detected',
  'imported dataset detected',
  'dataset detected',
};

const Set<String> _kPiLinuxPathPrefixes = {
  '/home/',
  '/opt/',
  '/var/',
  '/etc/',
  '/usr/',
  '/srv/',
  '/tmp/',
};

bool isGenericDetectionLabel(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return _kGenericDiseaseLabels.contains(normalized);
}

bool isPiLinuxPath(String value) {
  var normalized = value.trim();
  if (normalized.isEmpty) return false;

  final uri = Uri.tryParse(normalized);
  if (uri != null && uri.isAbsolute && uri.scheme == 'file') {
    try {
      normalized = uri.toFilePath();
    } catch (_) {
      normalized = normalized.replaceFirst(RegExp(r'^file://'), '');
    }
  }

  final path = normalized.toLowerCase();
  if (RegExp(r'^[a-z]:[\\/]').hasMatch(path)) {
    return false;
  }
  if (path.startsWith('\\\\')) {
    return false;
  }

  for (final prefix in _kPiLinuxPathPrefixes) {
    if (path.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

String formatDiseaseClassLabel(String raw) {
  final normalized = raw.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  if (normalized.isEmpty) return '';

  final words = normalized.split(RegExp(r'\s+'));
  return words
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String displayDiseaseName(
  ScanItem item, {
  String unknownLabel = 'Unknown Disease',
}) {
  final canonical = item.diseaseName.trim();
  if (canonical.isNotEmpty && !isGenericDetectionLabel(canonical)) {
    return canonical;
  }

  final formattedClass = formatDiseaseClassLabel(item.diseaseClass);
  if (formattedClass.isNotEmpty && !isGenericDetectionLabel(formattedClass)) {
    return formattedClass;
  }

  final formattedFallback = formatDiseaseClassLabel(item.disease);
  if (formattedFallback.isNotEmpty &&
      !isGenericDetectionLabel(formattedFallback)) {
    return formattedFallback;
  }

  return unknownLabel;
}

bool isAnthracnoseScan(ScanItem item) {
  final disease = displayDiseaseName(item, unknownLabel: '').toLowerCase();
  return disease.contains('anthracnose');
}

String normalizeSeverityLabel(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) return '';
  if (value == 'none') return '';
  if (value.contains('healthy')) return 'Healthy';
  if (value == 'high') return 'Advanced Stage';
  if (value == 'low' || value == 'trace') return 'Early Stage';
  if (value.contains('advanced') ||
      value.contains('severe') ||
      value.contains('critical')) {
    return 'Advanced Stage';
  }
  if (value.contains('early') ||
      value.contains('moderate') ||
      value.contains('mid')) {
    return 'Early Stage';
  }
  return raw.trim();
}

String statusForScan(
  ScanItem item, {
  bool anthracnoseOnly = true,
  String notApplicableLabel = '--',
}) {
  final disease = displayDiseaseName(item, unknownLabel: '').toLowerCase();
  if (disease == 'healthy') return 'Healthy';

  if (anthracnoseOnly && !isAnthracnoseScan(item)) return notApplicableLabel;

  final level = item.severityLevelName.trim();
  if (level.isNotEmpty && level.toLowerCase() != 'none') return level;

  return 'Unclassified';
}

String statusKeyForScan(
  ScanItem item, {
  bool anthracnoseOnly = true,
  String notApplicableKey = 'not_applicable',
  String notApplicableLabel = '--',
}) {
  final disease = displayDiseaseName(item, unknownLabel: '').toLowerCase();
  if (disease == 'healthy') return 'healthy';

  if (anthracnoseOnly && !isAnthracnoseScan(item)) return notApplicableKey;

  final status = statusForScan(
    item,
    anthracnoseOnly: anthracnoseOnly,
    notApplicableLabel: notApplicableLabel,
  ).trim().toLowerCase();

  if (status.contains('healthy')) return 'healthy';
  if (status.contains('advanced') ||
      status.contains('severe') ||
      status.contains('critical')) {
    return 'advanced_stage';
  }
  if (status == 'high') return 'advanced_stage';
  if (status.contains('early') ||
      status.contains('moderate') ||
      status.contains('mid')) {
    return 'early_stage';
  }
  if (status == 'low' || status == 'trace') return 'early_stage';
  if (status == notApplicableLabel.toLowerCase() ||
      status == 'n/a' ||
      status == 'not applicable') {
    return notApplicableKey;
  }
  return status.replaceAll(' ', '_');
}
