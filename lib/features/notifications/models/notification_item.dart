class NotificationItem {
  final String id;
  final String type;
  final String event;
  final String studentName;
  final int studentId;
  final DateTime timestamp;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.event,
    required this.studentName,
    required this.studentId,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? type,
    String? event,
    String? studentName,
    int? studentId,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      event: event ?? this.event,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationItem.fromFcm(Map<String, dynamic> data) {
    return NotificationItem(
      id: '${data['student_id']}_${data['event']}_${data['timestamp']}',
      type: data['type'] ?? 'attendance',
      event: data['event'] ?? 'check_in',
      studentName: data['student_name'] ?? 'Alumno',
      studentId: int.tryParse(data['student_id']?.toString() ?? '0') ?? 0,
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'event': event,
      'studentName': studentName,
      'studentId': studentId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: json['type'] as String,
      event: json['event'] as String,
      studentName: json['studentName'] as String,
      studentId: json['studentId'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
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
