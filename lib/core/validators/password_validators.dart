/// Validación de contraseñas compartida por registro, restablecimiento y
/// cambio forzado. Replica las reglas que el backend exige en producción
/// (`Password::min(8)->mixedCase()->letters()->numbers()->symbols()`; el
/// backend además verifica `uncompromised()`, que solo puede validar él).
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Ingresa una contraseña';
  }
  if (value.length < 8) {
    return 'Mínimo 8 caracteres';
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Debe incluir al menos una mayúscula';
  }
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Debe incluir al menos una minúscula';
  }
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Debe incluir al menos un número';
  }
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
    return 'Debe incluir al menos un símbolo';
  }
  return null;
}
