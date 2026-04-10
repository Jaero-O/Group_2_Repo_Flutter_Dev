import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../model/scan_item.dart';

class PiApi {
  PiApi._();
  static final PiApi instance = PiApi._();
  static const String hotspotBaseUrl = 'http://192.168.4.1:5000';
  static const String defaultBaseUrl = hotspotBaseUrl;

  Uri _makeUri(String baseUrl, String path) {
    final base = Uri.parse(baseUrl);
    final origin = base.hasScheme
        ? '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}'
        : baseUrl;
    final normalized = origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalized$normalizedPath');
  }

  Future<bool> getStatus(String baseUrl) async {
    try {
      final uri = _makeUri(baseUrl, '/api/status');
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      return resp.statusCode == 200 && (resp.body.toLowerCase().contains('ready') || resp.body.isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  Future<ScanItem> getScan(String baseUrl, String id) async {
    final uri = _makeUri(baseUrl, '/api/scan/$id');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('Scan $id not found on Pi at $baseUrl');
    return ScanItem.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<ScanItem>> getScansAll(String baseUrl) async {
    final uri = _makeUri(baseUrl, '/api/scan/all');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('Failed fetch all scans from Pi at $baseUrl');
    final decoded = jsonDecode(resp.body);
    final List<dynamic> arr;
    if (decoded is List) {
      arr = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final dynamic inner = decoded['scans'] ?? decoded['results'] ?? decoded['data'];
      if (inner is List) {
        arr = inner;
      } else {
        arr = [decoded];
      }
    } else {
      arr = <dynamic>[];
    }
    return arr.whereType<Map>().map((e) => ScanItem.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<List<ScanItem>> getScansSince(String baseUrl, String timestamp) async {
    final uri = _makeUri(baseUrl, '/api/scan/since/$timestamp');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('Failed fetch scans since $timestamp from Pi at $baseUrl');
    final decoded = jsonDecode(resp.body);
    final List<dynamic> arr;
    if (decoded is List) {
      arr = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final dynamic inner = decoded['scans'] ?? decoded['results'] ?? decoded['data'];
      if (inner is List) {
        arr = inner;
      } else {
        arr = [decoded];
      }
    } else {
      arr = <dynamic>[];
    }
    return arr.whereType<Map>().map((e) => ScanItem.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<String> downloadImage(ScanItem item, String baseUrl) async {
    final fileName = item.imageUrl.split('/').last;
    final uri = _makeUri(baseUrl, '/api/image/$fileName');

    final resp = await http.get(uri).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) throw Exception('Image download failed from Pi at $baseUrl');

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(resp.bodyBytes);
    return path;
  }
}
