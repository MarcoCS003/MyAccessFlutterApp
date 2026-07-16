import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/features/home/screens/main_navigation_screen.dart';
import 'package:cliente_flutter_myaccess/features/padres/screens/home_padre_screen.dart';
import 'package:cliente_flutter_myaccess/features/maestros/screens/home_maestro_screen.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';

import 'mocks/auth_mocks.dart';
import 'test_helpers.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    if (invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return null;
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #headers) {
      return _MockHttpHeaders();
    }
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return null;
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #statusCode) {
      return 200;
    }
    if (invocation.memberName == #contentLength) {
      return _transparentImage.length;
    }
    if (invocation.memberName == #headers) {
      return _MockHttpHeaders();
    }
    if (invocation.memberName == #compressionState) {
      return HttpClientResponseCompressionState.notCompressed;
    }
    return null;
  }
}

final List<int> _transparentImage = [
  0x47,
  0x49,
  0x46,
  0x38,
  0x39,
  0x61,
  0x01,
  0x00,
  0x01,
  0x00,
  0x80,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0xff,
  0xff,
  0xff,
  0x21,
  0xf9,
  0x04,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x2c,
  0x00,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x01,
  0x00,
  0x00,
  0x02,
  0x02,
  0x44,
  0x01,
  0x00,
  0x3b,
];

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides();
    await initializeTestHive();
  });

  testWidgets('MainNavigationScreen debe mostrar BottomNavigationBar', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => MockAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: User(
                  id: 1,
                  name: 'Juan Perez',
                  email: 'juan@ijl.mx',
                  role: 'parent',
                ),
              ),
            ),
          ),
          emptyChildrenProviderOverride,
        ],
        child: const MaterialApp(home: MainNavigationScreen()),
      ),
    );
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('MainNavigationScreen en rol Padre muestra HomePadreScreen', (
    tester,
  ) async {
    final parentState = AuthState(
      status: AuthStatus.authenticated,
      user: User(
        id: 1,
        name: 'Juan Perez',
        email: 'juan@ijl.mx',
        role: 'parent',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(parentState)),
          emptyChildrenProviderOverride,
        ],
        child: const MaterialApp(home: MainNavigationScreen()),
      ),
    );

    expect(find.byType(HomePadreScreen), findsOneWidget);
  });

  testWidgets('MainNavigationScreen en rol Docente muestra HomeMaestroScreen', (
    tester,
  ) async {
    final teacherState = AuthState(
      status: AuthStatus.authenticated,
      user: User(
        id: 2,
        name: 'Prof. Carlos',
        email: 'carlos@ijl.mx',
        role: 'teacher',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(teacherState)),
          emptyChildrenProviderOverride,
        ],
        child: const MaterialApp(home: MainNavigationScreen()),
      ),
    );

    expect(find.byType(HomeMaestroScreen), findsOneWidget);
  });
}
