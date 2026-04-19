enum NotificationType { alert, warning, info }

class NotificationItem {
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;

  const NotificationItem({
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
}
