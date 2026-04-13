class ScanItem {
  final int id;
  final String title;
  final String description;
  final String timestamp;
  final String imagePath;
  final String imageUrl;
  final String checksum;
  final String source;
  final String updatedAt;
  final String disease;
  final double confidence;
  final double severityValue;
  final int? photoId;
  final String scanDir;
  // New normalized fields
  final int? treeId;
  final String treeName;
  final String treeLocation;
  final String treeVariety;
  final int? diseaseId;
  final String diseaseName;
  final String diseaseDescription;
  final String diseaseSymptoms;
  final String diseasePrevention;
  final int? severityLevelId;
  final String severityLevelName;
  final String severityLevelDescription;

  ScanItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.imagePath,
    required this.imageUrl,
    required this.checksum,
    required this.source,
    required this.updatedAt,
    required this.disease,
    required this.confidence,
    required this.severityValue,
    this.photoId,
    required this.scanDir,
    this.treeId,
    this.treeName = '',
    this.treeLocation = '',
    this.treeVariety = '',
    this.diseaseId,
    this.diseaseName = '',
    this.diseaseDescription = '',
    this.diseaseSymptoms = '',
    this.diseasePrevention = '',
    this.severityLevelId,
    this.severityLevelName = '',
    this.severityLevelDescription = '',
  });

  static int _deriveIdFromScanDir(String scanDir) {
    // Example: .../scan_20260404_141212 -> 20260404141212
    final match = RegExp(r'scan_(\d{8})_(\d{6})').firstMatch(scanDir);
    if (match == null) return 0;
    final raw = '${match.group(1)}${match.group(2)}';
    return int.tryParse(raw) ?? 0;
  }

  static double _numToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  factory ScanItem.fromJson(Map<String, dynamic> json) {
    // Backward-compatible parsing:
    // - Old Pi payload: {id,title,description,timestamp,image_url,...}
    // - RasPi payload: {timestamp,classification:{class,confidence},reduced_image,scan_dir,database_id}

    final classification = json['classification'];
    final bool isRasPiPayload = classification is Map<String, dynamic> || json.containsKey('reduced_image') || json.containsKey('scan_dir');

    final String timestamp = json['timestamp']?.toString() ?? '';
    final String scanDir = json['scan_dir']?.toString() ?? '';
    final String reducedImage = json['reduced_image']?.toString() ?? '';

    // Normalize timestamp to canonical ISO format for consistent deduplication
    String normalizedTimestamp = '';
    if (timestamp.isNotEmpty) {
      final dt = DateTime.tryParse(timestamp);
      if (dt != null) {
        normalizedTimestamp = dt.toUtc().toIso8601String();
      } else {
        // If unparseable, use original for backward compatibility
        normalizedTimestamp = timestamp;
      }
    }

    // Determine image URL with deterministic precedence: image_url > reduced_image > image_path > file_path
    String imageUrl = '';
    if (json['image_url']?.toString().isNotEmpty == true) {
      imageUrl = json['image_url'].toString();
    } else if (reducedImage.isNotEmpty) {
      imageUrl = reducedImage;
    } else if (json['image_path']?.toString().isNotEmpty == true) {
      imageUrl = json['image_path'].toString();
    } else if (json['file_path']?.toString().isNotEmpty == true) {
      imageUrl = json['file_path'].toString();
    }

    final String disease = isRasPiPayload
        ? ((classification is Map<String, dynamic>) ? classification['class']?.toString() : null) ?? ''
        : (json['disease']?.toString() ?? '');

    final double confidence = isRasPiPayload
        ? ((classification is Map<String, dynamic>) ? _numToDouble(classification['confidence']) : 0.0)
        : _numToDouble(json['confidence']);

    final double severityValue = json.containsKey('severity_value')
        ? _numToDouble(json['severity_value'])
        : (disease.toLowerCase() == 'healthy' ? 0.0 : (confidence * 100.0));

    final int? photoId = json['photo_id'] is int
        ? json['photo_id'] as int
        : int.tryParse(json['photo_id']?.toString() ?? '');

    final int? databaseId = json['database_id'] is int
        ? json['database_id'] as int
        : int.tryParse(json['database_id']?.toString() ?? '');

    final int id = databaseId ?? int.tryParse(json['id']?.toString() ?? '') ?? _deriveIdFromScanDir(scanDir);

    final String title = (json['title']?.toString().isNotEmpty == true)
        ? json['title'].toString()
        : (disease.isNotEmpty ? disease : 'Scan');

    // Parse tree data
    final tree = json['tree'];
    final int? treeId = tree is Map<String, dynamic> ? (tree['id'] is int ? tree['id'] as int : int.tryParse(tree['id']?.toString() ?? '')) : null;
    final String treeName = tree is Map<String, dynamic> ? tree['name']?.toString() ?? '' : '';
    final String treeLocation = tree is Map<String, dynamic> ? tree['location']?.toString() ?? '' : '';
    final String treeVariety = tree is Map<String, dynamic> ? tree['variety']?.toString() ?? '' : '';

    // Parse disease data
    final diseaseObj = json['disease_obj'] ?? json['disease_data'];
    final int? diseaseId = diseaseObj is Map<String, dynamic> ? (diseaseObj['id'] is int ? diseaseObj['id'] as int : int.tryParse(diseaseObj['id']?.toString() ?? '')) : null;
    final String diseaseName = diseaseObj is Map<String, dynamic> ? diseaseObj['name']?.toString() ?? disease : disease;
    final String diseaseDescription = diseaseObj is Map<String, dynamic> ? diseaseObj['description']?.toString() ?? '' : '';
    final String diseaseSymptoms = diseaseObj is Map<String, dynamic> ? diseaseObj['symptoms']?.toString() ?? '' : '';
    final String diseasePrevention = diseaseObj is Map<String, dynamic> ? diseaseObj['prevention']?.toString() ?? '' : '';

    // Parse severity level data
    final severityObj = json['severity_level'] ?? json['severity_data'];
    final int? severityLevelId = severityObj is Map<String, dynamic> ? (severityObj['id'] is int ? severityObj['id'] as int : int.tryParse(severityObj['id']?.toString() ?? '')) : null;
    final String severityLevelName = severityObj is Map<String, dynamic> ? severityObj['name']?.toString() ?? '' : '';
    final String severityLevelDescription = severityObj is Map<String, dynamic> ? severityObj['description']?.toString() ?? '' : '';

    return ScanItem(
      id: id,
      title: title,
      description: json['description']?.toString() ?? '',
      timestamp: normalizedTimestamp,
      imagePath: json['image_path']?.toString() ?? '',
      // For RasPi payload, use reduced_image so downloadImage() can extract filename.
      imageUrl: imageUrl,
      checksum: json['metadata_hash']?.toString() ?? json['checksum']?.toString() ?? '',
      source: json['source']?.toString() ?? 'pi',
      updatedAt: json['updated_at']?.toString() ?? '',
      disease: disease,
      confidence: confidence,
      severityValue: severityValue,
      photoId: photoId,
      scanDir: scanDir,
      treeId: treeId,
      treeName: treeName,
      treeLocation: treeLocation,
      treeVariety: treeVariety,
      diseaseId: diseaseId,
      diseaseName: diseaseName,
      diseaseDescription: diseaseDescription,
      diseaseSymptoms: diseaseSymptoms,
      diseasePrevention: diseasePrevention,
      severityLevelId: severityLevelId,
      severityLevelName: severityLevelName,
      severityLevelDescription: severityLevelDescription,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'timestamp': timestamp,
        'image_path': imagePath,
        'image_url': imageUrl,
        'checksum': checksum,
        'source': source,
        'updated_at': updatedAt,
      'disease': disease,
      'confidence': confidence,
      'severity_value': severityValue,
      'photo_id': photoId,
      'scan_dir': scanDir,
      'tree_id': treeId,
      'tree_name': treeName,
      'tree_location': treeLocation,
      'tree_variety': treeVariety,
      'disease_id': diseaseId,
      'disease_name': diseaseName,
      'disease_description': diseaseDescription,
      'disease_symptoms': diseaseSymptoms,
      'disease_prevention': diseasePrevention,
      'severity_level_id': severityLevelId,
      'severity_level_name': severityLevelName,
      'severity_level_description': severityLevelDescription,
      };
}
