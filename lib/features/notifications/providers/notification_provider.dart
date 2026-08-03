import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/notification_local_store.dart';
import '../models/notification_item.dart';

/// Se recrea cuando cambia el usuario autenticado (login de otra cuenta o
/// logout): el notifier nuevo recarga Hive bajo la clave de ESA cuenta, así
/// nadie hereda en memoria las notificaciones de la cuenta anterior. Sin
/// sesión, la lista queda vacía.
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
      final email = ref.watch(authProvider.select((s) => s.user?.email));
      return NotificationNotifier(userKey: email);
    });

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier({String? userKey, NotificationLocalStore? store})
    : _store =
          store ??
          (userKey == null ? null : NotificationLocalStore(userKey: userKey)),
      super([]) {
    // Sin usuario autenticado no se lee nada de Hive: ni el inbox anónimo
    // ni los datos de otra cuenta.
    if (_store != null) reloadFromLocal();
  }

  final NotificationLocalStore? _store;

  /// Store para escrituras: si el notifier aún no tiene usuario (p. ej.
  /// getInitialMessage antes de que checkAuthStatus resuelva) se resuelve
  /// desde auth_box para no perder el mensaje.
  NotificationLocalStore get _writeStore =>
      _store ?? NotificationLocalStore.forCurrentUser();

  /// Relee Hive. Llamar al volver a primer plano: cubre lo que el handler
  /// de background escribió mientras la app estaba en segundo plano.
  void reloadFromLocal() {
    state = _store?.load() ?? [];
    debugPrint('[NOTIF] reloadFromLocal: ${state.length} items desde Hive');
  }

  /// Devuelve true si la notificación era nueva (no duplicada por id).
  Future<bool> addFromFcm(Map<String, dynamic> data) =>
      addNotification(NotificationItem.fromFcm(data));

  /// Devuelve true si la notificación era nueva.
  Future<bool> addNotification(NotificationItem notification) async {
    // Merge con Hive antes de guardar: no pisa items escritos por el
    // isolate de background mientras la app estaba en segundo plano.
    final persisted = _writeStore.load();
    final isNew =
        !persisted.any((n) => n.id == notification.id) &&
        !state.any((n) => n.id == notification.id);
    state = NotificationLocalStore.dedupeAndSort([
      notification,
      ...persisted,
      ...state,
    ]);
    await _writeStore.saveAll(state);
    return isNew;
  }

  Future<void> markAsRead(String id) async {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    await _writeStore.saveAll(state);
  }

  Future<void> markAllAsRead() async {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    await _writeStore.saveAll(state);
  }

  Future<void> dismiss(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _writeStore.saveAll(state);
  }

  Future<void> clearAll() async {
    state = [];
    await _writeStore.saveAll(state);
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}
