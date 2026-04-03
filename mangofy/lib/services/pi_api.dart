import 'dart:convert';
import 'dart:io'; // Required for File
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // Required for getApplicationDocumentsDirectory
import '../model/scan_item.dart';

class PiApi {
  PiApi._();
  static final PiApi instance = PiApi._();

  // Switch to the ZeroTier Managed IP
  static const String _baseUrl = 'http://192.168.196.139:5000';

  // Helper to check if the Pi is reachable over VPN
  Future<bool> checkStatus() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/api/status'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<ScanItem> getScan(String id) async {
    final resp = await http.get(Uri.parse('$_baseUrl/api/scan/$id'));
    if (resp.statusCode != 200) throw Exception('Scan missing on Pi');
    return ScanItem.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<ScanItem>> getScansSince(String timestamp) async {
    final resp = await http.get(Uri.parse('$_baseUrl/api/scan/since/$timestamp'));
    if (resp.statusCode != 200) throw Exception('Failed sync');
    final arr = jsonDecode(resp.body) as List;
    return arr.map((e) => ScanItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ScanItem>> getScansAll() async {
    final resp = await http.get(Uri.parse('$_baseUrl/api/scan/all'));
    if (resp.statusCode != 200) throw Exception('Failed fetch all scans');
    final arr = jsonDecode(resp.body) as List;
    return arr.map((e) => ScanItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> downloadImage(ScanItem item) async {
    // Force the use of the ZeroTier IP by rebuilding the URL from the filename
    final fileName = item.imageUrl.split('/').last;
    final downloadUrl = '$_baseUrl/api/image/$fileName';

    final resp = await http.get(Uri.parse(downloadUrl));
    if (resp.statusCode != 200) throw Exception('Image download failed');

    // Fixed typo: getApplicationDocumentsDirectory instead of getApplicationDocuments Lindos
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath);
    await file.writeAsBytes(resp.bodyBytes);
    
    return filePath;
  }
}