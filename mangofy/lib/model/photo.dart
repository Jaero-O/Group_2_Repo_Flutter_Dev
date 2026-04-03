class Photo {
  final int? id;
  final String name;
  final String data; // base64 encoded image data
  final String timestamp;

  Photo({
    this.id,
    required this.name,
    required this.data,
    required this.timestamp,
  });

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as int?,
      name: map['name'] as String,
      data: map['data'] as String,
      timestamp: map['timestamp'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'data': data,
      'timestamp': timestamp,
    };
  }
}