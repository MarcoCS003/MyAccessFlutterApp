import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_local_store.dart';
import '../models/notification_item.dart';

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
      return NotificationNotifier();
    });

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier({NotificationLocalStore? store})
    : _store = store ?? NotificationLocalStore(),
      super([]) {
    reloadFromLocal();
  }

  final NotificationLocalStore _store;

  /// Relee Hive. Llamar al volver a primer plano: cubre lo que el handler
  /// de background escribió mientras la app estaba en segundo plano.
  void reloadFromLocal() {
    state = _store.load();
    debugPrint('[NOTIF] reloadFromLocal: ${state.length} items desde Hive');
  }

  /// Devuelve true si la notificación era nueva (no duplicada por id).
  Future<bool> addFromFcm(Map<String, dynamic> data) =>
      addNotification(NotificationItem.fromFcm(data));

  /// Devuelve true si la notificación era nueva.
  Future<bool> addNotification(NotificationItem notification) async {
    // Merge con Hive antes de guardar: no pisa items escritos por el
    // isolate de background mientras la app estaba en segundo plano.
    final persisted = _store.load();
    final isNew =
        !persisted.any((n) => n.id == notification.id) &&
        !state.any((n) => n.id == notification.id);
    state = NotificationLocalStore.dedupeAndSort([
      notification,
      ...persisted,
      ...state,
    ]);
    await _store.saveAll(state);
    return isNew;
  }

  Future<void> markAsRead(String id) async {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    await _store.saveAll(state);
  }

  Future<void> markAllAsRead() async {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    await _store.saveAll(state);
  }

  Future<void> dismiss(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _store.saveAll(state);
  }

  Future<void> clearAll() async {
    state = [];
    await _store.saveAll(state);
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}
