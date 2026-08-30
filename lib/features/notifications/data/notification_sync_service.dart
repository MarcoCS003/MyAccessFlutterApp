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

/// Servicio para reconciliar notificaciones con el backend (sync v2).
///
/// El cliente envía los IDs locales que ya tiene guardados y el backend
/// devuelve solo los registros faltantes. Los métodos devuelven el tipo de
/// fallo para que el caller decida si marca la ventana como sincronizada o
/// reintenta en la siguiente.
class NotificationSyncService {
  final ApiService _api;

  NotificationSyncService({ApiService? api}) : _api = api ?? ApiService();

  /// Pide al backend los registros que faltan comparando [localIds] (los más
  /// recientes de la cuenta, máximo 10) contra los últimos 10 del usuario.
  Future<NotificationSyncFetchResult> fetchDiff(List<int> localIds) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/notifications/diff',
        data: {'local_ids': localIds},
      );
      final list = response['missing'];
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
      debugPrint('[NotificationSyncService] fetchDiff error: $e');
      return NotificationSyncFetchResult.failed(_classifyFailure(e));
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
