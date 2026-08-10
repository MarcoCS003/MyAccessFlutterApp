import 'package:flutter/foundation.dart';

import '../../../services/api_service.dart';
import '../models/notification_item.dart';

/// Servicio para sincronizar notificaciones pendientes con el backend.
///
/// Todos los métodos capturan errores y los loggean con [debugPrint] sin
/// propagar excepciones, por lo que son seguros de invocar desde isolate
/// de background o desde providers.
class NotificationSyncService {
  final ApiService _api;

  NotificationSyncService({ApiService? api}) : _api = api ?? ApiService();

  /// Obtiene las notificaciones pendientes del endpoint de sincronización.
  Future<List<NotificationItem>> fetchPending() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/notifications/sync',
      );
      final list = response['notifications'];
      if (list is! List<dynamic>) return [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromSyncApi)
          .toList();
    } catch (e) {
      debugPrint('[NotificationSyncService] fetchPending error: $e');
      return [];
    }
  }

  /// Marca una notificación como confirmada en el backend.
  Future<void> ack(int backendId) async {
    try {
      await _api.post<dynamic>('/notifications/ack/$backendId');
    } catch (e) {
      debugPrint('[NotificationSyncService] ack($backendId) error: $e');
    }
  }
}
