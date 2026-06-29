import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cliente_flutter_myaccess/core/theme/theme.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/debug_role_provider.dart';
import 'package:cliente_flutter_myaccess/features/padres/screens/home_padre_screen.dart';
import 'package:cliente_flutter_myaccess/features/padres/providers/children_provider.dart';
import 'package:cliente_flutter_myaccess/features/maestros/screens/home_maestro_screen.dart';
import 'package:cliente_flutter_myaccess/features/maestros/screens/teacher_qr_screen.dart';
import 'package:cliente_flutter_myaccess/features/notifications/screens/notifications_screen.dart';
import 'package:cliente_flutter_myaccess/features/notifications/providers/notification_provider.dart';
import 'package:cliente_flutter_myaccess/features/profile/screens/profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final debugRole = ref.watch(debugRoleProvider);
    final unreadCount = ref.watch(notificationProvider.notifier).unreadCount;
    final effectiveRole = debugRole ?? authState.user?.role ?? 'parent';
    final isTeacher = effectiveRole == 'teacher';

    // Tab QR para padres: lista de selección de hijo → ChildQrScreen
    Widget parentQrTab() {
      final childrenAsync = ref.watch(childrenProvider);
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Códigos QR',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: AppTheme.bgLightColor,
        body: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (children) => children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_outlined,
                          size: 80, color: AppTheme.borderLightColor),
                      const SizedBox(height: 16),
                      Text(
                        'Sin hijos vinculados',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vincula un hijo desde la pantalla de inicio.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Selecciona un hijo para ver su QR',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: children.length,
                        itemBuilder: (context, index) {
                          final child = children[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.lightGoldColor,
                                child: const Icon(Icons.qr_code,
                                    color: AppTheme.accentGoldColor),
                              ),
                              title: Text(
                                child.name,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor),
                              ),
                              subtitle: Text(
                                '${child.grade} - ${child.group}',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.textSecondaryColor),
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppTheme.textSecondaryColor),
                              onTap: () =>
                                  context.push('/child/${child.id}/qr'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    final List<Widget> screens = [
      isTeacher ? const HomeMaestroScreen() : const HomePadreScreen(),
      isTeacher ? const TeacherQRScreen() : parentQrTab(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x14002452),
              blurRadius: 8,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.themeNavyColor,
            unselectedItemColor: AppTheme.textSecondaryColor,
            selectedLabelStyle: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home, color: AppTheme.themeNavyColor),
                label: 'Inicio',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_outlined),
                activeIcon: Icon(Icons.qr_code_scanner,
                    color: AppTheme.themeNavyColor),
                label: 'QR',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.notifications,
                      color: AppTheme.themeNavyColor),
                ),
                label: 'Notis',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person, color: AppTheme.themeNavyColor),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
