import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/notification_item.dart';
import '../model/risk_assessment.dart';
import 'notification_service.dart';
import 'local_db.dart';
import 'risk_calculator.dart';

class DeviceNotificationService {
  DeviceNotificationService._();
  static final DeviceNotificationService instance = DeviceNotificationService._();

  static const String _lastRiskAlertIsoKey = 'notif_last_risk_alert_iso';
  static const String _lastWeeklyDigestIsoKey = 'notif_last_weekly_digest_iso';

  static const int _riskAlertId = 9001;
  static const int _syncAlertId = 9002;
  static const int _dailyReminderId = 9003;
  static const int _weeklyReminderId = 9004;

  static const AndroidNotificationChannel _riskChannel =
      AndroidNotificationChannel(
        'risk_alerts',
        'Risk Alerts',
        description: 'High-risk disease and forecast alerts',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _syncChannel =
      AndroidNotificationChannel(
        'sync_alerts',
        'Sync Alerts',
        description: 'Import and synchronization updates',
        importance: Importance.defaultImportance,
      );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_initialized) return;
    if (_initFuture != null) {
      await _initFuture;
      return;
    }

    _initFuture = _initializeInternal();
    await _initFuture;
  }

  Future<void> _initializeInternal() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      const ios = DarwinInitializationSettings();
      const settings = InitializationSettings(android: android, iOS: ios);

      await _plugin.initialize(settings);

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
      await androidPlugin?.createNotificationChannel(_riskChannel);
      await androidPlugin?.createNotificationChannel(_syncChannel);
      await androidPlugin?.requestNotificationsPermission();

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _ensureReminderSchedules();
      _initialized = true;
    } catch (_) {
      // Keep app startup responsive even when notification setup fails.
      _initialized = true;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _ensureReminderSchedules() async {
    const dailyDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'risk_alerts',
        'Risk Alerts',
        channelDescription: 'High-risk disease and forecast alerts',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    const weeklyDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'risk_alerts',
        'Risk Alerts',
        channelDescription: 'High-risk disease and forecast alerts',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _schedulePeriodicReminder(
      id: _dailyReminderId,
      title: 'Mangofy Daily Risk Check',
      body: 'Open Mangofy to review today\'s anthracnose risk and recommendations.',
      interval: RepeatInterval.daily,
      details: dailyDetails,
    );

    await _schedulePeriodicReminder(
      id: _weeklyReminderId,
      title: 'Mangofy Weekly Forecast',
      body: 'Review this week\'s disease trend and action priorities.',
      interval: RepeatInterval.weekly,
      details: weeklyDetails,
    );
  }

  Future<void> _schedulePeriodicReminder({
    required int id,
    required String title,
    required String body,
    required RepeatInterval interval,
    required NotificationDetails details,
  }) async {
    try {
      await _plugin.periodicallyShow(
        id,
        title,
        body,
        interval,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Fallback for devices/OS versions where exact alarms are restricted.
      try {
        await _plugin.periodicallyShow(
          id,
          title,
          body,
          interval,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {
        // Ignore scheduling failures; manual alerts can still work.
      }
    }
  }

  Future<void> notifySyncSummary({
    required int importedScans,
    required int failures,
  }) async {
    if (importedScans == 0 && failures == 0) return;

    await init();

    final body = failures > 0
        ? 'Imported $importedScans scan(s) with $failures issue(s). Open app for details.'
        : 'Imported $importedScans new scan(s) successfully.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sync_alerts',
        'Sync Alerts',
        channelDescription: 'Import and synchronization updates',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(_syncAlertId, 'Mangofy Sync Update', body, details);
  }

  Future<void> notifyRiskIfHigh({String sourceLabel = 'forecast'}) async {
    await init();

    final stageSummary = await LocalDb.instance.getAnthracnoseStageSummary();
    final trend = await LocalDb.instance.getDiseaseWeeklyTrendSeries(
      diseaseKeyword: 'anthracnose',
    );
    final summary = await LocalDb.instance.getScanSummary();
    final weather = await LocalDb.instance.getCachedWeather();

    final assessment = RiskCalculator.computeRisk(
      stageSummary: stageSummary,
      weeklyTrend: trend,
      weather: weather,
    );

    if (assessment.riskLevel != RiskLevel.high &&
        assessment.riskLevel != RiskLevel.critical) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastRaw = prefs.getString(_lastRiskAlertIsoKey);
    final lastAlertAt =
        lastRaw == null || lastRaw.isEmpty ? null : DateTime.tryParse(lastRaw);
    final now = DateTime.now().toUtc();
    if (lastAlertAt != null && now.difference(lastAlertAt).inHours < 12) {
      return;
    }

    final levelText =
        assessment.riskLevel == RiskLevel.critical ? 'CRITICAL' : 'HIGH';
    final infectionPct =
        (assessment.infectionProbability * 100).toStringAsFixed(1);
    final yieldLossPct = (assessment.estimatedYieldLoss * 100).toStringAsFixed(
      1,
    );

    final generatedItems = NotificationService.generate(
      anthracnoseCount: stageSummary['total'] ?? 0,
      stageBreakdown: stageSummary,
      weeklyTrend: trend,
      summary: summary,
    );

    NotificationItem? alignedItem;
    for (final item in generatedItems) {
      if (item.type == NotificationType.alert ||
          item.type == NotificationType.warning) {
        alignedItem = item;
        break;
      }
    }

    final fallbackBody = '$levelText anthracnose risk from $sourceLabel. '
        'Infection probability $infectionPct%. '
        'Estimated yield loss $yieldLossPct%.';

    final title = alignedItem?.title ?? 'Mangofy Risk Alert';
    final body = alignedItem?.body ?? fallbackBody;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'risk_alerts',
        'Risk Alerts',
        channelDescription: 'High-risk disease and forecast alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(_riskAlertId, title, body, details);
    await prefs.setString(_lastRiskAlertIsoKey, now.toIso8601String());
  }

  Future<void> maybeNotifyWeeklyDigest() async {
    await init();

    final now = DateTime.now().toUtc();
    if (now.weekday != DateTime.sunday) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastRaw = prefs.getString(_lastWeeklyDigestIsoKey);
    final lastDigestAt =
        lastRaw == null || lastRaw.isEmpty ? null : DateTime.tryParse(lastRaw);
    if (lastDigestAt != null && now.difference(lastDigestAt).inDays < 6) {
      return;
    }

    final summary = await LocalDb.instance.getScanSummary();
    final total = summary.totalScans;
    final early = summary.earlyStageCount;
    final advanced = summary.advancedStageCount;

    final body = 'Weekly snapshot: $total total scans, '
        '$early early-stage and $advanced advanced anthracnose detections.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'risk_alerts',
        'Risk Alerts',
        channelDescription: 'High-risk disease and forecast alerts',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(_weeklyReminderId, 'Mangofy Weekly Digest', body, details);
    await prefs.setString(_lastWeeklyDigestIsoKey, now.toIso8601String());
  }
}
