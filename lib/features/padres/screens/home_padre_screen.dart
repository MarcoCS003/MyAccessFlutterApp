import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/children_provider.dart';

class HomePadreScreen extends ConsumerWidget {
  final bool showQrSelector;
  const HomePadreScreen({super.key, this.showQrSelector = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final children = ref.watch(childrenProvider);

    if (showQrSelector) {
      return Scaffold(
        appBar: AppBar(
          leading: const Icon(Icons.menu),
          title: const Text('Códigos QR'),
        ),
        body: children.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: children.length,
                itemBuilder: (context, index) {
                  final child = children[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.lightGoldColor,
                        child: Icon(Icons.qr_code,
                            color: AppTheme.accentGoldColor),
                      ),
                      title: Text(child.name,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text('${child.grade} - ${child.group}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/child/${child.id}');
                      },
                    ),
                  );
                },
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Access IJL',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.lightGoldColor,
              child: Text(
                authState.user?.name.substring(0, 2).toUpperCase() ?? 'MP',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.accentGoldColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${authState.user?.name.split(" ")[0] ?? "Usuario"}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                'Revisa la actividad de tus hijos hoy.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tus hijos vinculados',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/link-child'),
                    icon: const Icon(Icons.add,
                        color: AppTheme.themeNavyColor),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.borderLightColor,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              children.isEmpty
                  ? _buildEmptyState(context)
                  : Column(
                      children: children.map((child) {
                        final isPresent = child.status == 'inside';
                        return GestureDetector(
                          onTap: () =>
                              context.push('/child/${child.id}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14002452),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      const Color(0xFFEEF2FF),
                                  child: Text(
                                    child.name
                                        .substring(0, 2)
                                        .toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: AppTheme.themeNavyColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        '${child.grade} - ${child.group}',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppTheme
                                              .textSecondaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPresent
                                              ? const Color(0xFFECFDF5)
                                              : const Color(0xFFF3F4F5),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isPresent
                                                    ? AppTheme
                                                        .successColor
                                                    : AppTheme
                                                        .textSecondaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isPresent
                                                  ? 'Última entrada: 07:45 AM'
                                                  : 'Aún no ingresa',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: isPresent
                                                    ? const Color(
                                                        0xFF065F46)
                                                    : AppTheme
                                                        .textSecondaryColor,
                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppTheme.textSecondaryColor),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 24),
              Text(
                'Actividad reciente',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildTimelineItem(
                icon: Icons.login_rounded,
                iconColor: AppTheme.successColor,
                title: 'Entrada Registrada',
                time: '07:45 AM',
                desc: 'Juan Pérez García ingresó por Puerta Principal.',
              ),
              _buildTimelineItem(
                icon: Icons.logout_rounded,
                iconColor: AppTheme.errorColor,
                title: 'Salida Registrada',
                time: 'Ayer, 14:30',
                desc: 'Juan Pérez García salió por Puerta Norte.',
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded,
                size: 80, color: AppTheme.borderLightColor),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes hijos vinculados',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor),
            ),
            Text(
              'Toca el botón + para vincular a tu primer hijo.',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String desc,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderLightColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A002452),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 20),
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
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.borderLightColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor),
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
