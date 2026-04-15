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

  List<Map<String, dynamic>> _extractScanMaps(dynamic decoded) {
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
    return arr.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<List<ScanItem>?> _getScansAllPaginated(
    String baseUrl,
    PiQrEndpoints ep,
  ) async {
    const int perPage = 250;
    const int maxPages = 500;
    const int pageConcurrency = 4;
    final seenKeys = <String>{};
    final collected = <Map<String, dynamic>>[];

    Future<List<Map<String, dynamic>>?> fetchPageRows(int page) async {
      final baseUri = _makeUri(baseUrl, ep.scansAllPath);
      final uri = baseUri.replace(
        queryParameters: {
          ...baseUri.queryParameters,
          'page': '$page',
          'per_page': '$perPage',
        },
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(resp.body);
      return _extractScanMaps(decoded);
    }

    final firstPageRows = await fetchPageRows(1);
    if (firstPageRows == null) return null;
    if (firstPageRows.isEmpty) return <ScanItem>[];

    int addedOnFirst = 0;
    for (final row in firstPageRows) {
      final id = row['id'] ?? row['database_id'];
      final key = id != null
          ? 'id:$id'
          : '${row['scan_dir'] ?? ''}|${row['timestamp'] ?? row['scan_timestamp'] ?? ''}|${row['image_url'] ?? row['reduced_image'] ?? ''}';
      if (seenKeys.add(key)) {
        collected.add(row);
        addedOnFirst++;
      }
    }
    if (addedOnFirst == 0) {
      return collected.map(ScanItem.fromJson).toList();
    }
    final actualPageSize = firstPageRows.length;

    for (int startPage = 2; startPage <= maxPages; startPage += pageConcurrency) {
      final pages = <int>[];
      for (
        int page = startPage;
        page < startPage + pageConcurrency && page <= maxPages;
        page++
      ) {
        pages.add(page);
      }

      final results = await Future.wait(
        pages.map((page) async {
          final rows = await fetchPageRows(page);
          return (page: page, rows: rows);
        }),
      );

      final sorted = [...results]..sort((a, b) => a.page.compareTo(b.page));
      bool reachedTail = false;

      for (final result in sorted) {
        final pageRows = result.rows;
        if (pageRows == null) {
          return null;
        }
        if (pageRows.isEmpty) {
          reachedTail = true;
          break;
        }

        int added = 0;
        for (final row in pageRows) {
          final id = row['id'] ?? row['database_id'];
          final key = id != null
              ? 'id:$id'
              : '${row['scan_dir'] ?? ''}|${row['timestamp'] ?? row['scan_timestamp'] ?? ''}|${row['image_url'] ?? row['reduced_image'] ?? ''}';
          if (seenKeys.add(key)) {
            collected.add(row);
            added++;
          }
        }

        // Server likely ignored pagination and returned repeated first page.
        if (added == 0) {
          reachedTail = true;
          break;
        }
        if (pageRows.length < actualPageSize) {
          reachedTail = true;
          break;
        }
      }

      if (reachedTail) break;
    }

    if (collected.isEmpty) return null;
    return collected.map(ScanItem.fromJson).toList();
  }

  Future<List<ScanItem>> getScansAll(String baseUrl, {PiQrEndpoints? endpoints}) async {
    final ep = endpoints ?? const PiQrEndpoints();
    final paginated = await _getScansAllPaginated(baseUrl, ep);
    if (paginated != null) {
      return paginated;
    }

    final uri = _makeUri(baseUrl, ep.scansAllPath);
    final resp = await http.get(uri).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch all scans from Pi at $baseUrl (HTTP ${resp.statusCode}). Check that the Pi is running and the scans endpoint (${ep.scansAllPath}) is correct.');
    }

    final decoded = jsonDecode(resp.body);
    final arr = _extractScanMaps(decoded);
    return arr.map(ScanItem.fromJson).toList();
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

  Future<String> downloadBulkImagesZip(
    String baseUrl,
    List<String> fileNames, {
    required PiQrEndpoints endpoints,
  }) async {
    final filtered = fileNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    if (filtered.isEmpty) {
      throw const FormatException('No filenames were provided for bulk image download.');
    }

    final path = endpoints.resolveBulkImagesZipPath(filtered);
    return downloadFile(
      baseUrl: baseUrl,
      path: path,
      fileName: 'images_bulk_${DateTime.now().millisecondsSinceEpoch}.zip',
      timeout: const Duration(minutes: 5),
      retries: 1,
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
