import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../notifications/models/notification_item.dart';
import '../../notifications/providers/notification_provider.dart';
import '../models/teacher_stats.dart';

/// Estado consolidado del home del maestro: stats calculadas desde las
/// notificaciones almacenadas en Hive, notificaciones de hoy y el payload
/// JSON para el QR de vinculación del maestro.
class TeacherState {
  final TeacherStats stats;
  final List<NotificationItem> todayNotifications;
  final String qrData;

  const TeacherState({
    this.stats = const TeacherStats(),
    this.todayNotifications = const [],
    this.qrData = '',
  });

  TeacherState copyWith({
    TeacherStats? stats,
    List<NotificationItem>? todayNotifications,
    String? qrData,
  }) {
    return TeacherState(
      stats: stats ?? this.stats,
      todayNotifications: todayNotifications ?? this.todayNotifications,
      qrData: qrData ?? this.qrData,
    );
  }
}

final teacherProvider = Provider<TeacherState>((ref) {
  final user = ref.watch(authProvider).user;
  final notifications = ref.watch(notificationProvider);

  final qrData = user != null
      ? jsonEncode({
          'type': 'teacher',
          'id': user.id,
          'name': user.name,
        })
      : '';

  return TeacherState(
    stats: _calculateStats(notifications),
    todayNotifications: _todayNotifications(notifications),
    qrData: qrData,
  );
});

TeacherStats _calculateStats(List<NotificationItem> notifications) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = today.subtract(const Duration(days: 7));

  var todayCount = 0;
  var weekCount = 0;

  for (final notification in notifications) {
    final nDate = DateTime(
      notification.timestamp.year,
      notification.timestamp.month,
      notification.timestamp.day,
    );
    if (nDate.isAtSameMomentAs(today)) {
      todayCount++;
    }
    if (notification.timestamp.isAfter(weekAgo)) {
      weekCount++;
    }
  }

  return TeacherStats(
    todayCount: todayCount,
    weekCount: weekCount,
    totalCount: notifications.length,
  );
}

List<NotificationItem> _todayNotifications(List<NotificationItem> notifications) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return notifications.where((notification) {
    final nDate = DateTime(
      notification.timestamp.year,
      notification.timestamp.month,
      notification.timestamp.day,
    );
    return nDate.isAtSameMomentAs(today);
  }).toList();
}
