class NotificationItem {
  final String id;
  final int? backendId;
  final String type;
  final String event;
  final String studentName;
  final int studentId;
  final DateTime timestamp;
  final bool isRead;
  final String? location;

  const NotificationItem({
    required this.id,
    this.backendId,
    required this.type,
    required this.event,
    required this.studentName,
    required this.studentId,
    required this.timestamp,
    this.isRead = false,
    this.location,
  });

  NotificationItem copyWith({
    String? id,
    int? backendId,
    String? type,
    String? event,
    String? studentName,
    int? studentId,
    DateTime? timestamp,
    bool? isRead,
    String? location,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      backendId: backendId ?? this.backendId,
      type: type ?? this.type,
      event: event ?? this.event,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      location: location ?? this.location,
    );
  }

  /// El backend no siempre manda las claves canónicas (ver
  /// docs/reporte_notificaciones_fcm.md): el evento puede venir como
  /// `attendance_type: entry|exit` y la fecha como `recorded_at`. Se aceptan
  /// alias y el evento se normaliza a 'check_in'/'check_out', que es lo que
  /// la UI (ChildCard, timeline, contadores) espera.
  factory NotificationItem.fromFcm(Map<String, dynamic> data) {
    final eventRaw = _firstString(data, const [
      'event',
      'attendance_type',
      'event_type',
      'tipo',
    ]);
    final timestampRaw = _firstString(data, const [
      'timestamp',
      'recorded_at',
      'created_at',
    ]);
    final studentIdRaw = _firstString(data, const [
      'student_id',
      'studentId',
      'alumno_id',
    ]);

    return NotificationItem(
      // El id usa las cadenas crudas del payload: con las claves canónicas
      // genera los mismos ids de siempre y la deduplicación por id contra
      // lo ya guardado en Hive sigue funcionando.
      id: '${studentIdRaw}_${eventRaw ?? 'check_in'}_$timestampRaw',
      backendId: int.tryParse(_firstString(data, const ['notification_id']) ?? ''),
      type: data['type']?.toString() ?? 'attendance',
      event: _normalizeEvent(eventRaw),
      studentName:
          _firstString(data, const [
            'student_name',
            'studentName',
            'nombre',
            'name',
          ]) ??
          'Alumno',
      studentId: int.tryParse(studentIdRaw ?? '0') ?? 0,
      timestamp:
          DateTime.tryParse(timestampRaw ?? '')?.toLocal() ?? DateTime.now(),
      location: _firstString(data, const ['location', 'ubicacion']),
    );
  }

  /// Mapea la respuesta del endpoint `GET /api/notifications/sync`.
  factory NotificationItem.fromSyncApi(Map<String, dynamic> json) {
    final backendId = json['id'] as int?;
    final type = json['type']?.toString() ?? 'attendance';
    final event = json['event']?.toString() ?? 'check_in';
    final studentName = json['student_name']?.toString() ?? 'Alumno';
    final studentIdRaw =
        json['student_id']?.toString() ?? json['teacher_id']?.toString() ?? '0';
    final studentId = int.tryParse(studentIdRaw) ?? 0;
    final timestamp = DateTime.tryParse(json['timestamp']?.toString() ?? '')?.toLocal() ??
        DateTime.now();

    return NotificationItem(
      id: '${studentId}_${event}_${timestamp.toIso8601String()}',
      backendId: backendId,
      type: type,
      event: event,
      studentName: studentName,
      studentId: studentId,
      timestamp: timestamp,
    );
  }

  static String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static String _normalizeEvent(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'check_out':
      case 'exit':
      case 'salida':
        return 'check_out';
      default:
        return 'check_in';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'backendId': backendId,
      'type': type,
      'event': event,
      'studentName': studentName,
      'studentId': studentId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'location': location,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      backendId: json['backendId'] as int?,
      type: json['type'] as String,
      event: json['event'] as String,
      studentName: json['studentName'] as String,
      studentId: json['studentId'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      location: json['location'] as String?,
    );
  }

  String get title =>
      event == 'check_in' ? 'Entrada registrada' : 'Salida registrada';

  String get body =>
      '$studentName ${event == 'check_in' ? 'entró' : 'salió'} a las ${_formatTime(timestamp)}';

  static String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
