import 'dart:convert';
import 'dart:typed_data';
import '../model/photo_qr_data.dart';

class PhotoDecoderService {
  /// Decodes a PhotoQrData object into raw image bytes.
  Uint8List decode(PhotoQrData data) {
    try {
      return base64Decode(data.base64Image);
    } catch (e) {
      throw FormatException('Failed to decode base64 image data: $e');
    }
  }

  /// Convenience method: goes straight from raw QR string to bytes.
  Uint8List decodeFromRaw(String raw) {
    final qrData = PhotoQrData.fromRawQr(raw);
    return decode(qrData);
  }
}