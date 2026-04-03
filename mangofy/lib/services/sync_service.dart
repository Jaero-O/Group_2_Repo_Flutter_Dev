import 'package:shared_preferences/shared_preferences.dart';
import '../model/scan_item.dart';
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
    final remoteUrl = await _getLastSyncAt();
    final scans = <ScanItem>[];

    try {
      if (remoteUrl != null) {
        scans.addAll(await PiApi.instance.getScansSince(remoteUrl.toIso8601String()));
      } else {
        scans.addAll(await PiApi.instance.getScansAll());
      }
    } catch (_) {
      scans.addAll(await PiApi.instance.getScansAll());
    }

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

    final now = DateTime.now().toUtc();
    await _setLastSyncAt(now);
    lastSyncNotifier.value = now;
  }
}
