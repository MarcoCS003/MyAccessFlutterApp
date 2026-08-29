import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/crash_report.dart';
import '../../../core/utils/user_key.dart';
import '../models/notification_item.dart';

/// Acceso compartido a la caja Hive de notificaciones. Centraliza la
/// deduplicación por identidad y el orden (más reciente primero) para que el
/// provider y el handler de background de FCM escriban igual.
///
/// Aislamiento por cuenta: cada usuario lee/escribe bajo `items_<userKey>`.
/// La clave global 'items' de versiones anteriores quedó huérfana (app en
/// desarrollo, datos demo): no se migra.
class NotificationLocalStore {
  NotificationLocalStore({required String userKey})
    : _key = 'items_${userStorageKey(userKey)}';

  /// Store del usuario de la última sesión persistida en auth_box; sin
  /// sesión cae en el inbox anónimo (la UI no lo lee, pero el mensaje FCM
  /// no se pierde). Para handlers FCM y el isolate de background.
  factory NotificationLocalStore.forCurrentUser() =>
      NotificationLocalStore(userKey: currentUserKey() ?? anonymousUserKey);

  final String _key;

  Box get _box => Hive.box(AppConstants.notificationsBox);

  List<NotificationItem> load() {
    try {
      final raw = _box.get(_key, defaultValue: <Map<dynamic, dynamic>>[]);
      final items = (raw as List)
          .map(
            (e) =>
                NotificationItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      return dedupeAndSort(items);
    } catch (e, st) {
      debugPrint('Error loading notifications from Hive: $e');
      crashRecordError(e, st);
      _deleteCorruptKey();
      return [];
    }
  }

  Future<bool> saveAll(List<NotificationItem> items) async {
    try {
      final sorted = dedupeAndSort(items);
      await _box.put(_key, sorted.map((n) => n.toJson()).toList());
      return true;
    } catch (e, st) {
      debugPrint('Error saving notifications to Hive: $e');
      crashRecordError(e, st);
      _deleteCorruptKey();
      return false;
    }
  }

  /// Borra SOLO la clave de esta cuenta tras un fallo (nunca box.clear(),
  /// que borraría las demás cuentas del dispositivo). El próximo sync
  /// repuebla el inbox. Best-effort: si el box ni siquiera está abierto,
  /// no hace nada.
  void _deleteCorruptKey() {
    try {
      unawaited(_box.delete(_key));
    } catch (_) {}
  }

  /// Inserta solo si no existe otro item con la misma identidad.
  ///
  /// Cuando existe [NotificationItem.backendId], esa identidad tiene prioridad
  /// sobre el id local para colapsar la misma fila recibida por FCM y sync.
  Future<NotificationUpsertResult> upsert(NotificationItem item) async {
    final items = load();
    if (items.any((n) => isSameNotification(n, item))) {
      return const NotificationUpsertResult.persistedDuplicate();
    }
    items.add(item);
    final persisted = await saveAll(items);
    if (!persisted) return const NotificationUpsertResult.failure();
    return const NotificationUpsertResult.persistedInsert();
  }

  /// Colapsa duplicados por backendId o, si no existe, por id local. Conserva
  /// la versión marcada como leída y ordena de más reciente a más antiguo.
  static List<NotificationItem> dedupeAndSort(List<NotificationItem> items) {
    final byId = <String, NotificationItem>{};
    for (final n in items) {
      final prev = byId[_identityKey(n)];
      if (prev == null || (n.isRead && !prev.isRead)) {
        byId[_identityKey(n)] = n;
      }
    }
    return byId.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static bool isSameNotification(
    NotificationItem first,
    NotificationItem second,
  ) => _identityKey(first) == _identityKey(second);

  static String _identityKey(NotificationItem item) =>
      item.backendId != null ? 'backend:${item.backendId}' : 'local:${item.id}';
}

class NotificationUpsertResult {
  const NotificationUpsertResult._({
    required this.persisted,
    required this.inserted,
  });

  const NotificationUpsertResult.persistedInsert()
    : this._(persisted: true, inserted: true);

  const NotificationUpsertResult.persistedDuplicate()
    : this._(persisted: true, inserted: false);

  const NotificationUpsertResult.failure()
    : this._(persisted: false, inserted: false);

  final bool persisted;
  final bool inserted;
}
