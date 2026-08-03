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
    test(
      'loadChildren carga hijos desde backend y los guarda en Hive',
      () async {
        final mockDio = MockDio();
        configureMockDioOptions(mockDio);
        final mockStorage = MockFlutterSecureStorage();

        when(
          () => mockStorage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => 'test_token');

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

        final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
        final notifier = ChildrenNotifier(
          apiService: apiService,
          userKey: 'padre@ijl.edu.mx',
        );

        await notifier.loadChildren();

        expect(notifier.state.hasValue, isTrue);
        expect(notifier.state.value!.length, 1);
        expect(notifier.state.value!.first.name, 'Juan Pérez');
      },
    );

    test('linkChild agrega el nuevo hijo a la lista', () async {
      final mockDio = MockDio();
      configureMockDioOptions(mockDio);
      final mockStorage = MockFlutterSecureStorage();

      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'test_token');

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

      final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
      final notifier = ChildrenNotifier(
        apiService: apiService,
        userKey: 'padre@ijl.edu.mx',
      );
      notifier.state = const AsyncValue.data([]);

      await notifier.linkChild('ABC123');

      expect(notifier.state.value!.length, 1);
      expect(notifier.state.value!.first.name, 'Ana López');
    });

    test('el caché de hijos está aislado por userKey', () async {
      const keyA = 'a@ijl.edu.mx';
      const keyB = 'b@ijl.edu.mx';

      ApiService okApi() {
        final mockDio = MockDio();
        configureMockDioOptions(mockDio);
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
                  'name': 'Hijo de A',
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
        return ApiService(dio: mockDio);
      }

      // API que simula estar sin red.
      ApiService failingApi() {
        final mockDio = MockDio();
        configureMockDioOptions(mockDio);
        when(
          () => mockDio.get(
            '/user',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/user'),
            type: DioExceptionType.connectionError,
          ),
        );
        return ApiService(dio: mockDio);
      }

      // A guarda su roster en Hive vía un loadChildren exitoso.
      final notifierA = ChildrenNotifier(apiService: okApi(), userKey: keyA);
      await notifierA.loadChildren();
      expect(notifierA.state.value!.first.name, 'Hijo de A');

      // B sin red NO debe ver el caché de A: queda en error.
      final notifierB = ChildrenNotifier(
        apiService: failingApi(),
        userKey: keyB,
      );
      await notifierB.loadChildren();
      expect(notifierB.state.hasValue, isFalse);
      expect(notifierB.state.hasError, isTrue);

      // A sin red SÍ recupera su propio caché.
      final notifierA2 = ChildrenNotifier(
        apiService: failingApi(),
        userKey: keyA,
      );
      await notifierA2.loadChildren();
      expect(notifierA2.state.value!.first.name, 'Hijo de A');
    });
  });
}
