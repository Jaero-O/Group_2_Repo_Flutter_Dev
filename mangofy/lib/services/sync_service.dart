import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/pi_qr_data.dart';
import '../model/scan_item.dart';
import 'hotspot_service.dart';
import 'local_db.dart';
import 'pi_api.dart';
import 'pi_bundle_service.dart';
import 'device_notification_service.dart';
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
  final ValueNotifier<SyncDiagnostics?> diagnosticsNotifier = ValueNotifier(
    null,
  );

  static const _lastSyncKey = 'pi_sync_last_sync_at';
  static const int _imageHydrationConcurrency = 12;
  static const int _imageImportConcurrency = 12;
  static const int _bulkZipFileChunkSize = 120;

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
        scans.addAll(
          await PiApi.instance.getScansSince(
            PiApi.defaultBaseUrl,
            last.toIso8601String(),
          ),
        );
      } else {
        scans.addAll(await PiApi.instance.getScansAll(PiApi.defaultBaseUrl));
      }
    } catch (_) {
      try {
        scans.addAll(await PiApi.instance.getScansAll(PiApi.defaultBaseUrl));
      } catch (e) {
        progressNotifier.value = null;
        rethrow;
      }
    }
    try {
      await _processScans(scans);
      final now = DateTime.now().toUtc();
      await _setLastSyncAt(now);
      lastSyncNotifier.value = now;
      await DeviceNotificationService.instance.notifySyncSummary(
        importedScans: scans.length,
        failures: diagnosticsNotifier.value?.failures ?? 0,
      );
      await DeviceNotificationService.instance.notifyRiskIfHigh(
        sourceLabel: 'sync',
      );
    } catch (e) {
      progressNotifier.value = null;
      rethrow;
    }
  }

  Future<bool> syncFromPi(PiQrData data) async {
    final baseUrl = data.baseUrl.isNotEmpty
        ? data.baseUrl
        : PiApi.hotspotBaseUrl;
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
        if (ssid == null ||
            ssid.isEmpty ||
            ssid.toLowerCase().contains('unknown')) {
          debugPrint(
            'Unable to read SSID after hotspot connect; location services may be required.',
          );
        } else if (ssid != data.ssid) {
          debugPrint(
            'SSID mismatch hint: current="$ssid" expected="${data.ssid}". Proceeding to verify Pi reachability.',
          );
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
        if (altUrl != null &&
            altUrl.isNotEmpty &&
            !candidates.contains(altUrl)) {
          candidates.add(altUrl);
        }

        accessUrl =
            await HotspotService.instance.findFirstReadyPi(
              candidates,
              statusPath: endpoints.statusPath,
            ) ??
            '';
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
      throw Exception(
        'Unable to reach Pi hotspot. Please connect to the Pi network via QR scan.',
      );
    }

    progressNotifier.value = const SyncProgress(
      stage: 'Fetching',
      completedUnits: 0,
      totalUnits: 1,
      message: 'Fetching scan data…',
    );

    final diagnostics = SyncDiagnostics();
    diagnosticsNotifier.value = diagnostics;
    bool usedDbImportFallback = false;

    List<ScanItem> scans;
    bool fetchSuccess = false;

    if (endpoints.dbDownloadPath != null &&
        endpoints.dbDownloadPath!.isNotEmpty) {
      try {
        progressNotifier.value = const SyncProgress(
          stage: 'Importing',
          completedUnits: 0,
          totalUnits: 1,
          message: 'Downloading full Pi database…',
        );
        final downloadedDbPath = await PiApi.instance.downloadDatabase(
          accessUrl,
          endpoints: endpoints,
        );
        progressNotifier.value = const SyncProgress(
          stage: 'Importing',
          completedUnits: 1,
          totalUnits: 1,
          message: 'Database downloaded. Importing records…',
        );
        await LocalDb.instance.replaceDatabaseFromFile(downloadedDbPath);
        await _normalizeImportedImagePaths();
        await _hydrateImportedScanImages(accessUrl, endpoints, diagnostics);
        usedDbImportFallback = true;
        fetchSuccess = true;

        // Top-up from live API because Pi DB exports can be slightly stale.
        final latestImported = await LocalDb.instance.getLatestScanDate();
        final topUpSinceIso = latestImported == null
            ? null
            : DateTime.tryParse(
                latestImported.replaceFirst(' ', 'T'),
              )?.toUtc().toIso8601String();

        if (topUpSinceIso != null) {
          progressNotifier.value = const SyncProgress(
            stage: 'Syncing',
            completedUnits: 0,
            totalUnits: 1,
            message: 'Checking for new scans after DB import…',
          );

          final recentScans = await PiApi.instance.getScansSince(
            accessUrl,
            topUpSinceIso,
            endpoints: endpoints,
          );

          if (recentScans.isNotEmpty) {
            diagnostics.scansFetched += recentScans.length;
            await _processScans(
              recentScans,
              baseUrl: accessUrl,
              endpoints: endpoints,
            );
          }
        }
      } catch (dbErr) {
        debugPrint('DB import failed, falling back to JSON API: $dbErr');
      }
    }

    if (!fetchSuccess) {
      try {
        final lastSyncAt = await _getLastSyncAt();
        if (lastSyncAt != null) {
          scans = await PiApi.instance.getScansSince(
            accessUrl,
            lastSyncAt.toIso8601String(),
            endpoints: endpoints,
          );
        } else {
          scans = await PiApi.instance.getScansAll(
            accessUrl,
            endpoints: endpoints,
          );
        }

        diagnostics.scansFetched = scans.length;
        await _processScans(scans, baseUrl: accessUrl, endpoints: endpoints);
        fetchSuccess = true;
      } catch (_) {
        progressNotifier.value = null;
        rethrow;
      }
    }

    // Optional: download and extract scan bundle for the scanned id.
    final scanId = data.scanId;
    if (scanId != null &&
        scanId.isNotEmpty &&
        endpoints.scanBundlePathTemplate != null) {
      progressNotifier.value = const SyncProgress(
        stage: 'Bundle',
        completedUnits: 0,
        totalUnits: 1,
        message: 'Downloading scan bundle…',
      );

      try {
        final bundlePath = await PiApi.instance.downloadScanBundle(
          accessUrl,
          endpoints: endpoints,
          scanId: scanId,
        );
        final extractedDir = await PiBundleService.instance.extractZipBundle(
          zipPath: bundlePath,
          scanId: scanId,
        );

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
                treeId: existing.treeId,
                treeName: existing.treeName,
                treeLocation: existing.treeLocation,
                treeVariety: existing.treeVariety,
                diseaseId: existing.diseaseId,
                diseaseName: existing.diseaseName,
                diseaseDescription: existing.diseaseDescription,
                diseaseSymptoms: existing.diseaseSymptoms,
                diseasePrevention: existing.diseasePrevention,
                severityLevelId: existing.severityLevelId,
                severityLevelName: existing.severityLevelName,
                severityLevelDescription: existing.severityLevelDescription,
              ),
            );
          }
        }
      } catch (_) {
        // Non-fatal: scan bundle is optional.
      }
    }

    // Reconcile only when data changed. This avoids heavy no-op work.
    if (usedDbImportFallback || diagnostics.scansFetched > 0) {
      await reconcileGalleryFromScans();
    }

    // Gate lastSync update on successful fetch+processing completion
    if (fetchSuccess) {
      final now = DateTime.now().toUtc();
      await _setLastSyncAt(now);
      lastSyncNotifier.value = now;
      await DeviceNotificationService.instance.notifySyncSummary(
        importedScans: diagnostics.scansFetched,
        failures: diagnostics.failures,
      );
      await DeviceNotificationService.instance.notifyRiskIfHigh(
        sourceLabel: 'sync',
      );
    }
    progressNotifier.value = null; // Clear progress on success
    return true;
  }

  Future<void> reconcileGalleryFromScans() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(join(docsDir.path, 'photos'));
    await photosDir.create(recursive: true);

    final importable = await LocalDb.instance.getImportableScanImages();
    final photoRows = <Map<String, dynamic>>[];
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
      final confidence = (row['confidence'] as num?)?.toDouble();
      final severityValue = (row['severity_value'] as num?)?.toDouble();
      final photoId = row['photo_id'] as int?;
      final scanDir = row['scan_dir'] as String?;

      if (!await File(imagePath).exists()) continue;

      final fileName = basename(imagePath);
      final permanentPath = join(photosDir.path, fileName);
      String updatedImagePath = imagePath;
      if (imagePath != permanentPath) {
        try {
          await File(imagePath).rename(permanentPath);
          updatedImagePath = permanentPath;
        } catch (e) {
          // Keep original path if rename fails
        }
      }
      await LocalDb.instance.updateScanImagePath(scanId, updatedImagePath);

      final photoName = disease.isNotEmpty ? disease : 'Scan $scanId';
      photoRows.add({
        'name': photoName,
        'data': '',
        'path': updatedImagePath,
        'timestamp': timestamp,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'checksum': checksum,
        'source': source,
        'updated_at': updatedAt,
        'disease': disease,
        'confidence': confidence,
        'severity_value': severityValue,
        'photo_id': photoId,
        'scan_dir': scanDir,
      });
    }

    await LocalDb.instance.batchUpsertPhotos(photoRows);
  }

  Future<void> _normalizeImportedImagePaths() async {
    final docs = await getApplicationDocumentsDirectory();
    final photosDir = Directory(join(docs.path, 'photos'));
    await photosDir.create(recursive: true);
    final importable = await LocalDb.instance.getScanImageCandidates();

    await Future.wait(
      importable.map((row) async {
        final scanId = row['id'] as int;
        final imagePath = row['image_path'] as String? ?? '';
        final imageUrl = row['image_url'] as String? ?? '';
        final imageRef = imagePath.isNotEmpty ? imagePath : imageUrl;
        if (imageRef.isEmpty) return;

        final existing = File(imagePath);
        if (await existing.exists()) return;

        final fileName = _extractImageFileName(imageRef) ?? '';
        if (fileName.isEmpty) return;

        final localFileName = 'scan_${scanId}_$fileName';
        final candidate = File('${docs.path}/$localFileName');
        final legacyCandidate = File('${docs.path}/$fileName');
        final candidateInPhotos = File(join(photosDir.path, localFileName));
        final legacyCandidateInPhotos = File(join(photosDir.path, fileName));
        if (await candidateInPhotos.exists()) {
          await LocalDb.instance.updateScanImagePath(
            scanId,
            candidateInPhotos.path,
          );
        } else if (await legacyCandidateInPhotos.exists()) {
          await LocalDb.instance.updateScanImagePath(
            scanId,
            legacyCandidateInPhotos.path,
          );
        } else if (await candidate.exists()) {
          await LocalDb.instance.updateScanImagePath(scanId, candidate.path);
        } else if (await legacyCandidate.exists()) {
          await LocalDb.instance.updateScanImagePath(
            scanId,
            legacyCandidate.path,
          );
        }
      }),
    );
  }

  Future<void> _hydrateImportedScanImages(
    String baseUrl,
    PiQrEndpoints endpoints,
    SyncDiagnostics diagnostics,
  ) async {
    final docs = await getApplicationDocumentsDirectory();
    final photosDir = Directory(join(docs.path, 'photos'));
    await photosDir.create(recursive: true);

    final importable = await LocalDb.instance.getScanImageCandidates();

    final pending = <Map<String, dynamic>>[];
    final pendingCandidates = await Future.wait(
      importable.map((row) async {
        final scanId = row['id'] as int;
        final imagePath = row['image_path'] as String? ?? '';
        final imageUrl = row['image_url'] as String? ?? '';
        final imageRef = imagePath.isNotEmpty ? imagePath : imageUrl;
        if (imageRef.isEmpty) return null;

        final existing = File(imagePath);
        if (await existing.exists()) return null;

        final fileName = _extractImageFileName(imageRef) ?? '';
        if (fileName.isEmpty) return null;

        final localFileName = 'scan_${scanId}_$fileName';

        final inPhotos = File(join(photosDir.path, localFileName));
        if (await inPhotos.exists()) {
          await LocalDb.instance.updateScanImagePath(scanId, inPhotos.path);
          return null;
        }

        final inPhotosLegacy = File(join(photosDir.path, fileName));
        if (await inPhotosLegacy.exists()) {
          await LocalDb.instance.updateScanImagePath(
            scanId,
            inPhotosLegacy.path,
          );
          return null;
        }

        final inDocs = File(join(docs.path, localFileName));
        if (await inDocs.exists()) {
          await LocalDb.instance.updateScanImagePath(scanId, inDocs.path);
          return null;
        }

        final inDocsLegacy = File(join(docs.path, fileName));
        if (await inDocsLegacy.exists()) {
          await LocalDb.instance.updateScanImagePath(scanId, inDocsLegacy.path);
          return null;
        }

        return {
          'scanId': scanId,
          'remoteFileName': fileName,
          'localFileName': localFileName,
        };
      }),
    );
    pending.addAll(pendingCandidates.whereType<Map<String, dynamic>>());

    if (pending.isEmpty) return;

    final bulkHydratedPaths = await _downloadBulkImagePaths(
      baseUrl: baseUrl,
      endpoints: endpoints,
      pending: pending,
      diagnostics: diagnostics,
      bundlePrefix: 'imported_images',
    );
    if (bulkHydratedPaths.isNotEmpty) {
      await Future.wait(
        bulkHydratedPaths.entries.map(
          (entry) =>
              LocalDb.instance.updateScanImagePath(entry.key, entry.value),
        ),
      );
      pending.removeWhere(
        (item) => bulkHydratedPaths.containsKey(item['scanId'] as int),
      );
    }

    if (pending.isEmpty) return;

    progressNotifier.value = SyncProgress(
      stage: 'Hydrating',
      completedUnits: 0,
      totalUnits: pending.length,
      message: 'Downloading ${pending.length} missing imported images…',
    );

    int completed = 0;
    for (int i = 0; i < pending.length; i += _imageHydrationConcurrency) {
      final chunk = pending.sublist(
        i,
        (i + _imageHydrationConcurrency) > pending.length
            ? pending.length
            : (i + _imageHydrationConcurrency),
      );

      await Future.wait(
        chunk.map((item) async {
          final scanId = item['scanId'] as int;
          final remoteFileName = item['remoteFileName'] as String;
          final localFileName = item['localFileName'] as String;
          diagnostics.imagesAttempted++;
          try {
            final localPath = await PiApi.instance.downloadFile(
              baseUrl: baseUrl,
              path: endpoints.resolveImagePath(remoteFileName),
              fileName: localFileName,
              timeout: const Duration(seconds: 30),
            );
            diagnostics.imagesDownloaded++;
            await LocalDb.instance.updateScanImagePath(scanId, localPath);
          } catch (e) {
            diagnostics.failures++;
            diagnostics.failureMessages.add(
              'Failed to hydrate imported image for scan $scanId: $e',
            );
            debugPrint('Failed to download image for scan $scanId: $e');
          }
        }),
      );

      completed += chunk.length;
      progressNotifier.value = SyncProgress(
        stage: 'Hydrating',
        completedUnits: completed,
        totalUnits: pending.length,
        message: 'Downloaded $completed of ${pending.length} imported images…',
      );
    }
  }

  Future<void> _processScans(
    List<ScanItem> scans, {
    String? baseUrl,
    PiQrEndpoints? endpoints,
  }) async {
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
      message: 'Syncing $scanCount scans from Pi…',
    );

    // Batch upsert all scans first
    await LocalDb.instance.batchUpsertScans(scans);
    completedUnits += scanCount;
    progressNotifier.value = SyncProgress(
      stage: 'Processing',
      completedUnits: completedUnits,
      totalUnits: totalUnits,
      message: 'Synced $scanCount scans from Pi.',
    );

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(join(docsDir.path, 'photos'));
    await photosDir.create(recursive: true);

    final scansWithImages = scans.where((s) => s.imageUrl.isNotEmpty).toList();
    final pendingForBulk = <Map<String, dynamic>>[];
    for (final scan in scansWithImages) {
      final remoteFileName = _extractImageFileName(scan.imageUrl);
      if (remoteFileName == null || remoteFileName.isEmpty) continue;
      final localFileName = 'scan_${scan.id}_$remoteFileName';
      pendingForBulk.add({
        'scanId': scan.id,
        'remoteFileName': remoteFileName,
        'localFileName': localFileName,
      });
    }

    final bulkDownloadedPaths = await _downloadBulkImagePaths(
      baseUrl: baseUrl ?? PiApi.defaultBaseUrl,
      endpoints: endpoints,
      pending: pendingForBulk,
      diagnostics: diagnostics,
      bundlePrefix: 'scan_images',
    );

    if (bulkDownloadedPaths.isNotEmpty) {
      await Future.wait(
        bulkDownloadedPaths.entries.map(
          (entry) =>
              LocalDb.instance.updateScanImagePath(entry.key, entry.value),
        ),
      );
    }

    int processedImageUnits = 0;

    Future<void> processImage(ScanItem remote) async {
      diagnostics.imagesAttempted++;
      try {
        final preDownloadedPath = bulkDownloadedPaths[remote.id];
        final localPath =
            preDownloadedPath ??
            await PiApi.instance.downloadImage(
              remote,
              baseUrl ?? PiApi.defaultBaseUrl,
              endpoints: endpoints,
            );
        if (preDownloadedPath == null) {
          diagnostics.imagesDownloaded++;
        }

        final uniqueFileName = 'scan_${remote.id}_${basename(localPath)}';
        final fileName = preDownloadedPath == null
            ? uniqueFileName
            : basename(localPath);
        final permanentPath = join(photosDir.path, fileName);
        String updatedImagePath = localPath;
        if (localPath != permanentPath) {
          try {
            await File(localPath).rename(permanentPath);
            updatedImagePath = permanentPath;
          } catch (_) {
            // Keep original path if rename fails.
          }
        }
        await LocalDb.instance.updateScanImagePath(remote.id, updatedImagePath);

        final photoName = remote.title.isNotEmpty
            ? remote.title
            : 'Scan ${remote.id}';
        final photoTimestamp = remote.timestamp.isNotEmpty
            ? remote.timestamp
            : DateTime.now().toIso8601String();

        int? photoId = await LocalDb.instance.getPhotoIdByNameTimestamp(
          photoName,
          photoTimestamp,
        );
        photoId ??= await LocalDb.instance.insertPhoto(
          name: photoName,
          data: '',
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
        if (photoId > 0) {
          diagnostics.photosInserted++;
        }
      } catch (e) {
        diagnostics.failures++;
        diagnostics.failureMessages.add(
          'Failed to process image for scan ${remote.id}: $e',
        );
        debugPrint('Image processing failed for scan ${remote.id}: $e');
      } finally {
        processedImageUnits++;
        completedUnits = scanCount + processedImageUnits;
        progressNotifier.value = SyncProgress(
          stage: 'Downloading',
          completedUnits: completedUnits,
          totalUnits: totalUnits,
          message: 'Downloaded $processedImageUnits of $imageCount images…',
        );
      }
    }

    for (int i = 0; i < scansWithImages.length; i += _imageImportConcurrency) {
      final chunk = scansWithImages.sublist(
        i,
        (i + _imageImportConcurrency) > scansWithImages.length
            ? scansWithImages.length
            : (i + _imageImportConcurrency),
      );

      progressNotifier.value = SyncProgress(
        stage: 'Downloading',
        completedUnits: completedUnits,
        totalUnits: totalUnits,
        message:
            'Downloading images ${i + 1}-${i + chunk.length} of $imageCount…',
      );

      await Future.wait(chunk.map(processImage));
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

  String? _extractImageFileName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty) return last;
    }

    final fileName = basename(trimmed);
    return fileName.isEmpty ? null : fileName;
  }

  Future<Map<int, String>> _downloadBulkImagePaths({
    required String baseUrl,
    required PiQrEndpoints? endpoints,
    required List<Map<String, dynamic>> pending,
    required SyncDiagnostics diagnostics,
    required String bundlePrefix,
  }) async {
    final resolvedEndpoints = endpoints ?? const PiQrEndpoints();
    if (pending.isEmpty ||
        resolvedEndpoints.bulkImagesZipPath == null ||
        resolvedEndpoints.bulkImagesZipPath!.isEmpty) {
      return <int, String>{};
    }

    final result = <int, String>{};
    for (int i = 0; i < pending.length; i += _bulkZipFileChunkSize) {
      final chunk = pending.sublist(
        i,
        (i + _bulkZipFileChunkSize) > pending.length
            ? pending.length
            : (i + _bulkZipFileChunkSize),
      );
      final fileNames = chunk
          .map((item) => (item['remoteFileName'] as String).trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      if (fileNames.isEmpty) continue;

      try {
        diagnostics.imagesAttempted += chunk.length;
        final zipPath = await PiApi.instance.downloadBulkImagesZip(
          baseUrl,
          fileNames,
          endpoints: resolvedEndpoints,
        );
        final extractedDir = await PiBundleService.instance.extractZipBundle(
          zipPath: zipPath,
          scanId: '${bundlePrefix}_${DateTime.now().millisecondsSinceEpoch}_$i',
        );

        for (final item in chunk) {
          final scanId = item['scanId'] as int;
          final remoteFileName = item['remoteFileName'] as String;
          final localFileName = item['localFileName'] as String;
          final extractedPath = join(extractedDir, remoteFileName);
          final extractedFile = File(extractedPath);
          if (await extractedFile.exists()) {
            final localExtractedPath = join(extractedDir, localFileName);
            if (extractedPath != localExtractedPath) {
              final localExtractedFile = File(localExtractedPath);
              if (!await localExtractedFile.exists()) {
                await extractedFile.copy(localExtractedPath);
              }
              result[scanId] = localExtractedPath;
            } else {
              result[scanId] = extractedPath;
            }
            diagnostics.imagesDownloaded++;
          }
        }
      } catch (e) {
        // Fallback to per-image download when bulk endpoint is unavailable.
        debugPrint('Bulk image zip unavailable for chunk at $i: $e');
      }
    }

    return result;
  }
}
