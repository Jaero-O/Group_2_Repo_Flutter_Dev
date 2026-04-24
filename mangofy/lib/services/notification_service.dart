import '../model/notification_item.dart';
import '../model/scan_summary_model.dart';

class NotificationService {
  const NotificationService._();

  static List<NotificationItem> generate({
    required int anthracnoseCount,
    required Map<String, int> stageBreakdown,
    required List<Map<String, dynamic>> weeklyTrend,
    required ScanSummary summary,
  }) {
    final now = DateTime.now();
    final int advanced = stageBreakdown['advanced'] ?? 0;
    final int early = stageBreakdown['early'] ?? 0;
    final int totalFromBreakdown = stageBreakdown['total'] ?? 0;
    final int total = totalFromBreakdown > 0 ? totalFromBreakdown : anthracnoseCount;
    final int latestWeek = _trendCountAt(weeklyTrend, weeklyTrend.length - 1);
    final int previousWeek = _trendCountAt(weeklyTrend, weeklyTrend.length - 2);
    final int twoWeeksAgo = _trendCountAt(weeklyTrend, weeklyTrend.length - 3);

    final bool hasAtLeastTwoWeeks = weeklyTrend.length >= 2;
    final bool hasAtLeastThreeWeeks = weeklyTrend.length >= 3;
    final int weekDelta = latestWeek - previousWeek;
    final bool isRising = hasAtLeastTwoWeeks && weekDelta > 0;
    final bool isCooling =
        hasAtLeastThreeWeeks && latestWeek < previousWeek && previousWeek <= twoWeeksAgo;
    final bool sustainedRise =
        hasAtLeastThreeWeeks && latestWeek > previousWeek && previousWeek >= twoWeeksAgo;

    final List<NotificationItem> items = <NotificationItem>[];

    if (summary.totalScans <= 0) {
      return <NotificationItem>[
        NotificationItem(
          title: 'No scan data yet',
          body:
              'Capture your first orchard scans to receive disease risk alerts and action recommendations.',
          type: NotificationType.info,
          timestamp: now.subtract(const Duration(minutes: 5)),
        ),
      ];
    }

    if (total <= 0) {
      return <NotificationItem>[
        NotificationItem(
          title: 'No anthracnose detected',
          body:
              'Recent scans show no anthracnose detections. Continue weekly monitoring and orchard sanitation to keep risk low.',
          type: NotificationType.info,
          timestamp: now.subtract(const Duration(minutes: 5)),
        ),
      ];
    }

    final double advancedRatio = total <= 0 ? 0 : advanced / total;
    final bool criticalAdvanced = advanced > 0 && (advancedRatio >= 0.4 || sustainedRise);

    if (criticalAdvanced) {
      items.add(
        NotificationItem(
          title: 'Critical: Advanced anthracnose spreading',
          body:
              '$advanced advanced-level detections found and weekly anthracnose cases are rising. Prioritize fungicide spray and isolate heavily affected fruits.',
          type: NotificationType.alert,
          timestamp: now.subtract(const Duration(minutes: 15)),
        ),
      );
    } else if (advanced > 0) {
      items.add(
        NotificationItem(
          title: 'Advanced anthracnose detected',
          body:
              '$advanced advanced-level detections are present. Start treatment this week and remove severely infected plant material.',
          type: NotificationType.alert,
          timestamp: now.subtract(const Duration(minutes: 30)),
        ),
      );
    }

    if (early > 0 && isRising) {
      items.add(
        NotificationItem(
          title: 'Early-stage anthracnose increasing',
          body:
              '$early early-stage detections recorded. Schedule preventive spraying within 3 days to avoid progression to advanced cases.',
          type: NotificationType.warning,
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
      );
    } else if (early > 0) {
      items.add(
        NotificationItem(
          title: 'Early-stage anthracnose present',
          body:
              '$early early-stage detections found. Monitor canopy humidity and inspect fruit clusters daily.',
          type: NotificationType.warning,
          timestamp: now.subtract(const Duration(hours: 4)),
        ),
      );
    }

    final affectedRatio = summary.totalScans <= 0
        ? 0.0
        : (total / summary.totalScans) * 100;

    if (isCooling) {
      items.add(
        NotificationItem(
          title: 'Disease pressure is improving',
          body:
              'Anthracnose weekly cases are trending down. Keep your current sanitation and spray schedule to maintain this progress.',
          type: NotificationType.info,
          timestamp: now.subtract(const Duration(hours: 8)),
        ),
      );
    } else {
      final String trendText;
      if (isRising) {
        trendText = 'Weekly cases are increasing.';
      } else if (hasAtLeastTwoWeeks && weekDelta == 0) {
        trendText = 'Weekly cases are stable.';
      } else {
        trendText = 'Keep tracking weekly scans for trend confirmation.';
      }

      items.add(
        NotificationItem(
          title: 'Anthracnose watch update',
          body:
              '$total anthracnose-related detections (${affectedRatio.toStringAsFixed(1)}% of recorded scans). $trendText Continue weekly monitoring and orchard sanitation.',
          type: NotificationType.info,
          timestamp: now.subtract(const Duration(hours: 12)),
        ),
      );
    }

    final sorted = List<NotificationItem>.from(items)
      ..sort((a, b) {
        final typeCompare = _typePriority(a.type).compareTo(_typePriority(b.type));
        if (typeCompare != 0) return typeCompare;
        return b.timestamp.compareTo(a.timestamp);
      });

    return sorted;
  }

  static int _trendCountAt(List<Map<String, dynamic>> trend, int index) {
    if (index < 0 || index >= trend.length) return 0;
    final value = trend[index]['count'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _typePriority(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return 0;
      case NotificationType.warning:
        return 1;
      case NotificationType.info:
        return 2;
    }
  }
}
