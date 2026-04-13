import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;
import '../model/pi_qr_data.dart';

class HotspotService {
  HotspotService._();
  static final HotspotService instance = HotspotService._();

  String? _sanitizeSsid(String? ssid) {
    if (ssid == null) return null;
    final v = ssid.trim();
    if (v.isEmpty) return null;
    // Some Android APIs return quoted SSIDs.
    if (v.length >= 2 && v.startsWith('"') && v.endsWith('"')) {
      return v.substring(1, v.length - 1);
    }
    return v;
  }

  Future<String?> getCurrentSsid() async {
    try {
      final ssid = await WiFiForIoTPlugin.getSSID();
      return _sanitizeSsid(ssid);
    } catch (_) {
      return null;
    }
  }

  Future<bool> connectPiHotspot() async {
    try {
      final connected = await WiFiForIoTPlugin.connect(
        'Pi-Proto-Net',
        password: 'prototype_pass',
        security: NetworkSecurity.WPA,
        withInternet: false,
      );

      if (!connected) return false;
      try {
        await WiFiForIoTPlugin.forceWifiUsage(true);
      } catch (_) {}
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connectToPi(PiQrData data) async {
    try {
      final connected = await WiFiForIoTPlugin.connect(
        data.ssid,
        password: data.password,
        security: NetworkSecurity.WPA,
        withInternet: false,
        joinOnce: false,
      );
      if (!connected) return false;

      try {
        await WiFiForIoTPlugin.forceWifiUsage(true);
      } catch (_) {}

      // Reduced delay: rely on readiness polling instead of fixed wait.
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyPiOnce(String baseUrl, {String statusPath = '/api/status'}) async {
    try {
      final base = Uri.parse(baseUrl);
      final uri = base.replace(path: statusPath);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = response.body.toLowerCase();
        return body.contains('ready');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> waitForPiReady(
    String baseUrl, {
    String statusPath = '/api/status',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    int attempt = 0;
    while (DateTime.now().isBefore(deadline)) {
      attempt++;
      final ok = await verifyPiOnce(baseUrl, statusPath: statusPath);
      if (ok) return true;

      final backoffMs = (attempt <= 3)
          ? 200
          : (attempt <= 6)
              ? 500
              : 800;
      await Future.delayed(Duration(milliseconds: backoffMs));
    }
    return false;
  }

  Future<bool> waitForPiReadyRacing(
    List<String> candidates, {
    String statusPath = '/api/status',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (candidates.isEmpty) return false;

    final futures = candidates.map((url) => waitForPiReady(url, statusPath: statusPath, timeout: timeout).then((ready) => ready ? url : null));
    final results = await Future.wait(futures);
    return results.any((url) => url != null);
  }

  Future<String?> findFirstReadyPi(
    List<String> candidates, {
    String statusPath = '/api/status',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (candidates.isEmpty) return null;

    final futures = candidates.map((url) => waitForPiReady(url, statusPath: statusPath, timeout: timeout).then((ready) => ready ? url : null));
    final results = await Future.wait(futures);
    return results.where((url) => url != null).cast<String>().firstOrNull;
  }
}

