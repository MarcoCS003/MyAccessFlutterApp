import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/notification_item.dart';

/// Acceso compartido a la caja Hive de notificaciones. Centraliza la
/// deduplicación por id y el orden (más reciente primero) para que el
/// provider y el handler de background de FCM escriban igual.
class NotificationLocalStore {
  static const String _key = 'items';

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
    } catch (e) {
      debugPrint('Error loading notifications from Hive: $e');
      return [];
    }
  }

  Future<void> saveAll(List<NotificationItem> items) async {
    try {
      final sorted = dedupeAndSort(items);
      await _box.put(_key, sorted.map((n) => n.toJson()).toList());
    } catch (e) {
      debugPrint('Error saving notifications to Hive: $e');
    }
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
