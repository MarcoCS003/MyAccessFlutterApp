import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../models/child.dart';
import '../models/timeline_event.dart';
import '../providers/children_provider.dart';

class ChildDetailScreen extends ConsumerStatefulWidget {
  final String childId;

  const ChildDetailScreen({super.key, required this.childId});

  @override
  ConsumerState<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends ConsumerState<ChildDetailScreen> {
  int _selectedFilter = 0; // 0 = Hoy, 1 = Semana, 2 = Mes
  final List<String> _filters = ['Hoy', 'Semana', 'Mes'];

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);

    return childrenAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (children) {
        final childId = int.tryParse(widget.childId);
        final child = children.firstWhere(
          (c) => c.id == childId,
          orElse: () => Child(
            id: -1,
            name: 'Estudiante no encontrado',
            grade: '',
            group: '',
          ),
        );

        if (child.id == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle')),
            body: const Center(child: Text('Estudiante no encontrado.')),
          );
        }

        return _ChildDetailContent(
          child: child,
          selectedFilter: _selectedFilter,
          filters: _filters,
          onFilterChanged: (index) => setState(() => _selectedFilter = index),
        );
      },
    );
  }
}

class _ChildDetailContent extends ConsumerWidget {
  final Child child;
  final int selectedFilter;
  final List<String> filters;
  final ValueChanged<int> onFilterChanged;

  const _ChildDetailContent({
    required this.child,
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
  });

  List<TimelineEvent> _filterEvents(List<TimelineEvent> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return events.where((event) {
      final date = DateTime(
        event.recordedAt.year,
        event.recordedAt.month,
        event.recordedAt.day,
      );
      switch (selectedFilter) {
        case 0: // Hoy
          return date.isAtSameMomentAs(today);
        case 1: // Semana
          return date.isAfter(today.subtract(const Duration(days: 7))) ||
              date.isAtSameMomentAs(today);
        case 2: // Mes
          return date.isAfter(today.subtract(const Duration(days: 30))) ||
              date.isAtSameMomentAs(today);
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(childTimelineProvider(child.id));
    final isInside = child.status == 'inside';
    final firstName = child.name.split(' ').first;
    final initials = child.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: AppTheme.bgLightColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          firstName,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
            tooltip: 'Ver QR',
            onPressed: () => context.push('/child/${child.id}/qr'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
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
                    radius: 48,
                    backgroundColor: AppTheme.lightGoldColor,
                    child: Text(
                      initials,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGoldColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    child.name,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${child.grade} • Grupo ${child.group}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  timelineAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (e, _) => Text(
                      'No se pudo cargar el historial',
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                    data: (events) {
                      final filtered = _filterEvents(events);
                      final todayEntries = filtered
                          .where((e) => e.type == 'check_in')
                          .length;
                      final todayExits = filtered
                          .where((e) => e.type == 'check_out')
                          .length;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatCell(
                            label: 'Entradas',
                            value: '$todayEntries',
                            icon: Icons.login_rounded,
                            iconColor: AppTheme.successColor,
                          ),
                          _Divider(),
                          _StatCell(
                            label: 'Salidas',
                            value: '$todayExits',
                            icon: Icons.logout_rounded,
                            iconColor: Colors.orangeAccent,
                          ),
                          _Divider(),
                          _StatCell(
                            label: 'Estado',
                            value: isInside ? 'Dentro' : 'Fuera',
                            icon: isInside
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            iconColor: isInside
                                ? AppTheme.successColor
                                : Colors.grey,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(filters.length, (i) {
                  final selected = selectedFilter == i;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: i < filters.length - 1 ? 10 : 0,
                    ),
                    child: ChoiceChip(
                      label: Text(
                        filters[i],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppTheme.primaryColor,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.borderLightColor,
                        ),
                      ),
                      showCheckmark: false,
                      onSelected: (_) => onFilterChanged(i),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Historial de accesos',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            timelineAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(child: Text('Error: $e')),
              ),
              data: (events) {
                final filtered = _filterEvents(events);
                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No hay eventos registrados para este período.',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  itemBuilder: (context, index) {
                    final event = filtered[index];
                    return _TimelineEventTile(
                      event: event,
                      isLast: index == filtered.length - 1,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _TimelineEventTile extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineEventTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isEntry = event.type == 'check_in';
    final eventColor = isEntry ? AppTheme.successColor : Colors.orange;
    final eventIcon = isEntry ? Icons.login_rounded : Icons.logout_rounded;
    final badgeLabel = isEntry ? 'Entrada' : 'Salida';
    final dateLabel = DateFormat('EEE, d MMM', 'es').format(event.recordedAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: eventColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(eventIcon, color: eventColor, size: 18),
            ),
            if (!isLast)
              Container(width: 2, height: 54, color: AppTheme.borderLightColor),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLightColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: eventColor,
                        ),
                      ),
                    ),
                    Text(
                      event.time,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (event.location != null && event.location!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.location!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  dateLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
