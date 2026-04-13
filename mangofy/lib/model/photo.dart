class Photo {
  final int? id;
  final String name;
  final String data; // base64 encoded image data
  final String timestamp;
  final String? path; // optional local file path for file-backed images
  // Additional scan fields
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? checksum;
  final String? source;
  final String? updatedAt;
  final String? disease;
  final String? severityLabel;
  final double? confidence;
  final double? severityValue;
  final int? photoId;
  final String? scanDir;

  Photo({
    this.id,
    required this.name,
    required this.data,
    required this.timestamp,
    this.path,
    this.title,
    this.description,
    this.imageUrl,
    this.checksum,
    this.source,
    this.updatedAt,
    this.disease,
    this.severityLabel,
    this.confidence,
    this.severityValue,
    this.photoId,
    this.scanDir,
  });

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as int?,
      name: map['name'] as String,
      data: (map['data'] as String?) ?? '', // Handle null data gracefully
      timestamp: map['timestamp'] as String,
      path: map['path'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      checksum: map['checksum'] as String?,
      source: map['source'] as String?,
      updatedAt: map['updated_at'] as String?,
      disease: map['disease'] as String?,
      severityLabel: map['severity_label'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble(),
      severityValue: (map['severity_value'] as num?)?.toDouble(),
      photoId: map['photo_id'] as int?,
      scanDir: map['scan_dir'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'data': data,
      'timestamp': timestamp,
      if (path != null) 'path': path,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (checksum != null) 'checksum': checksum,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (disease != null) 'disease': disease,
      if (severityLabel != null) 'severity_label': severityLabel,
      if (confidence != null) 'confidence': confidence,
      if (severityValue != null) 'severity_value': severityValue,
      if (photoId != null) 'photo_id': photoId,
      if (scanDir != null) 'scan_dir': scanDir,
    };
  }
}

// Lightweight version for gallery grid - excludes large data field
class PhotoMetadata {
  final int? id;
  final String name;
  final String timestamp;
  final String? path;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? checksum;
  final String? source;
  final String? updatedAt;
  final String? disease;
  final String? severityLabel;
  final double? confidence;
  final double? severityValue;
  final int? photoId;
  final String? scanDir;

  PhotoMetadata({
    this.id,
    required this.name,
    required this.timestamp,
    this.path,
    this.title,
    this.description,
    this.imageUrl,
    this.checksum,
    this.source,
    this.updatedAt,
    this.disease,
    this.severityLabel,
    this.confidence,
    this.severityValue,
    this.photoId,
    this.scanDir,
  });

  factory PhotoMetadata.fromMap(Map<String, dynamic> map) {
    return PhotoMetadata(
      id: map['id'] as int?,
      name: map['name'] as String,
      timestamp: map['timestamp'] as String,
      path: map['path'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      checksum: map['checksum'] as String?,
      source: map['source'] as String?,
      updatedAt: map['updated_at'] as String?,
      disease: map['disease'] as String?,
      severityLabel: map['severity_label'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble(),
      severityValue: (map['severity_value'] as num?)?.toDouble(),
      photoId: map['photo_id'] as int?,
      scanDir: map['scan_dir'] as String?,
    );
  }

  // Convert to full Photo by loading data from database
  Future<Photo> toFullPhoto() async {
    // This will be implemented to load the full photo data when needed
    return Photo(
      id: id,
      name: name,
      data: '', // Will be loaded separately
      timestamp: timestamp,
      path: path,
      title: title,
      description: description,
      imageUrl: imageUrl,
      checksum: checksum,
      source: source,
      updatedAt: updatedAt,
      disease: disease,
      severityLabel: severityLabel,
      confidence: confidence,
      severityValue: severityValue,
      photoId: photoId,
      scanDir: scanDir,
    );
  }
}
