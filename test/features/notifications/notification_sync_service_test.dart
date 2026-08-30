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

    test('fetchDiff envía los IDs locales al endpoint de diff', () async {
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/notifications/diff',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => {'window_size': 10, 'missing': <dynamic>[]});

      final result = await syncService.fetchDiff([1042, 1041, 1039]);

      expect(result.succeeded, isTrue);
      expect(result.notifications, isEmpty);
      verify(
        () => mockApi.post<Map<String, dynamic>>(
          '/notifications/diff',
          data: {
            'local_ids': [1042, 1041, 1039],
          },
        ),
      ).called(1);
    });

    test('fetchDiff mapea los registros faltantes del backend', () async {
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/notifications/diff',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => {
          'window_size': 10,
          'missing': [
            {
              'id': 1043,
              'user_id': 42,
              'type': 'attendance',
              'event': 'entry',
              'student_id': 10,
              'teacher_id': null,
              'person_name': 'Juan Pérez',
              'title': 'Entrada de Juan Pérez',
              'body': 'Juan Pérez registró Entrada a las 07:55',
              'recorded_at': '2026-08-29T07:55:12-06:00',
            },
          ],
        },
      );

      final result = await syncService.fetchDiff([1042]);

      expect(result.succeeded, isTrue);
      expect(result.notifications.length, 1);
      expect(result.notifications.first.backendId, 1043);
      expect(result.notifications.first.recipientUserId, 42);
      expect(result.notifications.first.studentName, 'Juan Pérez');
      expect(result.notifications.first.event, 'check_in');
      expect(result.notifications.first.studentId, 10);
    });

    test('fetchDiff informa error de parseo sin clave missing', () async {
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/notifications/diff',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => {'unexpected': 'value'});

      final result = await syncService.fetchDiff([]);

      expect(result.succeeded, isFalse);
      expect(result.failure?.kind, NotificationSyncFailureKind.parse);
    });

    test('fetchDiff informa error de red sin propagar excepciones', () async {
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/notifications/diff',
          data: any(named: 'data'),
        ),
      ).thenThrow(Exception('network error'));

      final result = await syncService.fetchDiff([1, 2]);

      expect(result.notifications, isEmpty);
      expect(result.failure?.kind, NotificationSyncFailureKind.network);
    });

    test('clasifica un 401 como no autorizado', () async {
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/notifications/diff',
          data: any(named: 'data'),
        ),
      ).thenThrow(const ServerFailure('No autorizado', statusCode: 401));

      final result = await syncService.fetchDiff([]);

      expect(result.failure?.kind, NotificationSyncFailureKind.unauthorized);
    });
  });
}
