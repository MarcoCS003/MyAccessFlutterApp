import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../notifications/models/notification_item.dart';
import '../../notifications/providers/notification_provider.dart';
import '../models/teacher_stats.dart';

/// Estado consolidado del home del maestro: stats calculadas desde las
/// notificaciones almacenadas en Hive y la lista completa de notificaciones
/// (más recientes primero).
///
/// El QR del maestro vive en `teacherQrProvider` y se construye a partir de
/// `authProvider.user.teacher?.qrCode` (cargado por `GET /api/user` vía
/// `AuthNotifier.refreshUser()`).
class TeacherState {
  final TeacherStats stats;
  final List<NotificationItem> notifications;

  const TeacherState({
    this.stats = const TeacherStats(),
    this.notifications = const [],
  });

  TeacherState copyWith({
    TeacherStats? stats,
    List<NotificationItem>? notifications,
  }) {
    return TeacherState(
      stats: stats ?? this.stats,
      notifications: notifications ?? this.notifications,
    );
  }
}

final teacherProvider = Provider<TeacherState>((ref) {
  final notifications = [...ref.watch(notificationProvider)]
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return TeacherState(
    stats: _calculateStats(notifications),
    notifications: notifications,
  );
});

/// `qr_code` del maestro listo para codificar en el QR, o `null` si el
/// usuario actual no es maestro, no tiene maestro vinculado o el registro
/// en backend no trae `qr_code`.
///
/// Fuente única: `authProvider.user.teacher?.qrCode`. El campo se carga
/// automáticamente en login/signUp/changePassword/switchAccount (vía
/// `AuthNotifier.refreshUser()`) y el botón de refresh en
/// `TeacherQRScreen` lo repuebla manualmente sin re-login.
final teacherQrProvider = Provider<String?>((ref) {
  final qr = ref.watch(
    authProvider.select((s) => s.user?.teacher?.qrCode),
  );
  if (qr == null) return null;
  final trimmed = qr.trim();
  return trimmed.isEmpty ? null : trimmed;
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