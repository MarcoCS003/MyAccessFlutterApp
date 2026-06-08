import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final String type; // 'access_in', 'access_out'
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.isRead,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [
    const NotificationItem(
      id: '1',
      title: 'Ingreso Escolar Registrado',
      body: 'Mateo Pérez registró su entrada por Torniquete Principal.',
      time: '07:30 AM',
      type: 'access_in',
      isRead: false,
    ),
    const NotificationItem(
      id: '2',
      title: 'Salida Escolar Registrada',
      body: 'Sofía Pérez registró su salida autorizada por Puerta Principal.',
      time: '02:05 PM',
      type: 'access_out',
      isRead: true,
    ),
  ];

  void _markAllRead() {
    setState(() {
      _notifications = _notifications
          .map((n) => NotificationItem(
                id: n.id,
                title: n.title,
                body: n.body,
                time: n.time,
                type: n.type,
                isRead: true,
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayItems =
        _notifications.where((n) => n.type == 'access_in').toList();
    final yesterdayItems =
        _notifications.where((n) => n.type == 'access_out').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              'Marcar todo leído',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.accentLightColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.bgLightColor,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (todayItems.isNotEmpty) ...[
            _buildDateHeader('HOY'),
            ...todayItems.map((item) => _buildNotificationCard(item)),
          ],
          if (yesterdayItems.isNotEmpty) ...[
            _buildDateHeader('AYER'),
            ...yesterdayItems.map((item) => _buildNotificationCard(item)),
          ],
        ],
      ),
    );
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final bool isEntry = item.type == 'access_in';
    final Color iconColor =
        isEntry ? AppTheme.successColor : AppTheme.errorColor;
    final IconData iconData =
        isEntry ? Icons.login_rounded : Icons.logout_rounded;

    // Use ClipRRect + Stack to achieve rounded corners + left accent bar
    // without mixing non-uniform Border with borderRadius (which crashes).
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Main card
            Container(
              decoration: BoxDecoration(
                color: item.isRead ? AppTheme.bgLightColor : Colors.white,
                border: Border.all(color: AppTheme.borderLightColor, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left accent bar for unread
                  if (!item.isRead)
                    Container(width: 4, color: AppTheme.primaryColor),

                  // Content area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon circle
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                iconColor.withValues(alpha: 0.12),
                            child: Icon(iconData, color: iconColor, size: 18),
                          ),
                          const SizedBox(width: 12),

                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: item.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                    ),
                                    if (!item.isRead)
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 8, top: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.textSecondaryColor,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.time,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.textSecondaryColor
                                        .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
