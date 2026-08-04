import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../notifications/models/notification_item.dart';
import '../../notifications/providers/notification_provider.dart';
import '../models/teacher_stats.dart';

/// Estado consolidado del home del maestro: stats calculadas desde las
/// notificaciones almacenadas en Hive, la lista completa de notificaciones
/// (más recientes primero) y el payload JSON para el QR de vinculación del
/// maestro.
class TeacherState {
  final TeacherStats stats;
  final List<NotificationItem> notifications;
  final String qrData;

  const TeacherState({
    this.stats = const TeacherStats(),
    this.notifications = const [],
    this.qrData = '',
  });

  TeacherState copyWith({
    TeacherStats? stats,
    List<NotificationItem>? notifications,
    String? qrData,
  }) {
    return TeacherState(
      stats: stats ?? this.stats,
      notifications: notifications ?? this.notifications,
      qrData: qrData ?? this.qrData,
    );
  }
}

final teacherProvider = Provider<TeacherState>((ref) {
  final user = ref.watch(authProvider).user;
  final notifications = [...ref.watch(notificationProvider)]
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  final qrData = user != null
      ? jsonEncode({'type': 'teacher', 'id': user.id, 'name': user.name})
      : '';

  return TeacherState(
    stats: _calculateStats(notifications),
    notifications: notifications,
    qrData: qrData,
  );
});

/// Lunes de la semana (lunes–domingo) que contiene [date]. Lo usan tanto las
/// stats como el agrupado por semana del home del maestro.
DateTime teacherWeekStart(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

TeacherStats _calculateStats(List<NotificationItem> notifications) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = teacherWeekStart(now);
  final monthStart = DateTime(now.year, now.month);

  var todayCount = 0;
  var weekCount = 0;
  var monthCount = 0;

  for (final notification in notifications) {
    final nDate = DateTime(
      notification.timestamp.year,
      notification.timestamp.month,
      notification.timestamp.day,
    );
    if (nDate.isAtSameMomentAs(today)) {
      todayCount++;
    }
    if (!nDate.isBefore(weekStart)) {
      weekCount++;
    }
    if (!nDate.isBefore(monthStart)) {
      monthCount++;
    }
  }

  return TeacherStats(
    todayCount: todayCount,
    weekCount: weekCount,
    monthCount: monthCount,
    totalCount: notifications.length,
  );
}
