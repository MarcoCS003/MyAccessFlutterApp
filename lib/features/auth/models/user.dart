/// Roles que entran a la app como "tipo maestro" (home maestro + QR).
/// Cualquier otro rol distinto de `parent` que no esté aquí (student, user)
/// se ignora y mantiene el comportamiento previo.
const staffRoles = {'teacher', 'admin', 'root'};

class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String role;

  /// El backend obliga a cambiar la contraseña antes de usar la app
  /// (maestros creados con contraseña por defecto). Usuarios cacheados de
  /// versiones anteriores no traen la key → false.
  final bool mustChangePassword;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
    this.mustChangePassword = false,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    String? role,
    bool? mustChangePassword,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
      'must_change_password': mustChangePassword,
    };
  }

  bool get isTeacher => staffRoles.contains(role);
  bool get isParent => role == 'parent';
}
