/// Roles que entran a la app como "tipo maestro" (home maestro + QR).
/// Cualquier otro rol distinto de `parent` que no esté aquí (student, user)
/// se ignora y mantiene el comportamiento previo.
const staffRoles = {'teacher', 'admin', 'root'};

/// Vínculo opcional del usuario con su registro de maestro (cuando
/// `users.teacher_id` apunta a un `teachers.id`). La app usa
/// `User.teacher?.qrCode` para construir el QR del maestro con el formato
/// oficial que esperan el checador y `POST /vincular-maestro`.
///
/// Solo viene cargado en respuestas de `GET /api/user` (el closure del
/// endpoint hace `$user->load('teacher:id,qr_code')`); `/auth/login`,
/// `/auth/register` y `/auth/change-password` devuelven `teacher: null` y la
/// app debe llamar `refreshUser()` para rellenarlo.
class UserTeacher {
  final int id;
  final String? qrCode;

  const UserTeacher({required this.id, this.qrCode});

  factory UserTeacher.fromJson(Map<String, dynamic> json) {
    return UserTeacher(
      id: json['id'] as int,
      qrCode: json['qr_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'qr_code': qrCode};
  }

  UserTeacher copyWith({int? id, String? qrCode}) {
    return UserTeacher(id: id ?? this.id, qrCode: qrCode ?? this.qrCode);
  }
}

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

  /// Vínculo opcional con el registro de maestro. Null si el usuario nunca
  /// fue enlazado, si la sesión se cacheó antes de que el backend expusiera
  /// esta relación, o si el endpoint que generó el JSON no la carga.
  final UserTeacher? teacher;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
    this.mustChangePassword = false,
    this.teacher,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    String? role,
    bool? mustChangePassword,
    UserTeacher? teacher,
    bool clearTeacher = false,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      teacher: clearTeacher ? null : (teacher ?? this.teacher),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final teacherRaw = json['teacher'];
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      teacher: teacherRaw is Map<String, dynamic>
          ? UserTeacher.fromJson(teacherRaw)
          : null,
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
      'teacher': teacher?.toJson(),
    };
  }

  bool get isTeacher => staffRoles.contains(role);
  bool get isParent => role == 'parent';
}