class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
    };
  }

  bool get isTeacher => role == 'teacher';
  bool get isParent => role == 'parent';
}
