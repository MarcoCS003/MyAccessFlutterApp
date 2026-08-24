import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/crash_report.dart';
import '../../../core/utils/user_key.dart';
import '../models/notification_item.dart';

/// Acceso compartido a la caja Hive de notificaciones. Centraliza la
/// deduplicación por id y el orden (más reciente primero) para que el
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

  Future<void> saveAll(List<NotificationItem> items) async {
    try {
      final sorted = dedupeAndSort(items);
      await _box.put(_key, sorted.map((n) => n.toJson()).toList());
    } catch (e, st) {
      debugPrint('Error saving notifications to Hive: $e');
      crashRecordError(e, st);
      _deleteCorruptKey();
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

  /// Inserta solo si no existe otro item con el mismo id.
  /// Devuelve true si se insertó (útil para decidir si mostrar bandeja).
  Future<bool> upsert(NotificationItem item) async {
    final items = load();
    if (items.any((n) => n.id == item.id)) return false;
    items.add(item);
    await saveAll(items);
    return true;
  }

  /// Colapsa duplicados por id (conserva la versión marcada como leída)
  /// y ordena de más reciente a más antiguo.
  static List<NotificationItem> dedupeAndSort(List<NotificationItem> items) {
    final byId = <String, NotificationItem>{};
    for (final n in items) {
      final prev = byId[n.id];
      if (prev == null || (n.isRead && !prev.isRead)) {
        byId[n.id] = n;
      }
    }
    return byId.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
