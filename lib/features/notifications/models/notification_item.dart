class NotificationItem {
  final String id;
  final int? backendId;

  /// Id del usuario destinatario (`user_id` en el payload FCM / sync).
  /// Permite enrutar la notificación al inbox de esa cuenta de forma
  /// exacta; null en payloads anteriores a este cambio (ruteo legado).
  final int? recipientUserId;
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
    this.recipientUserId,
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
    int? recipientUserId,
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
      recipientUserId: recipientUserId ?? this.recipientUserId,
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
    final studentIdRaw = _firstString(data, const [
      'student_id',
      'studentId',
      'alumno_id',
      'teacher_id',
    ]);
    final timestampRaw = _firstString(data, const [
      'timestamp',
      'recorded_at',
      'created_at',
    ]);
    final backendId = _parseInt(
      _firstValue(data, const ['notification_id', 'id']),
    );
    final timestamp = _parseTimestamp(timestampRaw);

    return NotificationItem(
      id: _localId(
        backendId: backendId,
        personId: studentIdRaw,
        event: eventRaw,
        timestamp: timestampRaw,
      ),
      backendId: backendId,
      recipientUserId: _parseInt(
        _firstValue(data, const ['user_id', 'userId']),
      ),
      type: data['type']?.toString() ?? 'attendance',
      event: _normalizeEvent(eventRaw),
      studentName:
          _firstString(data, const [
            'person_name',
            'student_name',
            'studentName',
            'nombre',
            'name',
          ]) ??
          'Alumno',
      studentId: int.tryParse(studentIdRaw ?? '0') ?? 0,
      timestamp: timestamp,
      location: _firstString(data, const ['location', 'ubicacion']),
    );
  }

  /// Variante segura para handlers FCM. Un payload sin fecha válida no debe
  /// inventar una hora ni llegar a persistirse.
  static NotificationItem? tryFromFcm(Map<String, dynamic> data) {
    try {
      return NotificationItem.fromFcm(data);
    } on FormatException {
      return null;
    }
  }

  /// Mapea la respuesta del endpoint `GET /api/notifications/sync`.
  factory NotificationItem.fromSyncApi(Map<String, dynamic> json) {
    final backendId = _parseInt(
      _firstValue(json, const ['id', 'notification_id']),
    );
    final type = json['type']?.toString() ?? 'attendance';
    final eventRaw = _firstString(json, const [
      'event',
      'attendance_type',
      'event_type',
      'tipo',
    ]);
    final event = _normalizeEvent(eventRaw);
    final studentName =
        _firstString(json, const [
          'person_name',
          'student_name',
          'studentName',
          'nombre',
          'name',
        ]) ??
        'Alumno';
    final studentIdRaw = _firstString(json, const [
      'student_id',
      'studentId',
      'teacher_id',
      'teacherId',
    ]);
    final studentId = int.tryParse(studentIdRaw ?? '') ?? 0;
    final timestampRaw = _firstString(json, const [
      'recorded_at',
      'timestamp',
      'created_at',
    ]);
    final timestamp = _parseTimestamp(timestampRaw);

    return NotificationItem(
      id: _localId(
        backendId: backendId,
        personId: studentIdRaw,
        event: eventRaw,
        timestamp: timestampRaw,
      ),
      backendId: backendId,
      recipientUserId: _parseInt(
        _firstValue(json, const ['user_id', 'userId']),
      ),
      type: type,
      event: event,
      studentName: studentName,
      studentId: studentId,
      timestamp: timestamp,
    );
  }

  static dynamic _firstValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) return value;
    }
    return null;
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

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime _parseTimestamp(String? raw) {
    final timestamp = DateTime.tryParse(raw ?? '')?.toLocal();
    if (timestamp == null) {
      throw const FormatException(
        'Notification timestamp is missing or invalid',
      );
    }
    return timestamp;
  }

  static String _localId({
    required int? backendId,
    required String? personId,
    required String? event,
    required String? timestamp,
  }) {
    if (backendId != null) return 'backend_$backendId';
    return '${personId ?? '0'}_${event ?? 'check_in'}_$timestamp';
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
      'recipientUserId': recipientUserId,
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
      backendId: _parseInt(json['backendId']),
      recipientUserId: _parseInt(json['recipientUserId']),
      type: json['type'] as String,
      event: json['event'] as String,
      studentName: json['studentName'] as String,
      studentId: _parseInt(json['studentId']) ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
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
