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
  });

  factory ScanItem.fromJson(Map<String, dynamic> json) => ScanItem(
        id: int.tryParse(json['id'].toString()) ?? 0,
        title: json['title']?.toString() ?? 'Scan',
        description: json['description']?.toString() ?? '',
        timestamp: json['timestamp']?.toString() ?? '',
        imagePath: json['image_path']?.toString() ?? '',
        imageUrl: json['image_url']?.toString() ?? '',
        checksum: json['metadata_hash']?.toString() ?? '',
        source: json['source']?.toString() ?? 'pi',
        updatedAt: json['updated_at']?.toString() ?? '',
      );

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
      };
}
