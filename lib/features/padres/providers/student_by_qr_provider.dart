import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_service.dart';
import '../models/child.dart';

/// Busca un estudiante por su código QR (`qr_code`) usando el endpoint
/// existente `/students`. Si no lo encuentra, devuelve `null`.
final studentByQrProvider = FutureProvider.family<Child?, String>((
  ref,
  code,
) async {
  final apiService = ApiService();
  final response = await apiService.get('/students');
  final data = response as Map<String, dynamic>;
  final students = data['data'] as List<dynamic>? ?? [];

  for (final item in students) {
    final student = item as Map<String, dynamic>;
    if (student['qr_code']?.toString() == code) {
      return Child.fromJson(student);
    }
  }

  return null;
});
