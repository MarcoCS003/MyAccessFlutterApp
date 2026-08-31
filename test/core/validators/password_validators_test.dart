import 'package:flutter_test/flutter_test.dart';
import 'package:cliente_flutter_myaccess/core/validators/password_validators.dart';

void main() {
  group('validatePassword', () {
    test('vacía o nula', () {
      expect(validatePassword(null), isNotNull);
      expect(validatePassword(''), isNotNull);
    });

    test('menos de 12 caracteres', () {
      expect(validatePassword('Abc123!'), isNotNull);
    });

    test('sin mayúscula', () {
      expect(validatePassword('abcdefgh1234!'), isNotNull);
    });

    test('sin minúscula', () {
      expect(validatePassword('ABCDEFGH1234!'), isNotNull);
    });

    test('sin número', () {
      expect(validatePassword('Abcdefghijk!'), isNotNull);
    });

    test('sin símbolo', () {
      expect(validatePassword('Abcdefgh1234'), isNotNull);
    });

    test('válida con todas las reglas', () {
      expect(validatePassword('Abcdefgh1234!'), isNull);
      expect(validatePassword('@qwerty1234A'), isNull);
    });
  });
}
