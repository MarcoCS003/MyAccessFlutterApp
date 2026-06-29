import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final String displayName = user?.name ?? 'Usuario';
    final String displayEmail = user?.email ?? '';
    final String role = authState.user?.role == 'teacher' ? 'Docente' : 'Tutor';

    // Initials from name
    final List<String> parts = displayName.trim().split(' ');
    final String initials = parts.length >= 2
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
          padding: EdgeInsets.only(
            top: 64,
            bottom: 32,
            left: 24,
            right: 24,
          ),
          child: Column(
            children: [
              // Initials avatar (gold bg, navy text)
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

              // User name
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

              // Email
              Text(
                displayEmail,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.accentLightColor,
                ),
              ),
              const SizedBox(height: 12),

              // Role badge pill (white translucent)
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
              // Section header
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

              // Notificaciones tile
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                iconColor: AppTheme.primaryColor,
                title: 'Notificaciones',
                value: _notificationsEnabled,
                onChanged: (val) =>
                    setState(() => _notificationsEnabled = val),
              ),

              // Modo oscuro tile
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                iconColor: AppTheme.primaryColor,
                title: 'Modo oscuro',
                value: _darkModeEnabled,
                onChanged: (val) => setState(() => _darkModeEnabled = val),
              ),

              const Divider(
                height: 24,
                indent: 20,
                endIndent: 20,
                color: AppTheme.borderLightColor,
              ),

              // Cerrar sesión tile
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
                onTap: () {
                  ref.read(authProvider.notifier).signOut();
                },
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
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}

