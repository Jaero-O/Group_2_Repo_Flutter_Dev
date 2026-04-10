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

    return ScanItem(
      id: id,
      title: title,
      description: json['description']?.toString() ?? '',
      timestamp: timestamp,
      imagePath: json['image_path']?.toString() ?? '',
      // For RasPi payload, use reduced_image so downloadImage() can extract filename.
      imageUrl: (json['image_url']?.toString() ?? '').isNotEmpty ? json['image_url']!.toString() : reducedImage,
      checksum: json['metadata_hash']?.toString() ?? json['checksum']?.toString() ?? '',
      source: json['source']?.toString() ?? 'pi',
      updatedAt: json['updated_at']?.toString() ?? '',
      disease: disease,
      confidence: confidence,
      severityValue: severityValue,
      photoId: photoId,
      scanDir: scanDir,
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
      };
}
