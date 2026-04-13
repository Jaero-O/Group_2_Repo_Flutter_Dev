import 'dart:convert';

class PiQrEndpoints {
  final String statusPath;
  final String? dbDownloadPath;
  final String? scanBundlePathTemplate;

  // Back-compat / optional endpoints used by the current app.
  final String scansAllPath;
  final String scansSincePathTemplate;
  final String scanByIdPathTemplate;
  final String imagePathTemplate;

  const PiQrEndpoints({
    this.statusPath = '/api/status',
    this.dbDownloadPath = '/api/db/download',
    this.scanBundlePathTemplate = '/api/scan/{id}/bundle',
    this.scansAllPath = '/api/scan/all',
    this.scansSincePathTemplate = '/api/scan/since/{timestamp}',
    this.scanByIdPathTemplate = '/api/scan/{id}',
    this.imagePathTemplate = '/api/image/{filename}',
  });

  static String? _readString(Map<String, dynamic> obj, List<String> keys) {
    for (final key in keys) {
      final v = obj[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static String? _normalizePathOrUrl(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();
    if (v.isEmpty) return null;

    final uri = Uri.tryParse(v);
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      final path = uri.path.isEmpty ? '/' : uri.path;
      return path.startsWith('/') ? path : '/$path';
    }

    return v.startsWith('/') ? v : '/$v';
  }

  static String? _validateAndNormalizeUrlField(String? raw, String fieldName) {
    if (raw == null) return null;
    final v = raw.trim();
    if (v.isEmpty) return null;

    final uri = Uri.tryParse(v);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw FormatException('Invalid $fieldName: must be a valid URL (e.g. "http://192.168.4.1:5000/api/status").');
    }

    final path = uri.path.isEmpty ? '/' : uri.path;
    return path.startsWith('/') ? path : '/$path';
  }

  static String? _normalizePathOnly(String? raw) => _normalizePathOrUrl(raw);

  static String? _normalizeTemplate(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    final normalized = uri != null && uri.hasScheme && uri.hasAuthority
        ? (uri.path.isEmpty ? '/' : uri.path)
        : trimmed;
    final path = normalized.startsWith('/') ? normalized : '/$normalized';

    if (path.contains('<id>')) return path.replaceAll('<id>', '{id}');
    if (path.contains(':id')) return path.replaceAll(':id', '{id}');
    return path;
  }

  factory PiQrEndpoints.fromJson(Map<String, dynamic> obj) {
    final endpointsObj = (obj['endpoints'] is Map)
        ? (obj['endpoints'] as Map).cast<String, dynamic>()
        : (obj['api'] is Map)
            ? (obj['api'] as Map).cast<String, dynamic>()
            : obj;

    final statusPath = _validateAndNormalizeUrlField(
          _readString(endpointsObj, const ['statusPath', 'status_path', 'status', 'statusUrl', 'status_url']),
          'status URL',
        ) ??
        '/api/status';

    final dbDownloadPath = _normalizePathOrUrl(
      _readString(endpointsObj, const ['dbDownloadPath', 'db_download_path', 'db_download', 'db', 'dbDownloadUrl', 'db_download_url']),
    ) ??
    '/api/db/download';

    final scanBundlePathTemplate = _normalizeTemplate(
      _readString(endpointsObj, const ['scanBundlePathTemplate', 'scan_bundle_path_template', 'scan_bundle_template', 'scan_bundle', 'scanBundleUrl', 'scan_bundle_url']),
    ) ??
    '/api/scan/{id}/bundle';

    final scansAllPath = _normalizePathOnly(
          _readString(endpointsObj, const ['scansAllPath', 'scans_all_path', 'scan_all_path']),
        ) ??
        '/api/scan/all';

    final scansSincePathTemplate = _normalizeTemplate(
          _readString(endpointsObj, const ['scansSincePathTemplate', 'scans_since_path_template', 'scan_since_template']),
        ) ??
        '/api/scan/since/{timestamp}';

    final scanByIdPathTemplate = _normalizeTemplate(
          _readString(endpointsObj, const ['scanByIdPathTemplate', 'scan_by_id_path_template', 'scan_path_template']),
        ) ??
        '/api/scan/{id}';

    final imagePathTemplate = _normalizeTemplate(
          _readString(endpointsObj, const ['imagePathTemplate', 'image_path_template', 'image_template']),
        ) ??
        '/api/image/{filename}';

    return PiQrEndpoints(
      statusPath: statusPath,
      dbDownloadPath: dbDownloadPath,
      scanBundlePathTemplate: scanBundlePathTemplate,
      scansAllPath: scansAllPath,
      scansSincePathTemplate: scansSincePathTemplate,
      scanByIdPathTemplate: scanByIdPathTemplate,
      imagePathTemplate: imagePathTemplate,
    );
  }

  String resolveBundlePath(String id) {
    final template = scanBundlePathTemplate;
    if (template == null || template.isEmpty) {
      throw const FormatException('QR payload is missing scan bundle endpoint template.');
    }
    if (!template.contains('{id}')) {
      return template;
    }
    return template.replaceAll('{id}', id);
  }

  String resolveScansSincePath(String timestamp) {
    final template = scansSincePathTemplate;
    return template.contains('{timestamp}') ? template.replaceAll('{timestamp}', timestamp) : template;
  }

  String resolveScanByIdPath(String id) {
    final template = scanByIdPathTemplate;
    return template.contains('{id}') ? template.replaceAll('{id}', id) : template;
  }

  String resolveImagePath(String fileName) {
    final template = imagePathTemplate;
    return template.contains('{filename}') ? template.replaceAll('{filename}', fileName) : template;
  }
}

class PiQrData {
  final String ssid;
  final String password;
  /// Base URL for the Pi API, e.g. `http://192.168.4.1:5000`.
  ///
  /// Back-compat: this was previously named `scanUrl` in earlier QR codes.
  final String scanUrl;

  /// Optional scan id (older flows use this to show a specific image after import).
  final String? scanId;
  final DateTime issuedAt;
  final String? altScanUrl;
  final PiQrEndpoints endpoints;

  PiQrData({
    required this.ssid,
    required this.password,
    required this.scanUrl,
    this.scanId,
    required this.issuedAt,
    this.altScanUrl,
    this.endpoints = const PiQrEndpoints(),
  });

  String get baseUrl => scanUrl;

  static String? _findFirstString(Map<String, dynamic> obj, List<String> keys) {
    for (final key in keys) {
      final value = obj[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String? _deriveBaseUrlFromRawUrl(String? raw) {
    if (raw == null) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  static String? _findFirstUrlValue(Map<String, dynamic> obj) {
    const keys = [
      'base_url',
      'baseUrl',
      'scan_url',
      'scanUrl',
      'status_url',
      'statusUrl',
      'db_download_url',
      'dbDownloadUrl',
      'scan_bundle_url',
      'scanBundleUrl',
    ];

    final raw = _findFirstString(obj, keys);
    if (raw != null) return raw;

    if (obj['endpoints'] is Map) {
      return _findFirstUrlValue((obj['endpoints'] as Map).cast<String, dynamic>());
    }
    if (obj['api'] is Map) {
      return _findFirstUrlValue((obj['api'] as Map).cast<String, dynamic>());
    }
    return null;
  }

  factory PiQrData.fromJson(Map<String, dynamic> obj) {
    final endpoints = PiQrEndpoints.fromJson(obj);

    final rawUrl = (obj['base_url'] ?? obj['baseUrl'] ?? obj['scan_url'] ?? obj['scanUrl'])?.toString() ?? '';
    final endpointUrl = _findFirstUrlValue(obj);
    String url = rawUrl.trim();
    if (url.isEmpty && endpointUrl != null) {
      final derived = _deriveBaseUrlFromRawUrl(endpointUrl);
      if (derived != null) {
        url = derived;
      }
    }

    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        throw const FormatException('baseUrl must include a scheme (e.g. "http://192.168.4.1:5000").');
      }
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        throw const FormatException('baseUrl must be http or https.');
      }
    }

    final ssid = obj['ssid']?.toString().trim() ?? '';
    final password = (obj['pwd']?.toString() ?? obj['password']?.toString() ?? '').trim();
    if (ssid.isEmpty) throw const FormatException('QR payload missing required field: ssid');
    if (password.isEmpty) throw const FormatException('QR payload missing required field: password');
    // baseUrl is strongly recommended, but if omitted we will fall back to the default hotspot IP.

    return PiQrData(
      ssid: ssid,
      password: password,
      scanUrl: url,
      scanId: (obj['scan_id'] ?? obj['scanId'])?.toString().trim().isEmpty == true
          ? null
          : (obj['scan_id'] ?? obj['scanId'])?.toString().trim(),
      issuedAt: DateTime.tryParse(obj['issued_at']?.toString() ?? obj['issuedAt']?.toString() ?? '') ?? DateTime.now().toUtc(),
      altScanUrl: obj['alt_scan_url']?.toString() ?? obj['altScanUrl']?.toString(),
      endpoints: endpoints,
    );
  }

  factory PiQrData.fromRaw(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('QR payload must be a JSON object.');
      }
      return PiQrData.fromJson(decoded);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid QR payload. Expected JSON with ssid/password/baseUrl and endpoints.');
    }
  }
}