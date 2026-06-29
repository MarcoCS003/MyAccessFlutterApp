import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/child.dart';
import '../models/timeline_event.dart';
import '../providers/children_provider.dart';

class HomePadreScreen extends ConsumerWidget {
  final bool showQrSelector;
  const HomePadreScreen({super.key, this.showQrSelector = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final childrenAsync = ref.watch(childrenProvider);

    if (showQrSelector) {
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
                        onTap: () => context.push('/child/${child.id}'),
                      ),
                    );
                  },
                ),
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
        onRefresh: () => ref.read(childrenProvider.notifier).loadChildren(),
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
              childrenAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorColor, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Error al cargar hijos',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          e.toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (children) => children.isEmpty
                    ? _buildEmptyState(context)
                    : Column(
                        children: children
                            .map((child) => _ChildCard(child: child))
                            .toList(),
                      ),
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
              Consumer(
                builder: (context, ref, _) {
                  final recentAsync = ref.watch(recentActivityProvider);
                  return recentAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No se pudo cargar la actividad reciente.',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    data: (events) {
                      if (events.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Aún no hay actividad registrada.',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: events.asMap().entries.map((entry) {
                          final (event, childName) = entry.value;
                          return _RecentEventTile(
                            event: event,
                            childName: childName,
                            isLast: entry.key == events.length - 1,
                          );
                        }).toList(),
                      );
                    },
                  );
                },
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
}

class _RecentEventTile extends StatelessWidget {
  final TimelineEvent event;
  final String childName;
  final bool isLast;

  const _RecentEventTile({
    required this.event,
    required this.childName,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isEntry = event.type == 'check_in';
    final iconColor = isEntry ? AppTheme.successColor : Colors.orange;
    final icon = isEntry ? Icons.login_rounded : Icons.logout_rounded;
    final title = isEntry ? 'Entrada registrada' : 'Salida registrada';
    final firstName = childName.split(' ').first;
    final location = event.location?.isNotEmpty == true
        ? event.location!
        : 'Puerta Principal';

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
                        event.time,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$firstName ${isEntry ? 'ingresó' : 'salió'} por $location',
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

class _ChildCard extends StatelessWidget {
  final Child child;

  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isPresent = child.status == 'inside';
    final lastEventText = child.lastEvent ??
        (isPresent ? 'Última entrada: 07:45 AM' : 'Aún no ingresa');
    final lastEventTime = child.lastEventTime != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(child.lastEventTime!)
        : '';

    return GestureDetector(
      onTap: () => context.push('/child/${child.id}'),
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
              backgroundColor: const Color(0xFFEEF2FF),
              child: Text(
                child.name.substring(0, 2).toUpperCase(),
                style: GoogleFonts.inter(
                  color: AppTheme.themeNavyColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${child.grade} - ${child.group}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPresent
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF3F4F5),
                      borderRadius: BorderRadius.circular(99),
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
                                ? AppTheme.successColor
                                : AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lastEventTime.isNotEmpty
                              ? '$lastEventText • $lastEventTime'
                              : lastEventText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isPresent
                                ? const Color(0xFF065F46)
                                : AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
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
  }
}
