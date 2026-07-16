import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(AuthState initialState)
    : super(
        skipInitialCheck: true,
        firebaseAuth: MockFirebaseAuth(),
        googleSignIn: MockGoogleSignIn(),
        firebaseMessaging: MockFirebaseMessaging(),
        secureStorage: MockFlutterSecureStorage(),
      ) {
    state = initialState;
  }
}
