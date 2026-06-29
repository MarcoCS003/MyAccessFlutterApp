/// Estadísticas de notificaciones calculadas localmente desde Hive.
class TeacherStats {
  final int todayCount;
  final int weekCount;
  final int totalCount;

  const TeacherStats({
    this.todayCount = 0,
    this.weekCount = 0,
    this.totalCount = 0,
  });

  TeacherStats copyWith({
    int? todayCount,
    int? weekCount,
    int? totalCount,
  }) {
    return TeacherStats(
      todayCount: todayCount ?? this.todayCount,
      weekCount: weekCount ?? this.weekCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}
