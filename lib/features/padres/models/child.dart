class Child {
  final int id;
  final String name;
  final String grade;
  final String group;
  final String? avatar;
  final String status;
  final String? qrCode;
  final String? lastEvent;
  final DateTime? lastEventTime;

  const Child({
    required this.id,
    required this.name,
    required this.grade,
    required this.group,
    this.avatar,
    this.status = 'outside',
    this.qrCode,
    this.lastEvent,
    this.lastEventTime,
  });

  Child copyWith({
    int? id,
    String? name,
    String? grade,
    String? group,
    String? avatar,
    String? status,
    String? qrCode,
    String? lastEvent,
    DateTime? lastEventTime,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      group: group ?? this.group,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      lastEvent: lastEvent ?? this.lastEvent,
      lastEventTime: lastEventTime ?? this.lastEventTime,
    );
  }

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as int,
      name: json['nombre'] as String? ?? json['name'] as String,
      grade:
          json['grado'] as String? ??
          json['nivel'] as String? ??
          json['grade'] as String? ??
          '',
      group: json['grupo'] as String? ?? json['group'] as String? ?? '',
      avatar: json['avatar'] as String?,
      status: json['status'] as String? ?? 'outside',
      qrCode: json['qr_code'] as String?,
      lastEvent: json['last_event'] as String?,
      lastEventTime: json['last_event_time'] != null
          ? DateTime.parse(json['last_event_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'grado': grade,
      'grupo': group,
      'avatar': avatar,
      'status': status,
      'qr_code': qrCode,
      'last_event': lastEvent,
      'last_event_time': lastEventTime?.toIso8601String(),
    };
  }
}
