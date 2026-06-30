import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_flutter_myaccess/features/padres/providers/children_provider.dart';
import 'package:cliente_flutter_myaccess/services/api_service.dart';

import '../../mocks/api_mocks.dart';
import '../../test_helpers.dart';

void main() {
  setUp(() async {
    await initializeTestHive();
    registerFallbackValue(FakeRequestOptions());
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  group('ChildrenNotifier', () {
    test('loadChildren carga hijos desde backend y los guarda en Hive',
        () async {
      final mockDio = MockDio();
      configureMockDioOptions(mockDio);
      final mockStorage = MockFlutterSecureStorage();

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'test_token');

      when(
        () => mockDio.get(
          '/user',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'students': [
              {
                'id': 1,
                'name': 'Juan Pérez',
                'grade': '3ro Primaria',
                'group': 'A',
                'status': 'inside',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/user'),
        ),
      );

      final apiService = ApiService(
        dio: mockDio,
        secureStorage: mockStorage,
      );
      final notifier = ChildrenNotifier(
        apiService: apiService,
      );

      await notifier.loadChildren();

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.value!.length, 1);
      expect(notifier.state.value!.first.name, 'Juan Pérez');
    });

    test('linkChild agrega el nuevo hijo a la lista', () async {
      final mockDio = MockDio();
      configureMockDioOptions(mockDio);
      final mockStorage = MockFlutterSecureStorage();

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'test_token');

      when(
        () => mockDio.post(
          '/vincular-alumno',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'message': 'Alumno vinculado exitosamente'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/vincular-alumno'),
        ),
      );

      when(
        () => mockDio.get(
          '/user',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'students': [
              {
                'id': 2,
                'name': 'Ana López',
                'grade': '2do Primaria',
                'group': 'B',
                'status': 'outside',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/user'),
        ),
      );

      final apiService = ApiService(
        dio: mockDio,
        secureStorage: mockStorage,
      );
      final notifier = ChildrenNotifier(
        apiService: apiService,
      );
      notifier.state = const AsyncValue.data([]);

      await notifier.linkChild('ABC123');

      expect(notifier.state.value!.length, 1);
      expect(notifier.state.value!.first.name, 'Ana López');
    });
  });
}
