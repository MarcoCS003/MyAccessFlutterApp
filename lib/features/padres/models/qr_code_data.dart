import 'dart:convert';

/// Representa los datos decodificados de un QR escaneado.
///
/// El backend genera QR con el formato:
/// `{"idS": "0", "personId": "<qr_code>", "type": "student"}`
/// donde `personId` es la referencia bancaria/qr_code del estudiante.
class QrCodeData {
  final int? id;
  final String reference;
  final String type;

  const QrCodeData({this.id, required this.reference, this.type = 'student'});

  bool get isStudent => type == 'student';

  factory QrCodeData.fromCode(String code) {
    final trimmed = code.trim();

    try {
      final decoded = jsonDecode(trimmed) as Map<String, dynamic>?;
      if (decoded != null) {
        final idS = decoded['idS'];
        final personId = decoded['personId']?.toString() ?? '';
        final type = decoded['type']?.toString() ?? 'student';

        return QrCodeData(
          id: idS != null && idS.toString() != '0'
              ? int.tryParse(idS.toString())
              : null,
          reference: personId.isNotEmpty ? personId : trimmed,
          type: type,
        );
      }
    } catch (_) {
      // No era JSON; usamos el valor crudo como referencia.
    }

    return QrCodeData(reference: trimmed);
  }
}
