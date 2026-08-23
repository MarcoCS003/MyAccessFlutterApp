import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../auth/data/session_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// userKey de la cuenta que se está activando (muestra spinner en el tile).
  String? _switchingKey;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final sessions = ref.watch(savedSessionsProvider);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Text(
                  'Cuentas',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondaryColor,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              ...sessions.map(
                (session) => _buildAccountTile(
                  session,
                  isActive: user != null && session.user.email == user.email,
                ),
              ),

              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Agregar cuenta',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  'Inicia sesión con otra cuenta sin cerrar la actual',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                onTap: () => context.push('/login?addAccount=1'),
              ),

              const Divider(
                height: 24,
                indent: 20,
                endIndent: 20,
                color: AppTheme.borderLightColor,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
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
                onChanged: (val) =>
                    ref.read(profileProvider.notifier).toggleNotifications(val),
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
                onTap: () => _confirmSignOut(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTile(SavedSession session, {required bool isActive}) {
    final displayName = session.user.name;
    final parts = displayName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';
    final roleLabel = session.user.role == 'teacher' ? 'Docente' : 'Tutor';
    final isSwitching = _switchingKey == session.userKey;

    return ListTile(
      leading: CircleAvatar(
        radius: 19,
        backgroundColor: isActive
            ? AppTheme.primaryColor
            : AppTheme.primaryColor.withValues(alpha: 0.12),
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
      title: Text(
        displayName,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        '${session.user.email} · $roleLabel',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppTheme.textSecondaryColor,
        ),
      ),
      trailing: isSwitching
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isActive
          ? const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.accentColor,
              size: 22,
            )
          : IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.errorColor,
                size: 20,
              ),
              tooltip: 'Eliminar cuenta del dispositivo',
              onPressed: () => _confirmRemoveAccount(session),
            ),
      onTap: isActive || isSwitching ? null : () => _switchAccount(session),
    );
  }

  Future<void> _switchAccount(SavedSession session) async {
    setState(() => _switchingKey = session.userKey);
    final ok = await ref
        .read(authProvider.notifier)
        .switchAccount(session.userKey);
    if (!mounted) return;
    setState(() => _switchingKey = null);
    if (!ok) {
      final message =
          ref.read(authProvider).errorMessage ?? 'No se pudo cambiar de cuenta';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _confirmRemoveAccount(SavedSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar cuenta',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Se eliminará ${session.user.email} de este dispositivo. '
          'Sus datos locales se conservan por si vuelve a iniciar sesión.',
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
              await ref
                  .read(authProvider.notifier)
                  .removeAccount(session.userKey);
            },
            child: Text(
              'Eliminar',
              style: GoogleFonts.inter(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
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

  void _confirmSignOut(BuildContext context) {
    final hasOtherAccounts = ref.read(savedSessionsProvider).length > 1;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cerrar sesión',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          hasOtherAccounts
              ? 'Se eliminará esta cuenta del dispositivo y se activará la otra cuenta guardada.'
              : '¿Estás seguro? Se eliminará esta cuenta del dispositivo.',
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
