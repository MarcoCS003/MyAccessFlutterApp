import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/failures.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  ApiService({Dio? dio, FlutterSecureStorage? secureStorage})
    : _dio = dio ?? _createDio(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    // Solo agregamos el interceptor al Dio interno. Si un Dio es inyectado
    // (por ejemplo en tests), se asume que el llamador maneja la autenticación.
    if (dio == null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (options.extra['requiresAuth'] != false) {
              final token = await _secureStorage.read(
                key: AppConstants.jwtTokenKey,
              );
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }

    return dio;
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _handleRequest(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      ),
    );
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    bool requiresAuth = true,
  }) async {
    return _handleRequest(
      () => _dio.post<T>(
        path,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      ),
    );
  }

  Future<T> delete<T>(
    String path, {
    dynamic data,
    bool requiresAuth = true,
  }) async {
    return _handleRequest(
      () => _dio.delete<T>(
        path,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      ),
    );
  }

  Future<T> _handleRequest<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ServerFailure('Error inesperado: ${e.toString()}');
    }
  }

  Failure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkFailure('Tiempo de espera agotado');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const NetworkFailure('Error de conexión. Verifica tu red.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = _extractMessage(e.response?.data);
        return ServerFailure(message, statusCode: statusCode);
      case DioExceptionType.cancel:
        return const NetworkFailure('Solicitud cancelada');
      case DioExceptionType.badCertificate:
        return const NetworkFailure('Error de certificado SSL');
    }
  }

  String _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) {
        return data['message'];
      }
      if (data['error'] is String) {
        return data['error'];
      }
    }
    return 'Error en el servidor';
  }
}
