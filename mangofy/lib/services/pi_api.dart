import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../model/scan_item.dart';
import '../model/pi_qr_data.dart';

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

  Future<void> _streamToFile(http.ByteStream stream, File outFile) async {
    final sink = outFile.openWrite();
    try {
      await stream.pipe(sink);
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  Future<String> downloadFile({
    required String baseUrl,
    required String path,
    required String fileName,
    Duration timeout = const Duration(seconds: 60),
    int retries = 2,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final finalPath = '${dir.path}/$fileName';
    final tmpPath = '$finalPath.part';
    final finalFile = File(finalPath);
    final tmpFile = File(tmpPath);

    int attempt = 0;
    while (true) {
      attempt++;
      try {
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }

        final uri = _makeUri(baseUrl, path);
        final client = http.Client();
        try {
          final req = http.Request('GET', uri);
          final resp = await client.send(req).timeout(timeout);
          if (resp.statusCode != 200) {
            throw Exception('Download failed (${resp.statusCode}) from $uri');
          }
          await _streamToFile(resp.stream, tmpFile).timeout(timeout);
        } finally {
          client.close();
        }

        if (await finalFile.exists()) {
          await finalFile.delete();
        }
        await tmpFile.rename(finalPath);
        return finalPath;
      } catch (e) {
        if (attempt > retries + 1) rethrow;
        // Hotspot routing can take a few seconds to stabilize.
        final backoff = Duration(milliseconds: 400 * attempt * attempt);
        await Future.delayed(backoff);
      }
    }
  }

  Future<bool> getStatus(String baseUrl, {PiQrEndpoints? endpoints}) async {
    try {
      final uri = _makeUri(baseUrl, (endpoints ?? const PiQrEndpoints()).statusPath);
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      return resp.statusCode == 200 && resp.body.toLowerCase().contains('ready');
    } catch (_) {
      return false;
    }
  }

  Future<ScanItem> getScan(String baseUrl, String id, {PiQrEndpoints? endpoints}) async {
    final ep = endpoints ?? const PiQrEndpoints();
    final uri = _makeUri(baseUrl, ep.resolveScanByIdPath(id));
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('Scan $id not found on Pi at $baseUrl');
    return ScanItem.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<ScanItem>> getScansAll(String baseUrl, {PiQrEndpoints? endpoints}) async {
    final ep = endpoints ?? const PiQrEndpoints();
    final uri = _makeUri(baseUrl, ep.scansAllPath);
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch all scans from Pi at $baseUrl (HTTP ${resp.statusCode}). Check that the Pi is running and the scans endpoint (${ep.scansAllPath}) is correct.');
    }
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

  Future<List<ScanItem>> getScansSince(String baseUrl, String timestamp, {PiQrEndpoints? endpoints}) async {
    final ep = endpoints ?? const PiQrEndpoints();
    final uri = _makeUri(baseUrl, ep.resolveScansSincePath(timestamp));
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch scans since $timestamp from Pi at $baseUrl (HTTP ${resp.statusCode}). Check that the Pi is running and the scans-since endpoint (${ep.resolveScansSincePath(timestamp)}) is correct.');
    }
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

  Future<String> downloadImage(ScanItem item, String baseUrl, {PiQrEndpoints? endpoints}) async {
    final ep = endpoints ?? const PiQrEndpoints();
    final fileName = item.imageUrl.split('/').last;

    // Prefer an explicit URL if the API returns one.
    final raw = item.imageUrl.trim();
    final Uri? direct = Uri.tryParse(raw);
    final String path;
    if (direct != null && direct.hasScheme) {
      // Downloading from an absolute URL: use it directly.
      final uri = direct;
      final directory = await getApplicationDocumentsDirectory();
      final destName = fileName.isNotEmpty ? fileName : 'image_${item.id}.jpg';
      final destPath = '${directory.path}/$destName';

      final client = http.Client();
      try {
        final req = http.Request('GET', uri);
        final resp = await client.send(req).timeout(const Duration(seconds: 30));
        if (resp.statusCode != 200) throw Exception('Image download failed (${resp.statusCode}) from $uri. Check that the image URL is accessible.');
        final tmpFile = File('$destPath.part');
        if (await tmpFile.exists()) await tmpFile.delete();
        await _streamToFile(resp.stream, tmpFile);
        if (await File(destPath).exists()) await File(destPath).delete();
        await tmpFile.rename(destPath);
        return destPath;
      } finally {
        client.close();
      }
    } else if (raw.startsWith('/')) {
      path = raw;
    } else {
      path = ep.resolveImagePath(fileName);
    }

    final destName = fileName.isNotEmpty ? fileName : 'image_${item.id}.jpg';
    return downloadFile(
      baseUrl: baseUrl,
      path: path,
      fileName: destName,
      timeout: const Duration(seconds: 60),
      retries: 2,
    );
  }

  Future<String> downloadDatabase(String baseUrl, {required PiQrEndpoints endpoints}) async {
    final path = endpoints.dbDownloadPath;
    if (path == null || path.isEmpty) {
      throw const FormatException('QR payload is missing db download endpoint.');
    }
    return downloadFile(
      baseUrl: baseUrl,
      path: path,
      fileName: 'pi_sync.db',
      timeout: const Duration(seconds: 120),
      retries: 2,
    );
  }

  Future<String> downloadScanBundle(String baseUrl, {required PiQrEndpoints endpoints, required String scanId}) async {
    final path = endpoints.resolveBundlePath(scanId);
    return downloadFile(
      baseUrl: baseUrl,
      path: path,
      fileName: 'scan_${scanId}_bundle.zip',
      timeout: const Duration(seconds: 180),
      retries: 2,
    );
  }
}
