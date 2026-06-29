import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final user = authState.user;

    final displayName = user?.name ?? 'Usuario';
    final displayEmail = user?.email ?? '';
    final role = user?.role == 'teacher' ? 'Docente' : 'Tutor';

    final parts = displayName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : 'U';

    return Column(
      children: [
        // ── Top navy header ──────────────────────────────────────
        Container(
          width: double.infinity,
          color: AppTheme.primaryColor,
          padding: const EdgeInsets.only(
            top: 64,
            bottom: 32,
            left: 24,
            right: 24,
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.lightGoldColor,
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayEmail,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.accentLightColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  role,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Settings list ─────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  'Configuración',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondaryColor,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                iconColor: AppTheme.primaryColor,
                title: 'Notificaciones',
                subtitle: 'Mostrar alertas en la app',
                value: profile.settings.notificationsEnabled,
                onChanged: (val) => ref
                    .read(profileProvider.notifier)
                    .toggleNotifications(val),
              ),

              _buildThemeTile(
                context: context,
                profile: profile,
                onChanged: (mode) => ref
                    .read(profileProvider.notifier)
                    .setThemeMode(mode),
              ),

              const Divider(
                height: 24,
                indent: 20,
                endIndent: 20,
                color: AppTheme.borderLightColor,
              ),

              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Versión',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  profile.version ?? 'Cargando...',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),

              const Divider(
                height: 24,
                indent: 20,
                endIndent: 20,
                color: AppTheme.borderLightColor,
              ),

              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Cerrar sesión',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorColor,
                  ),
                ),
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppTheme.textSecondaryColor,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildThemeTile({
    required BuildContext context,
    required ProfileState profile,
    required ValueChanged<ThemeMode> onChanged,
  }) {
    final themeLabels = {
      ThemeMode.system: 'Según el sistema',
      ThemeMode.light: 'Claro',
      ThemeMode.dark: 'Oscuro',
    };

    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.dark_mode_outlined,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        'Tema',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        themeLabels[profile.settings.themeMode] ?? 'Sistema',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppTheme.textSecondaryColor,
        ),
      ),
      trailing: DropdownButton<ThemeMode>(
        value: profile.settings.themeMode,
        underline: const SizedBox.shrink(),
        onChanged: (mode) {
          if (mode != null) onChanged(mode);
        },
        items: ThemeMode.values.map((mode) {
          return DropdownMenuItem(
            value: mode,
            child: Text(
              themeLabels[mode] ?? mode.name,
              style: GoogleFonts.inter(fontSize: 13),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cerrar sesión',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro? Se borrarán todos los datos locales de este dispositivo.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              await ref.read(authProvider.notifier).signOut();
            },
            child: Text(
              'Cerrar sesión',
              style: GoogleFonts.inter(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
