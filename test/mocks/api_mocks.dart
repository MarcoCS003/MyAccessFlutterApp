import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeRequestOptions extends Fake implements RequestOptions {}

/// Configura un [MockDio] para que su propiedad [options] no sea nula,
/// evitando errores cuando [ApiService] muta headers en el Dio autenticado.
void configureMockDioOptions(MockDio mockDio) {
  when(() => mockDio.options).thenReturn(BaseOptions());
}
