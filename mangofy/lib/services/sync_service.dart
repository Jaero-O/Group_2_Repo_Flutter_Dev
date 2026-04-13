import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/pi_qr_data.dart';
import '../model/scan_item.dart';
import 'database_service.dart';
import 'hotspot_service.dart';
import 'local_db.dart';
import 'pi_api.dart';
import 'pi_bundle_service.dart';
import 'package:flutter/foundation.dart';

class SyncProgress {
  final String stage;
  final int completedUnits;
  final int totalUnits;
  final String message;

  double get percent => totalUnits > 0 ? completedUnits / totalUnits : 0;

  const SyncProgress({
    required this.stage,
    required this.completedUnits,
    required this.totalUnits,
    required this.message,
  });
}

class SyncDiagnostics {
  int scansFetched = 0;
  int imagesAttempted = 0;
  int imagesDownloaded = 0;
  int photosInserted = 0;
  int failures = 0;
  List<String> failureMessages = [];
}

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final ValueNotifier<DateTime?> lastSyncNotifier = ValueNotifier(null);
  final ValueNotifier<SyncProgress?> progressNotifier = ValueNotifier(null);
  final ValueNotifier<SyncDiagnostics?> diagnosticsNotifier = ValueNotifier(null);

  static const _lastSyncKey = 'pi_sync_last_sync_at';

  Future<DateTime?> _getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _setLastSyncAt(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  Future<void> sync() async {
    // Legacy direct Pi configuration using fixed local IP.
    final scans = <ScanItem>[];
    try {
      final last = await _getLastSyncAt();
      if (last != null) {
        scans.addAll(await PiApi.instance.getScansSince(PiApi.defaultBaseUrl, last.toIso8601String()));
      } else {
        scans.addAll(await PiApi.instance.getScansAll(PiApi.defaultBaseUrl));
      }
    } catch (_) {
      scans.addAll(await PiApi.instance.getScansAll(PiApi.defaultBaseUrl));
    }
    await _processScans(scans);
  }

  Future<bool> syncFromPi(PiQrData data) async {
    final baseUrl = data.baseUrl.isNotEmpty ? data.baseUrl : PiApi.hotspotBaseUrl;
    final altUrl = data.altScanUrl?.isNotEmpty == true ? data.altScanUrl : null;
    final endpoints = data.endpoints;

    bool piAvailable = false;
    late String accessUrl;

    progressNotifier.value = const SyncProgress(
      stage: 'Connecting',
      completedUnits: 0,
      totalUnits: 1,
      message: 'Connecting to hotspot…',
    );

    try {
      final connected = await HotspotService.instance.connectToPi(data);
      if (connected) {
        final ssid = await HotspotService.instance.getCurrentSsid();
        if (ssid == null || ssid.isEmpty || ssid.toLowerCase().contains('unknown')) {
          debugPrint('Unable to read SSID after hotspot connect; location services may be required.');
        } else if (ssid != data.ssid) {
          debugPrint('SSID mismatch hint: current="$ssid" expected="${data.ssid}". Proceeding to verify Pi reachability.');
        }

        progressNotifier.value = const SyncProgress(
          stage: 'Verifying',
          completedUnits: 0,
          totalUnits: 1,
          message: 'Verifying Pi connection…',
        );

        final candidates = <String>[];
        if (baseUrl.isNotEmpty) {
          candidates.add(baseUrl);
        }
        if (PiApi.hotspotBaseUrl != baseUrl) {
          candidates.add(PiApi.hotspotBaseUrl);
        }
        if (altUrl != null && altUrl.isNotEmpty && !candidates.contains(altUrl)) {
          candidates.add(altUrl);
        }

        accessUrl = await HotspotService.instance.findFirstReadyPi(candidates, statusPath: endpoints.statusPath) ?? '';
        piAvailable = accessUrl.isNotEmpty;

        if (piAvailable) {
          progressNotifier.value = const SyncProgress(
            stage: 'Connected',
            completedUnits: 1,
            totalUnits: 1,
            message: 'Connected to Pi.',
          );
        }
      }
    } catch (_) {
      piAvailable = false;
    }

    if (!piAvailable) {
      progressNotifier.value = null;
      // The Pi should act as the hotspot; do not fall back to a LAN IP here.
      throw Exception('Unable to reach Pi hotspot. Please connect to the Pi network via QR scan.');
    }

    progressNotifier.value = const SyncProgress(
      stage: 'Fetching',
      completedUnits: 0,
      totalUnits: 1,
      message: 'Fetching scan data…',
    );

    final diagnostics = SyncDiagnostics();
    diagnosticsNotifier.value = diagnostics;

    List<ScanItem> scans;
    bool fetchSuccess = false;
    try {
      final lastSyncAt = await _getLastSyncAt();
      if (lastSyncAt != null) {
        scans = await PiApi.instance.getScansSince(accessUrl, lastSyncAt.toIso8601String(), endpoints: endpoints);
        // If incremental fetch returns suspiciously empty, force full sync for Kivy parity
        if (scans.isEmpty) {
          debugPrint('Incremental sync returned no scans; falling back to full sync.');
          scans = await PiApi.instance.getScansAll(accessUrl, endpoints: endpoints);
        }
      } else {
        scans = await PiApi.instance.getScansAll(accessUrl, endpoints: endpoints);
      }

      diagnostics.scansFetched = scans.length;
      await _processScans(scans, baseUrl: accessUrl, endpoints: endpoints);
      fetchSuccess = true;
    } catch (e) {
      progressNotifier.value = null; // Clear progress on error
      // If this Pi setup prefers DB download/import over scan endpoints, fall back when provided.
      if (endpoints.dbDownloadPath != null && endpoints.dbDownloadPath!.isNotEmpty) {
        final downloadedDbPath = await PiApi.instance.downloadDatabase(accessUrl, endpoints: endpoints);
        await LocalDb.instance.replaceDatabaseFromFile(downloadedDbPath);
        await _normalizeImportedImagePaths();
        fetchSuccess = true;
      } else {
        rethrow;
      }
    }

    // Optional: download and extract scan bundle for the scanned id.
    final scanId = data.scanId;
    if (scanId != null && scanId.isNotEmpty && endpoints.scanBundlePathTemplate != null) {
      progressNotifier.value = const SyncProgress(
        stage: 'Bundle',
        completedUnits: 0,
        totalUnits: 1,
        message: 'Downloading scan bundle…',
      );

      try {
        final bundlePath = await PiApi.instance.downloadScanBundle(accessUrl, endpoints: endpoints, scanId: scanId);
        final extractedDir = await PiBundleService.instance.extractZipBundle(zipPath: bundlePath, scanId: scanId);

        final id = int.tryParse(scanId);
        if (id != null) {
          final existing = await LocalDb.instance.getScanById(id);
          if (existing != null) {
            await LocalDb.instance.upsertScan(
              ScanItem(
                id: existing.id,
                title: existing.title,
                description: existing.description,
                timestamp: existing.timestamp,
                imagePath: existing.imagePath,
                imageUrl: existing.imageUrl,
                checksum: existing.checksum,
                source: existing.source,
                updatedAt: existing.updatedAt,
                disease: existing.disease,
                confidence: existing.confidence,
                severityValue: existing.severityValue,
                photoId: existing.photoId,
                scanDir: extractedDir,
              ),
            );
          }
        }
      } catch (_) {
        // Non-fatal: scan bundle is optional.
      }
    }

    // Reconcile gallery from imported scans
    await reconcileGalleryFromScans();

    // Gate lastSync update on successful fetch+processing completion
    if (fetchSuccess) {
      final now = DateTime.now().toUtc();
      await _setLastSyncAt(now);
      lastSyncNotifier.value = now;
    }
    progressNotifier.value = null; // Clear progress on success
    return true;
  }

  Future<void> reconcileGalleryFromScans() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(join(docsDir.path, 'photos'));
    await photosDir.create(recursive: true);

    final importable = await LocalDb.instance.getImportableScanImages();
    for (final row in importable) {
      final scanId = row['id'] as int;
      final timestamp = row['scan_timestamp'] as String;
      final disease = row['disease_class'] as String;
      final imagePath = row['image_path'] as String;
      final title = row['title'] as String?;
      final description = row['description'] as String?;
      final imageUrl = row['image_url'] as String?;
      final checksum = row['checksum'] as String?;
      final source = row['source'] as String?;
      final updatedAt = row['updated_at'] as String?;
      final confidence = row['confidence'] as double?;
      final severityValue = row['severity_value'] as double?;
      final photoId = row['photo_id'] as int?;
      final scanDir = row['scan_dir'] as String?;
      
      if (!await File(imagePath).exists()) continue;

      final fileName = basename(imagePath);
      final permanentPath = join(photosDir.path, fileName);
      String updatedImagePath = imagePath;
      try {
        await File(imagePath).rename(permanentPath);
        updatedImagePath = permanentPath;
      } catch (e) {
        // Keep original path if rename fails
      }
      await LocalDb.instance.updateScanImagePath(scanId, updatedImagePath);

      final photoName = disease.isNotEmpty ? disease : 'Scan $scanId';
      final photoTimestamp = timestamp;

      int? existingPhotoId = await LocalDb.instance.getPhotoIdByNameTimestamp(photoName, photoTimestamp);
      if (existingPhotoId == null) {
        final bytes = await File(updatedImagePath).readAsBytes();
        final photoData = base64Encode(bytes);
        existingPhotoId = await LocalDb.instance.insertPhoto(
          name: photoName,
          data: photoData,
          path: updatedImagePath,
          timestamp: photoTimestamp,
          title: title,
          description: description,
          imageUrl: imageUrl,
          checksum: checksum,
          source: source,
          updatedAt: updatedAt,
          disease: disease,
          confidence: confidence,
          severityValue: severityValue,
          photoId: photoId,
          scanDir: scanDir,
        );
      }
    }
  }

  Future<void> _normalizeImportedImagePaths() async {
    final docs = await getApplicationDocumentsDirectory();
    final importable = await LocalDb.instance.getImportableScanImages();

    for (final row in importable) {
      final scanId = row['id'] as int;
      final imagePath = row['image_path'] as String? ?? '';
      if (imagePath.isEmpty) continue;

      final existing = File(imagePath);
      if (await existing.exists()) continue;

      final fileName = imagePath.split(RegExp(r'[\\/]+')).last;
      if (fileName.isEmpty) continue;

      final candidate = File('${docs.path}/$fileName');
      if (await candidate.exists()) {
        await LocalDb.instance.updateScanImagePath(scanId, candidate.path);
      }
    }
  }

  Future<void> _processScans(List<ScanItem> scans, {String? baseUrl, PiQrEndpoints? endpoints}) async {
    final diagnostics = diagnosticsNotifier.value ?? SyncDiagnostics();
    diagnostics.scansFetched = scans.length;
    final scanCount = scans.length;
    final imageCount = scans.where((s) => s.imageUrl.isNotEmpty).length;
    final totalUnits = scanCount + imageCount;
    int completedUnits = 0;

    progressNotifier.value = SyncProgress(
      stage: 'Processing',
      completedUnits: completedUnits,
      totalUnits: totalUnits,
      message: 'Processing $scanCount scans…',
    );

    // Batch upsert all scans first
    await LocalDb.instance.batchUpsertScans(scans);
    completedUnits += scanCount;
    progressNotifier.value = SyncProgress(
      stage: 'Processing',
      completedUnits: completedUnits,
      totalUnits: totalUnits,
      message: 'Processed $scanCount scans…',
    );

    // Then process images individually
    for (final remote in scans) {
      if (remote.imageUrl.isNotEmpty) {
        diagnostics.imagesAttempted++;
        try {
          progressNotifier.value = SyncProgress(
            stage: 'Downloading',
            completedUnits: completedUnits,
            totalUnits: totalUnits,
            message: 'Downloading image for scan ${remote.id}…',
          );

          final localPath = await PiApi.instance.downloadImage(
            remote,
            baseUrl ?? PiApi.defaultBaseUrl,
            endpoints: endpoints,
          );
          diagnostics.imagesDownloaded++;

          final docsDir = await getApplicationDocumentsDirectory();
          final photosDir = Directory(join(docsDir.path, 'photos'));
          await photosDir.create(recursive: true);
          final fileName = basename(localPath);
          final permanentPath = join(photosDir.path, fileName);
          String updatedImagePath = localPath;
          try {
            await File(localPath).rename(permanentPath);
            updatedImagePath = permanentPath;
          } catch (e) {
            // Keep original path if rename fails
          }

          final updated = ScanItem(
            id: remote.id,
            title: remote.title,
            description: remote.description,
            timestamp: remote.timestamp,
            imagePath: updatedImagePath,
            imageUrl: remote.imageUrl,
            checksum: remote.checksum,
            source: remote.source,
            updatedAt: remote.updatedAt,
            disease: remote.disease,
            confidence: remote.confidence,
            severityValue: remote.severityValue,
            photoId: remote.photoId,
            scanDir: remote.scanDir,
          );
          await LocalDb.instance.upsertScan(updated);

          final photoName = remote.title.isNotEmpty ? remote.title : 'Scan ${remote.id}';
          final photoTimestamp = remote.timestamp.isNotEmpty ? remote.timestamp : DateTime.now().toIso8601String();

          int? photoId = await LocalDb.instance.getPhotoIdByNameTimestamp(photoName, photoTimestamp);
          if (photoId == null) {
            final bytes = await File(updatedImagePath).readAsBytes();
            final photoData = base64Encode(bytes);
            photoId = await LocalDb.instance.insertPhoto(
              name: photoName,
              data: photoData,
              path: updatedImagePath,
              timestamp: photoTimestamp,
              title: remote.title,
              description: remote.description,
              imageUrl: remote.imageUrl,
              checksum: remote.checksum,
              source: remote.source,
              updatedAt: remote.updatedAt,
              disease: remote.disease,
              confidence: remote.confidence,
              severityValue: remote.severityValue,
              photoId: remote.photoId,
              scanDir: remote.scanDir,
            );
          }
          diagnostics.photosInserted++;

          if (photoId > 0) {
            // Photo inserted into gallery DB, no need to update scan record
          }
        } catch (e) {
          diagnostics.failures++;
          diagnostics.failureMessages.add('Failed to process image for scan ${remote.id}: $e');
          debugPrint('Image processing failed for scan ${remote.id}: $e');
        }
        completedUnits++;
        progressNotifier.value = SyncProgress(
          stage: 'Downloading',
          completedUnits: completedUnits,
          totalUnits: totalUnits,
          message: 'Downloaded ${completedUnits - scanCount} of $imageCount images…',
        );
      }
    }

    String message = 'Sync complete.';
    if (diagnostics.failures > 0) {
      message = 'Sync complete with ${diagnostics.failures} failures.';
    }
    progressNotifier.value = SyncProgress(
      stage: 'Complete',
      completedUnits: 1,
      totalUnits: 1,
      message: message,
    );
    diagnosticsNotifier.value = diagnostics;
  }
}
