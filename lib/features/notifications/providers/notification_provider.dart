import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
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
    if (_store != null) {
      // Carga inicial síncrona (el box acaba de abrirse en main()).
      state = _store.load();
      debugPrint('[NOTIF] carga inicial: ${state.length} items desde Hive');
    }
  }

  final NotificationLocalStore? _store;

  /// Store para escrituras: si el notifier aún no tiene usuario (p. ej.
  /// getInitialMessage antes de que checkAuthStatus resuelva) se resuelve
  /// desde auth_box para no perder el mensaje.
  NotificationLocalStore get _writeStore =>
      _store ?? NotificationLocalStore.forCurrentUser();

  /// Relee Hive DESDE DISCO. Llamar al volver a primer plano: cubre lo que
  /// el handler de background de FCM y la tarea de sync escribieron mientras
  /// la app estaba en segundo plano. Esos corren en OTRO isolate con su
  /// propia instancia de Hive, así que el box abierto en este isolate no ve
  /// sus escrituras hasta cerrarlo y reabrirlo.
  Future<void> reloadFromLocal() async {
    final store = _store;
    if (store == null) {
      state = [];
      return;
    }
    if (Hive.isBoxOpen(AppConstants.notificationsBox)) {
      await Hive.box(AppConstants.notificationsBox).close();
    }
    await Hive.openBox(AppConstants.notificationsBox);
    state = store.load();
    debugPrint('[NOTIF] reloadFromLocal: ${state.length} items desde Hive');
  }

  /// Persiste una notificación FCM. Un payload inválido se rechaza sin
  /// actualizar el estado ni hacer que la UI lo considere nuevo.
  Future<NotificationUpsertResult> addFromFcm(Map<String, dynamic> data) async {
    final notification = NotificationItem.tryFromFcm(data);
    if (notification == null) return const NotificationUpsertResult.failure();
    return addNotification(notification);
  }

  /// Persiste una notificación y solo actualiza el estado después de que Hive
  /// confirma la escritura.
  Future<NotificationUpsertResult> addNotification(
    NotificationItem notification,
  ) async {
    // Sin sesión resuelta (p.ej. getInitialMessage antes de que
    // checkAuthStatus resuelva): persistir en el inbox resuelto para no
    // perder el mensaje, pero NO cargar en memoria el inbox completo de la
    // última cuenta conocida — podría no corresponder a esta sesión.
    if (_store == null) {
      final persisted = _writeStore.load();
      final isNew =
          !persisted.any(
            (n) => NotificationLocalStore.isSameNotification(n, notification),
          ) &&
          !state.any(
            (n) => NotificationLocalStore.isSameNotification(n, notification),
          );
      final merged = NotificationLocalStore.dedupeAndSort([
        notification,
        ...persisted,
        ...state,
      ]);
      final saved = await _writeStore.saveAll(merged);
      if (!saved) return const NotificationUpsertResult.failure();
      state = merged;
      return isNew
          ? const NotificationUpsertResult.persistedInsert()
          : const NotificationUpsertResult.persistedDuplicate();
    }
    // Merge con Hive antes de guardar: no pisa items escritos por el
    // isolate de background mientras la app estaba en segundo plano.
    final persisted = _store.load();
    final isNew =
        !persisted.any(
          (n) => NotificationLocalStore.isSameNotification(n, notification),
        ) &&
        !state.any(
          (n) => NotificationLocalStore.isSameNotification(n, notification),
        );
    final merged = NotificationLocalStore.dedupeAndSort([
      notification,
      ...persisted,
      ...state,
    ]);
    final saved = await _store.saveAll(merged);
    if (!saved) return const NotificationUpsertResult.failure();
    state = merged;
    return isNew
        ? const NotificationUpsertResult.persistedInsert()
        : const NotificationUpsertResult.persistedDuplicate();
  }

  Future<void> markAsRead(String id) async {
    final updated = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    if (await _writeStore.saveAll(updated)) state = updated;
  }

  Future<void> markAllAsRead() async {
    final updated = state.map((n) => n.copyWith(isRead: true)).toList();
    if (await _writeStore.saveAll(updated)) state = updated;
  }

  Future<void> dismiss(String id) async {
    final updated = state.where((n) => n.id != id).toList();
    if (await _writeStore.saveAll(updated)) state = updated;
  }

  Future<void> clearAll() async {
    if (await _writeStore.saveAll(const [])) state = [];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}
