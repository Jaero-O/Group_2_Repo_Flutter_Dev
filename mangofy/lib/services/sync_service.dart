import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/pi_qr_data.dart';
import '../model/scan_item.dart';
import 'database_service.dart';
import 'hotspot_service.dart';
import 'local_db.dart';
import 'pi_api.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final ValueNotifier<DateTime?> lastSyncNotifier = ValueNotifier(null);

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
    final baseUrl = data.scanUrl.isNotEmpty ? data.scanUrl : PiApi.hotspotBaseUrl;
    final altUrl = data.altScanUrl?.isNotEmpty == true ? data.altScanUrl : null;

    bool hotspotConnected = false;
    bool piAvailable = false;
    late String accessUrl;

    try {
      hotspotConnected = await HotspotService.instance.connectToPi(data);
      if (hotspotConnected) {
        piAvailable = await HotspotService.instance.verifyPi(baseUrl);
        if (piAvailable) {
          accessUrl = baseUrl;
        } else if (altUrl != null) {
          piAvailable = await HotspotService.instance.verifyPi(altUrl);
          if (piAvailable) {
            accessUrl = altUrl;
          }
        } else {
          piAvailable = await HotspotService.instance.verifyPi(PiApi.hotspotBaseUrl);
          if (piAvailable) {
            accessUrl = PiApi.hotspotBaseUrl;
          }
        }
      }
    } catch (_) {
      hotspotConnected = false;
      piAvailable = false;
    }

    if (!piAvailable) {
      // The Pi should act as the hotspot; do not fall back to a LAN IP here.
      throw Exception('Unable to reach Pi hotspot. Please connect to the Pi network via QR scan.');
    }

    List<ScanItem> scans;
    final lastSyncAt = await _getLastSyncAt();
    if (lastSyncAt != null) {
      scans = await PiApi.instance.getScansSince(accessUrl, lastSyncAt.toIso8601String());
    } else {
      scans = await PiApi.instance.getScansAll(accessUrl);
    }

    await _processScans(scans, baseUrl: accessUrl);

    final now = DateTime.now().toUtc();
    await _setLastSyncAt(now);
    lastSyncNotifier.value = now;
    return true;
  }

  Future<void> _processScans(List<ScanItem> scans, {String? baseUrl}) async {
    for (final remote in scans) {
      final local = await LocalDb.instance.getScanById(remote.id);
      if (local == null) {
        await LocalDb.instance.upsertScan(remote);
        continue;
      }

      final isRemoteNewer = remote.updatedAt.isNotEmpty && local.updatedAt.isNotEmpty
          ? DateTime.tryParse(remote.updatedAt)?.isAfter(DateTime.tryParse(local.updatedAt) ?? DateTime(0)) ?? false
          : false;

      final isChecksumDiff = remote.checksum != local.checksum;
      if (isRemoteNewer || isChecksumDiff) {
        await LocalDb.instance.upsertScan(remote);
      }
    }

    for (final remote in scans) {
      if (remote.imageUrl.isNotEmpty) {
        try {
          final localPath = await PiApi.instance.downloadImage(remote, baseUrl ?? remote.imageUrl);
          final updated = ScanItem(
            id: remote.id,
            title: remote.title,
            description: remote.description,
            timestamp: remote.timestamp,
            imagePath: localPath,
            imageUrl: remote.imageUrl,
            checksum: remote.checksum,
            source: remote.source,
            updatedAt: remote.updatedAt,
          );
          await LocalDb.instance.upsertScan(updated);

          final photoName = remote.title.isNotEmpty ? remote.title : 'Scan ${remote.id}';
          final photoTimestamp = remote.timestamp.isNotEmpty ? remote.timestamp : DateTime.now().toIso8601String();

          final exists = await DatabaseService.instance.photoExists(photoName, photoTimestamp);
          if (!exists) {
            final bytes = await File(localPath).readAsBytes();
            final photoData = base64Encode(bytes);
            await DatabaseService.instance.insertPhoto(
              name: photoName,
              data: photoData,
              timestamp: photoTimestamp,
            );
          }
        } catch (_) {
          // Non-fatal: could not download image or save gallery photo. Keep existing entry.
        }
      }
    }
  }
}
