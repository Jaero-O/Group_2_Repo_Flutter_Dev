import 'dart:convert';

class PiQrData {
  final String ssid;
  final String password;
  final String scanUrl;
  final String scanId;
  final DateTime issuedAt;
  final String? altScanUrl;

  PiQrData({
    required this.ssid,
    required this.password,
    required this.scanUrl,
    required this.scanId,
    required this.issuedAt,
    this.altScanUrl,
  });

  factory PiQrData.fromJson(Map<String, dynamic> obj) {
    return PiQrData(
      ssid: obj['ssid']?.toString() ?? '',
      password: obj['pwd']?.toString() ?? obj['password']?.toString() ?? '',
      scanUrl: obj['scan_url']?.toString() ?? obj['scanUrl']?.toString() ?? '',
      scanId: obj['scan_id']?.toString() ?? obj['scanId']?.toString() ?? '',
      issuedAt: DateTime.tryParse(obj['issued_at']?.toString() ?? obj['issuedAt']?.toString() ?? '') ?? DateTime.now().toUtc(),
      altScanUrl: obj['alt_scan_url']?.toString() ?? obj['altScanUrl']?.toString(),
    );
  }

  factory PiQrData.fromRaw(String raw) {
    final Map<String, dynamic> obj = jsonDecode(raw);
    return PiQrData.fromJson(obj);
  }
}