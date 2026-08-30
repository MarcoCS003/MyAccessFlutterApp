import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cliente_flutter_myaccess/features/auth/data/session_store.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';
import 'package:cliente_flutter_myaccess/features/notifications/background/sync_window.dart';

import '../../test_helpers.dart';

void main() {
  group('ventanas de sincronización', () {
    test('activeWindowStart cubre ventana y grace', () {
      expect(activeWindowStart(DateTime(2026, 8, 29, 8, 59)), isNull);
      expect(
        activeWindowStart(DateTime(2026, 8, 29, 9, 0)),
        DateTime(2026, 8, 29, 9),
      );
      expect(
        activeWindowStart(DateTime(2026, 8, 29, 9, 59)),
        DateTime(2026, 8, 29, 9),
      );
      // Grace: 10:00–10:30 sigue contando como ventana de las 9.
      expect(
        activeWindowStart(DateTime(2026, 8, 29, 10, 29)),
        DateTime(2026, 8, 29, 9),
      );
      expect(activeWindowStart(DateTime(2026, 8, 29, 10, 30)), isNull);
      expect(activeWindowStart(DateTime(2026, 8, 29, 13, 0)), isNull);
      expect(
        activeWindowStart(DateTime(2026, 8, 29, 15, 30)),
        DateTime(2026, 8, 29, 15),
      );
      expect(
        activeWindowStart(DateTime(2026, 8, 29, 16, 29)),
        DateTime(2026, 8, 29, 15),
      );
      expect(activeWindowStart(DateTime(2026, 8, 29, 16, 30)), isNull);
    });

    test('nextWindowStart apunta a la siguiente ventana', () {
      expect(
        nextWindowStart(DateTime(2026, 8, 29, 8, 0)),
        DateTime(2026, 8, 29, 9),
      );
      expect(
        nextWindowStart(DateTime(2026, 8, 29, 9, 30)),
        DateTime(2026, 8, 29, 15),
      );
      expect(
        nextWindowStart(DateTime(2026, 8, 29, 14, 59)),
        DateTime(2026, 8, 29, 15),
      );
      expect(
        nextWindowStart(DateTime(2026, 8, 29, 16, 0)),
        DateTime(2026, 8, 30, 9),
      );
    });

    test('lastStartedWindow devuelve la ventana iniciada más reciente', () {
      expect(
        lastStartedWindow(DateTime(2026, 8, 29, 8, 0)),
        DateTime(2026, 8, 28, 15),
      );
      expect(
        lastStartedWindow(DateTime(2026, 8, 29, 9, 30)),
        DateTime(2026, 8, 29, 9),
      );
      expect(
        lastStartedWindow(DateTime(2026, 8, 29, 16, 0)),
        DateTime(2026, 8, 29, 15),
      );
    });

    test('windowMarkerValue identifica fecha y ventana', () {
      expect(windowMarkerValue(DateTime(2026, 8, 29, 9)), '2026-08-29:09');
      expect(windowMarkerValue(DateTime(2026, 12, 3, 15)), '2026-12-03:15');
    });
  });

  group('deviceSyncSlot', () {
    setUp(() async {
      await initializeTestHive();
    });

    tearDown(() async {
      await cleanUpTestHive();
    });

    test('genera un slot en rango, lo persiste y lo reutiliza', () async {
      final first = await resolveDeviceSyncSlot(const []);
      expect(first, inInclusiveRange(0, 3599));
      expect(Hive.box('settings_box').get('deviceSyncSlot'), first);

      final second = await resolveDeviceSyncSlot(const []);
      expect(second, first);
    });

    test('cae al hash del user_id si Hive no está disponible', () async {
      await Hive.box('settings_box').close();

      final sessions = [
        const SavedSession(
          userKey: 'papa@ijl.edu.mx',
          user: User(
            id: 4321,
            name: 'Padre',
            email: 'papa@ijl.edu.mx',
            role: 'parent',
          ),
        ),
      ];
      final slot = await resolveDeviceSyncSlot(sessions);

      expect(slot, 4321 % 3600);
      await Hive.openBox('settings_box');
    });
  });
}
