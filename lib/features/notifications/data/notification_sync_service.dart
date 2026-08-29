import 'package:flutter/foundation.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/crash_report.dart';
import '../../../services/api_service.dart';
import '../models/notification_item.dart';

enum NotificationSyncFailureKind { network, unauthorized, parse, server }

class NotificationSyncFailure {
  const NotificationSyncFailure(this.kind);

  final NotificationSyncFailureKind kind;
}

class NotificationSyncFetchResult {
  const NotificationSyncFetchResult({
    required this.notifications,
    this.failure,
    this.invalidItems = 0,
  });

  const NotificationSyncFetchResult.success(
    List<NotificationItem> notifications, {
    int invalidItems = 0,
  }) : this(
         notifications: notifications,
         invalidItems: invalidItems,
         failure: invalidItems > 0
             ? const NotificationSyncFailure(NotificationSyncFailureKind.parse)
             : null,
       );

  const NotificationSyncFetchResult.failed(NotificationSyncFailure failure)
    : this(notifications: const [], failure: failure);

  final List<NotificationItem> notifications;
  final NotificationSyncFailure? failure;
  final int invalidItems;

  bool get succeeded => failure == null;
}

class NotificationSyncAckResult {
  const NotificationSyncAckResult({this.failure});

  const NotificationSyncAckResult.success() : this();

  const NotificationSyncAckResult.failed(NotificationSyncFailure failure)
    : this(failure: failure);

  final NotificationSyncFailure? failure;

  bool get succeeded => failure == null;
}

/// Servicio para sincronizar notificaciones pendientes con el backend.
///
/// Los métodos devuelven el tipo de fallo para que el caller pueda decidir si
/// actualiza el marcador de sync o conserva el trabajo para reintento.
class NotificationSyncService {
  final ApiService _api;

  NotificationSyncService({ApiService? api}) : _api = api ?? ApiService();

  /// Obtiene las notificaciones pendientes del endpoint de sincronización.
  Future<NotificationSyncFetchResult> fetchPending() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/notifications/sync',
      );
      final list = response['notifications'];
      if (list is! List) {
        return const NotificationSyncFetchResult.failed(
          NotificationSyncFailure(NotificationSyncFailureKind.parse),
        );
      }

      final notifications = <NotificationItem>[];
      var invalidItems = 0;
      for (final raw in list) {
        if (raw is! Map) {
          invalidItems++;
          continue;
        }
        try {
          notifications.add(
            NotificationItem.fromSyncApi(Map<String, dynamic>.from(raw)),
          );
        } on FormatException catch (e) {
          invalidItems++;
          debugPrint('[NotificationSyncService] item descartado: $e');
        }
      }

      crashLog('notif_sync: fetched=${list.length}');
      return NotificationSyncFetchResult.success(
        notifications,
        invalidItems: invalidItems,
      );
    } catch (e) {
      debugPrint('[NotificationSyncService] fetchPending error: $e');
      return NotificationSyncFetchResult.failed(_classifyFailure(e));
    }
  }

  /// Marca una notificación como confirmada en el backend.
  Future<NotificationSyncAckResult> ack(int backendId) async {
    try {
      await _api.post<dynamic>('/notifications/ack/$backendId');
      return const NotificationSyncAckResult.success();
    } catch (e) {
      debugPrint('[NotificationSyncService] ack($backendId) error: $e');
      return NotificationSyncAckResult.failed(_classifyFailure(e));
    }
  }

  NotificationSyncFailure _classifyFailure(Object error) {
    if (error is NetworkFailure) {
      return const NotificationSyncFailure(NotificationSyncFailureKind.network);
    }
    if (error is ServerFailure) {
      if (error.statusCode == 401) {
        return const NotificationSyncFailure(
          NotificationSyncFailureKind.unauthorized,
        );
      }
      return const NotificationSyncFailure(NotificationSyncFailureKind.server);
    }
    if (error is FormatException || error is TypeError) {
      return const NotificationSyncFailure(NotificationSyncFailureKind.parse);
    }
    // ApiService normally maps connection failures to NetworkFailure. Treat
    // unexpected exceptions as retryable network failures as a safeguard for
    // background isolates and test doubles.
    return const NotificationSyncFailure(NotificationSyncFailureKind.network);
  }
}
