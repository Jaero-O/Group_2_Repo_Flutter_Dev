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
    if (anthracnoseCount <= 0 || (stageBreakdown['total'] ?? 0) <= 0) {
      return const <NotificationItem>[];
    }

    final now = DateTime.now();
    final int advanced = stageBreakdown['advanced'] ?? 0;
    final int early = stageBreakdown['early'] ?? 0;
    final int total = stageBreakdown['total'] ?? 0;
    final int latestWeek = _trendCountAt(weeklyTrend, weeklyTrend.length - 1);
    final int previousWeek = _trendCountAt(weeklyTrend, weeklyTrend.length - 2);
    final int twoWeeksAgo = _trendCountAt(weeklyTrend, weeklyTrend.length - 3);

    final bool isRising = latestWeek > previousWeek;
    final bool isCooling =
        latestWeek < previousWeek && previousWeek <= twoWeeksAgo;

    final List<NotificationItem> items = <NotificationItem>[];

    if (advanced > 0 && isRising) {
      items.add(
        NotificationItem(
          title: 'Critical: Advanced anthracnose spreading',
          body:
              '$advanced advanced-level detections found and weekly anthracnose cases are rising. Prioritize fungicide spray and isolate heavily affected fruits.',
          type: NotificationType.alert,
          timestamp: now.subtract(const Duration(minutes: 20)),
        ),
      );
    } else if (advanced > 0) {
      items.add(
        NotificationItem(
          title: 'Advanced anthracnose detected',
          body:
              '$advanced advanced-level detections are present. Start treatment this week and remove severely infected plant material.',
          type: NotificationType.alert,
          timestamp: now.subtract(const Duration(hours: 2)),
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
          timestamp: now.subtract(const Duration(hours: 5)),
        ),
      );
    } else if (early > 0) {
      items.add(
        NotificationItem(
          title: 'Early-stage anthracnose present',
          body:
              '$early early-stage detections found. Monitor canopy humidity and inspect fruit clusters daily.',
          type: NotificationType.warning,
          timestamp: now.subtract(const Duration(hours: 8)),
        ),
      );
    }

    if (isCooling) {
      items.add(
        NotificationItem(
          title: 'Disease pressure is improving',
          body:
              'Anthracnose weekly cases are trending down. Keep your current sanitation and spray schedule for stability.',
          type: NotificationType.info,
          timestamp: now.subtract(const Duration(hours: 12)),
        ),
      );
    } else {
      final affectedRatio = summary.totalScans <= 0
          ? 0.0
          : (total / summary.totalScans) * 100;
      items.add(
        NotificationItem(
          title: 'Anthracnose watch update',
          body:
              '$total anthracnose-related detections (${affectedRatio.toStringAsFixed(1)}% of recorded scans). Continue weekly monitoring and orchard sanitation.',
          type: NotificationType.info,
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      );
    }

    return items;
  }

  static int _trendCountAt(List<Map<String, dynamic>> trend, int index) {
    if (index < 0 || index >= trend.length) return 0;
    final value = trend[index]['count'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
