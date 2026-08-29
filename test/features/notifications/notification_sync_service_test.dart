import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_flutter_myaccess/core/errors/failures.dart';
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

        expect(result.succeeded, isTrue);
        expect(result.notifications, isEmpty);
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
              'user_id': 10,
              'type': 'attendance',
              'event': 'entry',
              'student_id': 10,
              'person_name': 'Pedrito Perez',
              'recorded_at': '2026-08-01T07:30:00-06:00',
            },
          ],
        },
      );

      final result = await syncService.fetchPending();

      expect(result.succeeded, isTrue);
      expect(result.notifications.length, 1);
      expect(result.notifications.first.backendId, 456);
      expect(result.notifications.first.recipientUserId, 10);
      expect(result.notifications.first.studentName, 'Pedrito Perez');
      expect(result.notifications.first.event, 'check_in');
      expect(result.notifications.first.studentId, 10);
    });

    test(
      'fetchPending informa error de parseo sin clave notifications',
      () async {
        when(
          () => mockApi.get<Map<String, dynamic>>('/notifications/sync'),
        ).thenAnswer((_) async => {'unexpected': 'value'});

        final result = await syncService.fetchPending();

        expect(result.succeeded, isFalse);
        expect(result.failure?.kind, NotificationSyncFailureKind.parse);
      },
    );

    test(
      'fetchPending informa error de red sin propagar excepciones',
      () async {
        when(
          () => mockApi.get<Map<String, dynamic>>('/notifications/sync'),
        ).thenThrow(Exception('network error'));

        final result = await syncService.fetchPending();

        expect(result.notifications, isEmpty);
        expect(result.failure?.kind, NotificationSyncFailureKind.network);
      },
    );

    test('ack envía POST al endpoint correcto', () async {
      when(
        () => mockApi.post<dynamic>('/notifications/ack/456'),
      ).thenAnswer((_) async => null);

      final result = await syncService.ack(456);

      expect(result.succeeded, isTrue);
      verify(() => mockApi.post<dynamic>('/notifications/ack/456')).called(1);
    });

    test('ack informa error sin propagar excepciones', () async {
      when(
        () => mockApi.post<dynamic>('/notifications/ack/456'),
      ).thenThrow(Exception('network error'));

      final result = await syncService.ack(456);

      expect(result.succeeded, isFalse);
      expect(result.failure?.kind, NotificationSyncFailureKind.network);
    });

    test('clasifica un 401 como no autorizado', () async {
      when(
        () => mockApi.get<Map<String, dynamic>>('/notifications/sync'),
      ).thenThrow(const ServerFailure('No autorizado', statusCode: 401));

      final result = await syncService.fetchPending();

      expect(result.failure?.kind, NotificationSyncFailureKind.unauthorized);
    });
  });
}
