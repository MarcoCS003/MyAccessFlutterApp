import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../auth/providers/auth_provider.dart';


// ── Mock data per period ──────────────────────────────────────────────────────
const _mockStats = {
  'Semanal': {
    'entradas': '5',
    'salidas': '5',
    'retardos': '0',
    'puntualidad': '100%',
    'horasRegistradas': '40',
    'diasAsistidos': '5',
  },
  'Quincenal': {
    'entradas': '13',
    'salidas': '13',
    'retardos': '2',
    'puntualidad': '85%',
    'horasRegistradas': '104',
    'diasAsistidos': '13',
  },
  'Mensual': {
    'entradas': '21',
    'salidas': '20',
    'retardos': '3',
    'puntualidad': '88%',
    'horasRegistradas': '168',
    'diasAsistidos': '21',
  },
};

class HomeMaestroScreen extends ConsumerStatefulWidget {
  const HomeMaestroScreen({super.key});

  @override
  ConsumerState<HomeMaestroScreen> createState() => _HomeMaestroScreenState();
}

class _HomeMaestroScreenState extends ConsumerState<HomeMaestroScreen> {
  String _selectedPeriod = 'Semanal';

  final _historyItems = [
    {'type': 'Entrada', 'time': '07:30 AM', 'date': 'Hoy'},
    {'type': 'Salida', 'time': '--:-- PM', 'date': 'Hoy'},
    {'type': 'Entrada', 'time': '07:28 AM', 'date': 'Ayer'},
    {'type': 'Salida', 'time': '14:05 PM', 'date': 'Ayer'},
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final fullName = authState.user?.name ?? 'Profesor';
    final nameParts = fullName.split(' ');
    final firstName = nameParts.length > 1 ? nameParts[1] : nameParts[0];
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'
        : nameParts[0][0];

    final stats = _mockStats[_selectedPeriod]!;

    return Scaffold(
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.accentGoldColor,
              child: Text(
                initials.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Text(
                  'Hola, Profe $firstName 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  'Revisa tus estadísticas y usa el tab QR para mostrar tu código.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Estadísticas — Selector de período ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis estadísticas',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Period selector chips
                    Row(
                      children: ['Semanal', 'Quincenal', 'Mensual']
                          .map((period) => GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPeriod = period),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _selectedPeriod == period
                                        ? AppTheme.primaryColor
                                        : AppTheme.borderLightColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    period,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedPeriod == period
                                          ? Colors.white
                                          : AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Stats Grid (2×3) ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Entradas',
                            value: stats['entradas']!,
                            icon: Icons.login_rounded,
                            iconColor: AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Salidas',
                            value: stats['salidas']!,
                            icon: Icons.logout_rounded,
                            iconColor: AppTheme.themeNavyColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Retardos',
                            value: stats['retardos']!,
                            icon: Icons.access_time_rounded,
                            iconColor: AppTheme.accentGoldColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Puntualidad',
                            value: stats['puntualidad']!,
                            icon: Icons.verified_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Horas reg.',
                            value: stats['horasRegistradas']!,
                            icon: Icons.schedule_rounded,
                            iconColor: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Días asistidos',
                            value: stats['diasAsistidos']!,
                            icon: Icons.calendar_today_rounded,
                            iconColor: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Historial de hoy ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Historial de hoy',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._historyItems
                  .where((item) => item['date'] == 'Hoy')
                  .map((item) => _HistoryItem(
                        type: item['type']!,
                        time: item['time']!,
                      )),

              const SizedBox(height: 20),

              // ── Historial de ayer ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Ayer',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ..._historyItems
                  .where((item) => item['date'] == 'Ayer')
                  .map((item) => _HistoryItem(
                        type: item['type']!,
                        time: item['time']!,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Card Widget ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Item Widget ───────────────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  final String type;
  final String time;

  const _HistoryItem({required this.type, required this.time});

  @override
  Widget build(BuildContext context) {
    final isEntrada = type == 'Entrada';
    final color =
        isEntrada ? AppTheme.successColor : AppTheme.textSecondaryColor;
    final icon = isEntrada ? Icons.login_rounded : Icons.logout_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLightColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              type,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isEntrada
                  ? AppTheme.textPrimaryColor
                  : AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
