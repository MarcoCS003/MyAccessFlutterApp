import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/notification_item.dart';
import 'notification_local_store.dart';

/// Genera datos demo de entradas/salidas (solo se invoca en builds debug)
/// para probar la app con un mes de historial en la BD local. Los items se
/// marcan con `location: 'Demo'` para distinguirlos de los eventos reales.
class NotificationSeeder {
  NotificationSeeder({NotificationLocalStore? store, Box? settingsBox})
    : _store = store ?? NotificationLocalStore(),
      _settingsBox = settingsBox ?? Hive.box(AppConstants.settingsBox);

  final NotificationLocalStore _store;
  final Box _settingsBox;

  static const String demoLocation = 'Demo';

  static String _flagKey(String userKey) => 'demo_seed_$userKey';

  /// Siembra un mes ([days] días hacia atrás, solo lunes-viernes) de entradas
  /// (~07:45) y salidas (~14:30) para cada persona. Idempotente por usuario:
  /// si ya se sembró para [userKey] devuelve 0 sin tocar la BD. El flag vive
  /// en settingsBox, que signOut limpia, así que el siguiente login re-siembra.
  Future<int> seedMonthForUser({
    required String userKey,
    required List<({int id, String name})> people,
    required String type,
    int days = 30,
  }) async {
    if (people.isEmpty) return 0;
    if (_settingsBox.get(_flagKey(userKey)) == true) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final generated = <NotificationItem>[];

    for (var offset = days; offset >= 0; offset--) {
      final day = today.subtract(Duration(days: offset));
      if (day.weekday > DateTime.friday) continue;

      for (final person in people) {
        // Jitter determinista: mismos timestamps en cada ejecución → mismos
        // ids → la deduplicación por id absorbe las re-ejecuciones.
        final jitter = (_dayOfYear(day) + person.id) % 21 - 10;
        final entry = DateTime(day.year, day.month, day.day, 7, 45 + jitter);
        final exit = DateTime(day.year, day.month, day.day, 14, 30 + jitter);

        for (final (event, time) in [
          ('check_in', entry),
          ('check_out', exit),
        ]) {
          // Nada de eventos a futuro: si corre a las 08:00, hoy solo siembra
          // la entrada.
          if (time.isAfter(now)) continue;
          final iso = time.toIso8601String();
          generated.add(
            NotificationItem(
              id: '${person.id}_${event}_$iso',
              type: type,
              event: event,
              studentName: person.name,
              studentId: person.id,
              timestamp: time,
              isRead: true,
              location: demoLocation,
            ),
          );
        }
      }
    }

    await _store.saveAll([...generated, ..._store.load()]);
    await _settingsBox.put(_flagKey(userKey), true);
    return generated.length;
  }

  static int _dayOfYear(DateTime d) =>
      d.difference(DateTime(d.year, 1, 1)).inDays + 1;
}
