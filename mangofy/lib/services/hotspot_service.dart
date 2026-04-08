import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;
import '../model/pi_qr_data.dart';

class HotspotService {
  HotspotService._();
  static final HotspotService instance = HotspotService._();

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
        joinOnce: true,
      );
      if (!connected) return false;

      try {
        await WiFiForIoTPlugin.forceWifiUsage(true);
      } catch (_) {}

      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyPi(String baseUrl) async {
    try {
      final uri = Uri.parse(baseUrl).replace(path: '/api/status');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = response.body.toLowerCase();
        return body.contains('ready') || body.isNotEmpty;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

