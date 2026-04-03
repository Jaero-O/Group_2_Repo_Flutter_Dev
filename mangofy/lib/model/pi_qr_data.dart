import 'dart:convert';

class PiQrData {
  final String ssid;
  final String password;
  final String scanUrl;
  final String scanId;
  final DateTime issuedAt;

  PiQrData({
    required this.ssid,
    required this.password,
    required this.scanUrl,
    required this.scanId,
    required this.issuedAt,
  });

  factory PiQrData.fromRaw(String raw) {
    final Map<String, dynamic> obj = jsonDecode(raw);
    return PiQrData(
      ssid: obj['ssid'] as String,
      password: obj['pwd'] as String,
      scanUrl: obj['scan_url'] as String,
      scanId: obj['scan_id']?.toString() ?? '',
      issuedAt: DateTime.parse(obj['issued_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}