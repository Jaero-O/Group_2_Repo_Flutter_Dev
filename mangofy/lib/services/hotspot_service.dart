import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;

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

  Future<bool> verifyPi() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.4.1:5000/api/status'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
