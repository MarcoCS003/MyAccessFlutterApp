import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_flutter_myaccess/features/notifications/data/notification_sync_service.dart';
import 'package:cliente_flutter_myaccess/services/api_service.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  group('NotificationSyncService', () {
    late _MockApiService mockApi;
    late NotificationSyncService syncService;

    setUp(() {
      mockApi = _MockApiService();
      syncService = NotificationSyncService(api: mockApi);
    });

    test(
      'fetchPending devuelve lista vacía cuando el backend no tiene pendientes',
      () async {
        when(
          () => mockApi.get<Map<String, dynamic>>('/notifications/sync'),
        ).thenAnswer((_) async => {'notifications': <dynamic>[]});

        final result = await syncService.fetchPending();

        expect(result, isEmpty);
      },
    );

    test('fetchPending mapea notificaciones pendientes del backend', () async {
      when(
        () => mockApi.get<Map<String, dynamic>>('/notifications/sync'),
      ).thenAnswer(
        (_) async => {
          'notifications': [
            {
              'id': 456,
              'type': 'attendance',
              'event': 'check_in',
              'student_id': 10,
              'student_name': 'Pedrito Perez',
              'timestamp': '2026-08-01T07:30:00-06:00',
            },
          ],
        },
      );

      final result = await syncService.fetchPending();

      expect(result.length, 1);
      expect(result.first.backendId, 456);
      expect(result.first.studentName, 'Pedrito Perez');
      expect(result.first.event, 'check_in');
      expect(result.first.studentId, 10);
    });

    test(
      'fetchPending devuelve lista vacía si el backend responde sin clave notifications',
      () async {
        when(
          () => mockApi.get<Map<String, dynamic>>('/notifications/sync'),
        ).thenAnswer((_) async => {'unexpected': 'value'});

        final result = await syncService.fetchPending();

        expect(result, isEmpty);
      },
    );

    test(
      'fetchPending no propaga excepciones y devuelve lista vacía',
      () async {
        when(
          () => mockApi.get<Map<String, dynamic>>('/notifications/sync'),
        ).thenThrow(Exception('network error'));

        final result = await syncService.fetchPending();

        expect(result, isEmpty);
      },
    );

    test('ack envía POST al endpoint correcto', () async {
      when(
        () => mockApi.post<dynamic>('/notifications/ack/456'),
      ).thenAnswer((_) async => null);

      await syncService.ack(456);

      verify(() => mockApi.post<dynamic>('/notifications/ack/456')).called(1);
    });

    test('ack no propaga excepciones', () async {
      when(
        () => mockApi.post<dynamic>('/notifications/ack/456'),
      ).thenThrow(Exception('network error'));

      await syncService.ack(456);

      // Si no lanza, el test pasa.
      expect(true, isTrue);
    });
  });
}
