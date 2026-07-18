import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cliente_flutter_myaccess/features/notifications/providers/notification_provider.dart';
import 'package:cliente_flutter_myaccess/features/padres/models/child.dart';
import 'package:cliente_flutter_myaccess/features/padres/providers/children_provider.dart';

import '../../mocks/children_mocks.dart';
import '../../test_helpers.dart';

void main() {
  final juan = Child(
    id: 1,
    name: 'Juan Pérez',
    grade: '3ro Primaria',
    group: 'A',
    status: 'outside',
  );
  final ana = Child(
    id: 2,
    name: 'Ana López',
    grade: '2do Primaria',
    group: 'B',
    status: 'outside',
  );

  setUp(() async {
    await initializeTestHive();
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  Future<ProviderContainer> makeContainer({
    required List<Map<String, dynamic>> fcmMessages,
  }) async {
    final container = ProviderContainer(
      overrides: [
        childrenProvider.overrideWith(
          (ref) => MockChildrenNotifier([juan, ana]),
        ),
      ],
    );
    final notifier = container.read(notificationProvider.notifier);
    for (final data in fcmMessages) {
      await notifier.addFromFcm(data);
    }
    return container;
  }

  test(
    'childrenWithActivityProvider marca dentro al hijo con check_in de hoy',
    () async {
      final container = await makeContainer(
        fcmMessages: [
          {
            'student_id': '1',
            'student_name': 'Juan Pérez',
            'event': 'check_in',
            'timestamp': DateTime.now().toIso8601String(),
          },
        ],
      );
      addTearDown(container.dispose);

      final children = container.read(childrenWithActivityProvider).value!;
      final juanAct = children.firstWhere((c) => c.id == 1);
      final anaAct = children.firstWhere((c) => c.id == 2);

      expect(juanAct.status, 'inside');
      expect(juanAct.lastEvent, 'Última entrada');
      expect(juanAct.lastEventTime, isNotNull);
      expect(anaAct.status, 'outside'); // sin eventos: conserva backend
      expect(anaAct.lastEvent, isNull);
    },
  );

  test(
    'evento de ayer no cambia el estado pero informa el último evento',
    () async {
      final ayer = DateTime.now().subtract(const Duration(days: 1));
      final container = await makeContainer(
        fcmMessages: [
          {
            'student_id': '1',
            'student_name': 'Juan Pérez',
            'event': 'check_in',
            'timestamp': ayer.toIso8601String(),
          },
        ],
      );
      addTearDown(container.dispose);

      final juanAct = container
          .read(childrenWithActivityProvider)
          .value!
          .firstWhere((c) => c.id == 1);
      // El estado no se altera por eventos de días anteriores...
      expect(juanAct.status, 'outside');
      // ...pero el card muestra el último evento conocido de la BD local.
      expect(juanAct.lastEvent, 'Última entrada');
      expect(juanAct.lastEventTime, isNotNull);
    },
  );

  test('timestamp en UTC se interpreta en hora local y sí aplica', () async {
    final container = await makeContainer(
      fcmMessages: [
        {
          'student_id': '1',
          'student_name': 'Juan Pérez',
          'event': 'check_in',
          'timestamp': DateTime.now().toUtc().toIso8601String(), // con Z
        },
      ],
    );
    addTearDown(container.dispose);

    final juanAct = container
        .read(childrenWithActivityProvider)
        .value!
        .firstWhere((c) => c.id == 1);
    expect(juanAct.status, 'inside');
    expect(juanAct.lastEvent, 'Última entrada');
  });

  test('childTimelineProvider filtra por alumno y mapea campos', () async {
    final container = await makeContainer(
      fcmMessages: [
        {
          'student_id': '1',
          'student_name': 'Juan Pérez',
          'event': 'check_in',
          'timestamp': DateTime.now().toIso8601String(),
          'location': 'Puerta Principal',
        },
      ],
    );
    addTearDown(container.dispose);

    final events = await container.read(childTimelineProvider(1).future);
    expect(events.length, 1);
    expect(events.first.type, 'check_in');
    expect(events.first.studentId, 1);
    expect(events.first.location, 'Puerta Principal');

    final eventsAna = await container.read(childTimelineProvider(2).future);
    expect(eventsAna, isEmpty);
  });
}
