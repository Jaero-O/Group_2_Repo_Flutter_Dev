import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/notification_item.dart';

class NotificationsPage extends StatelessWidget {
  final List<NotificationItem> notifications;

  const NotificationsPage({super.key, required this.notifications});

  ({Color bgColor, Color iconColor, IconData icon}) _styleFor(
    NotificationType type,
  ) {
    switch (type) {
      case NotificationType.alert:
        return (
          bgColor: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFC62828),
          icon: Icons.warning_amber_rounded,
        );
      case NotificationType.warning:
        return (
          bgColor: const Color(0xFFFFF8E1),
          iconColor: const Color(0xFFF9A825),
          icon: Icons.info_outline,
        );
      case NotificationType.info:
        return (
          bgColor: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF2E7D32),
          icon: Icons.notifications,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'No alerts - your crop is healthy!',
                style: GoogleFonts.inter(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final style = _styleFor(item.type);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: style.bgColor,
                        child: Icon(style.icon, color: style.iconColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: GoogleFonts.inter(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.timeAgo,
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
