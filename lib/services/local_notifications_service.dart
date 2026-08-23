import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/notifications/models/notification_item.dart';

/// Muestra notificaciones del sistema (bandeja) para los eventos de acceso.
/// FCM no muestra nada cuando la app está en primer plano, y los mensajes
/// data-only tampoco generan UI en segundo plano: este servicio cubre ambos.
class LocalNotificationsService {
  LocalNotificationsService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'attendance_channel';
  static const String _channelName = 'Entradas y salidas';
  static const String _channelDescription =
      'Notificaciones de acceso de alumnos';

  Future<void> init({void Function()? onTap}) async {
    const androidInit = AndroidInitializationSettings('ic_notification');
    // Los permisos ya se piden vía FirebaseMessaging.requestPermission().
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: onTap == null ? null : (_) => onTap(),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
  }

  Future<void> showAttendance(NotificationItem item) async {
    await _plugin.show(
      id: item.id.hashCode,
      title: item.title,
      body: item.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          icon: 'ic_notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: item.id,
    );
  }
}
