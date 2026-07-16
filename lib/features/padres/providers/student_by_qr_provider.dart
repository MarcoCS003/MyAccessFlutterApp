import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_service.dart';
import '../models/child.dart';

/// Busca un estudiante por el código QR escaneado.
///
/// La clave es un record `(int? id, String reference)` para garantizar
/// igualdad estructural y evitar que Riverpod dispare peticiones repetidas.
/// El QR puede contener JSON con `idS` y `personId`, o solo la referencia
/// (qr_code) plana. Se intenta primero por ID (`/students/{id}`) y, si no se
/// proporciona ID, se busca por referencia en la lista completa.
final studentByQrProvider = FutureProvider.family<Child?, ({int? id, String reference})>((
  ref,
  qrData,
) async {
  final apiService = ApiService();

  if (qrData.id != null) {
    try {
      final response = await apiService.get('/students/${qrData.id}');
      final data = response as Map<String, dynamic>?;
      if (data != null) {
        return Child.fromJson(data);
      }
    } catch (_) {
      // Si falla la búsqueda por ID, continuamos buscando por referencia.
    }
  }

  final response = await apiService.get('/students');
  final data = response as Map<String, dynamic>;
  final students = data['data'] as List<dynamic>? ?? [];

  for (final item in students) {
    final student = item as Map<String, dynamic>;
    if (student['qr_code']?.toString() == qrData.reference) {
      return Child.fromJson(student);
    }
  }

  return null;
});
