import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../providers/children_provider.dart';
import 'child_qr_screen.dart';

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
    final children = ref.watch(childrenProvider);

    final child = children.firstWhere(
      (c) => c.id == widget.childId,
      orElse: () => const Child(
        id: '',
        name: 'Estudiante no encontrado',
        grade: '',
        group: '',
        avatarUrl: '',
        status: 'outside',
        lastEventText: '',
        events: [],
      ),
    );

    if (child.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(child: Text('Estudiante no encontrado.')),
      );
    }

    final isInside = child.status == 'inside';
    final firstName = child.name.split(' ').first;
    final initials = child.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    // Compute stats from events
    final todayEntries = child.events
        .where((e) => e.type == 'entry' && e.date.startsWith('Hoy'))
        .length;
    final todayExits = child.events
        .where((e) => e.type == 'exit' && e.date.startsWith('Hoy'))
        .length;

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChildQrScreen(child: child),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Navy Header ────────────────────────────────────────────────
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
                  // Big CircleAvatar with gold initials
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

                  // Child full name
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

                  // Grade & Group
                  Text(
                    '${child.grade} • Grupo ${child.group}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatCell(
                        label: 'Entradas hoy',
                        value: '$todayEntries',
                        icon: Icons.login_rounded,
                        iconColor: AppTheme.successColor,
                      ),
                      _Divider(),
                      _StatCell(
                        label: 'Salidas hoy',
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
                        iconColor:
                            isInside ? AppTheme.successColor : Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Filter Chips ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final selected = _selectedFilter == i;
                  return Padding(
                    padding: EdgeInsets.only(right: i < _filters.length - 1 ? 10 : 0),
                    child: ChoiceChip(
                      label: Text(
                        _filters[i],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppTheme.primaryColor,
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
                      onSelected: (_) => setState(() => _selectedFilter = i),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // ── Timeline Section Title ─────────────────────────────────────
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

            // ── Timeline Events ────────────────────────────────────────────
            if (child.events.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text('No hay eventos registrados recientemente.'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: child.events.length,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemBuilder: (context, index) {
                  final event = child.events[index];
                  return _TimelineEventTile(
                    event: event,
                    isLast: index == child.events.length - 1,
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

// ── Stat Cell Widget ──────────────────────────────────────────────────────────
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

// ── Vertical Divider ──────────────────────────────────────────────────────────
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

// ── Timeline Event Tile ───────────────────────────────────────────────────────
class _TimelineEventTile extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineEventTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    Color eventColor;
    IconData eventIcon;
    String badgeLabel;

    switch (event.type) {
      case 'entry':
        eventColor = AppTheme.successColor;
        eventIcon = Icons.login_rounded;
        badgeLabel = 'Entrada';
        break;
      case 'exit':
        eventColor = Colors.orange;
        eventIcon = Icons.logout_rounded;
        badgeLabel = 'Salida';
        break;
      default:
        eventColor = AppTheme.errorColor;
        eventIcon = Icons.warning_amber_rounded;
        badgeLabel = 'Alerta';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + connector line
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
              Container(
                width: 2,
                height: 54,
                color: AppTheme.borderLightColor,
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Event card
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
                    // Badge pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
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
                    // Time
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
                const SizedBox(height: 3),
                Text(
                  event.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.date,
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
