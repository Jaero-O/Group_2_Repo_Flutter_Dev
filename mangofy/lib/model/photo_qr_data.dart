class PhotoQrData {
  final String base64Image;
  final String? mimeType;
  final DateTime? timestamp;

  PhotoQrData({
    required this.base64Image,
    this.mimeType = 'image/jpeg',
    this.timestamp,
  });

  factory PhotoQrData.fromRawQr(String raw) {
    // Expects format: "data:image/jpeg;base64,<data>" or plain base64
    if (raw.startsWith('data:')) {
      final semicolon = raw.indexOf(';');
      final comma = raw.indexOf(',');
      final mimeType = raw.substring(5, semicolon);
      final base64Image = raw.substring(comma + 1);
      return PhotoQrData(
        base64Image: base64Image,
        mimeType: mimeType,
        timestamp: DateTime.now(),
      );
    }
    return PhotoQrData(
      base64Image: raw,
      timestamp: DateTime.now(),
    );
  }
}