import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/crash_report.dart';
import '../../auth/data/session_store.dart';

/// Ventanas de sincronización (hora local): 9:00–10:00 y 15:00–16:00,
/// justo después de los picos de entradas (7–9) y salidas (13–15).
const List<int> syncWindowStartHours = [9, 15];
const Duration syncWindowLength = Duration(hours: 1);

/// Margen después del fin de la ventana: si el SO ejecutó la tarea tarde,
/// aún se sincroniza mientras `ahora <= ventanaFin + grace`.
const Duration syncWindowGrace = Duration(minutes: 30);

/// Clave en settings_box con el segundo (0–3599) dentro de la ventana en el
/// que ESTE dispositivo sincroniza (anti-estampida con ~1000 dispositivos).
const String deviceSyncSlotKey = 'deviceSyncSlot';

/// Devuelve el inicio de la ventana activa en [now] (incluye el grace), o
/// null si [now] está fuera de cualquier ventana + grace.
DateTime? activeWindowStart(DateTime now) {
  for (final hour in syncWindowStartHours) {
    final start = DateTime(now.year, now.month, now.day, hour);
    final endWithGrace = start.add(syncWindowLength).add(syncWindowGrace);
    if (!now.isBefore(start) && now.isBefore(endWithGrace)) return start;
  }
  return null;
}

/// Próximo inicio de ventana estrictamente posterior a [now].
DateTime nextWindowStart(DateTime now) {
  for (final hour in syncWindowStartHours) {
    final start = DateTime(now.year, now.month, now.day, hour);
    if (now.isBefore(start)) return start;
  }
  return DateTime(now.year, now.month, now.day + 1, syncWindowStartHours.first);
}

/// La ventana iniciada más reciente (la de hoy si ya empezó alguna, si no la
/// última de ayer). Sirve para detectar si la app se abrió sin que el sync
/// automático haya cubierto la ventana pasada.
DateTime lastStartedWindow(DateTime now) {
  DateTime? latest;
  for (final hour in syncWindowStartHours) {
    final start = DateTime(now.year, now.month, now.day, hour);
    if (!start.isAfter(now)) latest = start;
  }
  return latest ??
      DateTime(now.year, now.month, now.day - 1, syncWindowStartHours.last);
}

/// Valor del marcador `lastDiffSync_<userKey>`: identifica fecha + ventana
/// (`2026-08-29:09`) para que una segunda pasada en la misma ventana no
/// repita requests.
String windowMarkerValue(DateTime windowStart) {
  final m = windowStart.month.toString().padLeft(2, '0');
  final d = windowStart.day.toString().padLeft(2, '0');
  final h = windowStart.hour.toString().padLeft(2, '0');
  return '${windowStart.year}-$m-$d:$h';
}

/// Slot (0–3599 s) estable del dispositivo dentro de la ventana.
///
/// Se genera aleatorio en el primer arranque del scheduler y se persiste en
/// settings_box. Si Hive no está disponible (o la escritura falla), se usa
/// un fallback determinista: `hash(user_id de la primera sesión) % 3600`.
Future<int> resolveDeviceSyncSlot(List<SavedSession> sessions) async {
  try {
    final box = Hive.box(AppConstants.settingsBox);
    final raw = box.get(deviceSyncSlotKey);
    if (raw is int && raw >= 0 && raw < 3600) return raw;
    final slot = Random().nextInt(3600);
    await box.put(deviceSyncSlotKey, slot);
    return slot;
  } catch (e, st) {
    debugPrint('[SyncWindow] slot fallback por error de Hive: $e');
    crashRecordError(e, st);
    final primaryId = sessions.isEmpty ? 0 : sessions.first.user.id;
    return primaryId.abs() % 3600;
  }
}
