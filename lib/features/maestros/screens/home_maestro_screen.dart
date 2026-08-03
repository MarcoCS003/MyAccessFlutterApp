import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/models/notification_item.dart';
import '../providers/teacher_provider.dart';

/// Período seleccionado en las stat cards del home del maestro.
enum _TimeFilter { today, week, month }

class HomeMaestroScreen extends ConsumerStatefulWidget {
  const HomeMaestroScreen({super.key});

  @override
  ConsumerState<HomeMaestroScreen> createState() => _HomeMaestroScreenState();
}

class _HomeMaestroScreenState extends ConsumerState<HomeMaestroScreen> {
  _TimeFilter _filter = _TimeFilter.today;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final teacherState = ref.watch(teacherProvider);
    final user = authState.user;

    final fullName = user?.name ?? 'Profesor IJL';
    final firstName = fullName.split(' ').first;
    final initials = fullName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: AppTheme.bgLightColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'MyAccess Maestro',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppTheme.lightGoldColor,
                      child: Text(
                        initials,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGoldColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGoldColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'MAESTRO',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Hola, Profe $firstName',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Estadísticas (filtros de período) ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Resumen de notificaciones',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Hoy',
                        value: '${teacherState.stats.todayCount}',
                        icon: Icons.today_rounded,
                        iconColor: AppTheme.successColor,
                        selected: _filter == _TimeFilter.today,
                        onTap: () =>
                            setState(() => _filter = _TimeFilter.today),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Semana',
                        value: '${teacherState.stats.weekCount}',
                        icon: Icons.date_range_rounded,
                        iconColor: AppTheme.themeNavyColor,
                        selected: _filter == _TimeFilter.week,
                        onTap: () => setState(() => _filter = _TimeFilter.week),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Mes',
                        value: '${teacherState.stats.monthCount}',
                        icon: Icons.calendar_month_rounded,
                        iconColor: AppTheme.accentGoldColor,
                        selected: _filter == _TimeFilter.month,
                        onTap: () =>
                            setState(() => _filter = _TimeFilter.month),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Registros del período seleccionado ────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _listTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ..._buildRecords(teacherState.notifications),
            ],
          ),
        ),
      ),
    );
  }

  String get _listTitle {
    switch (_filter) {
      case _TimeFilter.today:
        return 'Notificaciones de hoy';
      case _TimeFilter.week:
        return 'Notificaciones de la semana';
      case _TimeFilter.month:
        return 'Notificaciones del mes';
    }
  }

  List<Widget> _buildRecords(List<NotificationItem> notifications) {
    switch (_filter) {
      case _TimeFilter.today:
        return _buildTodayRecords(notifications);
      case _TimeFilter.week:
        return _buildWeekRecords(notifications);
      case _TimeFilter.month:
        return _buildMonthRecords(notifications);
    }
  }

  /// Hoy: registros de hoy; si hoy no hay ninguno, los del último día con
  /// registros.
  List<Widget> _buildTodayRecords(List<NotificationItem> notifications) {
    if (notifications.isEmpty) {
      return const [_EmptyRecordsSection(filter: _TimeFilter.today)];
    }
    final byDay = _groupByDay(notifications);
    final today = _dateOnly(DateTime.now());
    // byDay conserva el orden descendente: la primera llave es el día más
    // reciente con registros.
    final day = byDay.containsKey(today) ? today : byDay.keys.first;
    return _buildDaySections({day: byDay[day]!});
  }

  /// Semana actual (lunes–domingo), agrupada por día del más reciente al más
  /// antiguo.
  List<Widget> _buildWeekRecords(List<NotificationItem> notifications) {
    final weekStart = teacherWeekStart(DateTime.now());
    final items = notifications
        .where((n) => !_dateOnly(n.timestamp).isBefore(weekStart))
        .toList();
    if (items.isEmpty) {
      return const [_EmptyRecordsSection(filter: _TimeFilter.week)];
    }
    return _buildDaySections(_groupByDay(items));
  }

  /// Mes calendario actual, agrupado en semanas expandibles; dentro de cada
  /// semana, grupos por día.
  List<Widget> _buildMonthRecords(List<NotificationItem> notifications) {
    final now = DateTime.now();
    final items = notifications
        .where(
          (n) => n.timestamp.year == now.year && n.timestamp.month == now.month,
        )
        .toList();
    if (items.isEmpty) {
      return const [_EmptyRecordsSection(filter: _TimeFilter.month)];
    }

    final currentWeek = teacherWeekStart(now);
    final byWeek = <DateTime, List<NotificationItem>>{};
    for (final notification in items) {
      byWeek
          .putIfAbsent(teacherWeekStart(notification.timestamp), () => [])
          .add(notification);
    }

    return byWeek.entries.map((entry) {
      final isCurrentWeek = entry.key.isAtSameMomentAs(currentWeek);
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLightColor),
        ),
        child: ExpansionTile(
          initiallyExpanded: isCurrentWeek,
          title: Text(
            _weekLabel(entry.key),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          children: _buildDaySections(_groupByDay(entry.value)),
        ),
      );
    }).toList();
  }

  /// Etiqueta de una semana: "semana 7 – 13 julio 2026" o, si cruza de mes,
  /// "semana 29 junio – 3 julio 2026".
  String _weekLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (weekStart.month == weekEnd.month && weekStart.year == weekEnd.year) {
      return 'semana ${weekStart.day} – ${DateFormat('d MMMM y', 'es').format(weekEnd)}';
    }
    return 'semana ${DateFormat('d MMMM', 'es').format(weekStart)} – ${DateFormat('d MMMM y', 'es').format(weekEnd)}';
  }

  /// Encabezado de fecha + timeline por cada día, en el orden del mapa (que
  /// llega ya ordenado del día más reciente al más antiguo).
  List<Widget> _buildDaySections(Map<DateTime, List<NotificationItem>> byDay) {
    final totalTiles = byDay.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    var tileIndex = 0;
    final widgets = <Widget>[];
    for (final entry in byDay.entries) {
      widgets.add(_DayHeader(date: entry.key));
      for (final notification in entry.value) {
        tileIndex++;
        widgets.add(
          _AttendanceTile(
            notification: notification,
            isLast: tileIndex == totalTiles,
          ),
        );
      }
    }
    return widgets;
  }

  /// Agrupa por día conservando el orden de la lista (más reciente primero).
  Map<DateTime, List<NotificationItem>> _groupByDay(
    List<NotificationItem> notifications,
  ) {
    final byDay = <DateTime, List<NotificationItem>>{};
    for (final notification in notifications) {
      byDay
          .putIfAbsent(_dateOnly(notification.timestamp), () => [])
          .add(notification);
    }
    return byDay;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primaryColor.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor
                  : AppTheme.borderLightColor,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;

  const _DayHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Text(
        DateFormat("EEEE, d 'de' MMMM 'de' y", 'es').format(date),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondaryColor,
        ),
      ),
    );
  }
}

class _EmptyRecordsSection extends StatelessWidget {
  final _TimeFilter filter;

  const _EmptyRecordsSection({required this.filter});

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (filter) {
      _TimeFilter.today => (
        'Sin notificaciones hoy',
        'Cuando lleguen alertas de entrada o salida aparecerán aquí.',
      ),
      _TimeFilter.week => (
        'Sin notificaciones esta semana',
        'No hay registros de entrada o salida en la semana actual.',
      ),
      _TimeFilter.month => (
        'Sin notificaciones este mes',
        'No hay registros de entrada o salida en el mes actual.',
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLightColor),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppTheme.borderLightColor,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final NotificationItem notification;
  final bool isLast;

  const _AttendanceTile({required this.notification, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isEntry = notification.event == 'check_in';
    final color = isEntry ? AppTheme.successColor : AppTheme.textSecondaryColor;
    final icon = isEntry ? Icons.login_rounded : Icons.logout_rounded;
    final time =
        '${notification.timestamp.hour.toString().padLeft(2, '0')}:${notification.timestamp.minute.toString().padLeft(2, '0')}';
    // La hora ya aparece arriba a la derecha: el detalle no la repite.
    final detail = '${notification.studentName} ${isEntry ? 'entró' : 'salió'}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.borderLightColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 20, bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLightColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
