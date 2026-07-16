import 'package:intl/intl.dart';

class TimelineEvent {
  final int id;
  final String type;
  final DateTime recordedAt;
  final String? location;
  final int? studentId;

  const TimelineEvent({
    required this.id,
    required this.type,
    required this.recordedAt,
    this.location,
    this.studentId,
  });

  String get title =>
      type == 'check_in' ? 'Entrada registrada' : 'Salida registrada';
  String get time => DateFormat('HH:mm').format(recordedAt);
  String get date => DateFormat('EEE, d MMM', 'es').format(recordedAt);

  TimelineEvent copyWith({
    int? id,
    String? type,
    DateTime? recordedAt,
    String? location,
    int? studentId,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      recordedAt: recordedAt ?? this.recordedAt,
      location: location ?? this.location,
      studentId: studentId ?? this.studentId,
    );
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] as int,
      type: json['type'] as String,
      recordedAt: DateTime.parse(
        json['recorded_at'] as String? ?? json['created_at'] as String,
      ),
      location: json['location'] as String?,
      studentId: json['student_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'recorded_at': recordedAt.toIso8601String(),
      'location': location,
      'student_id': studentId,
    };
  }
}
