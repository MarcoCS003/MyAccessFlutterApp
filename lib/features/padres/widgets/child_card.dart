import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../models/child.dart';

/// Tarjeta de visualización de un estudiante. Se usa en el home del padre y
/// en la pantalla de confirmación de vinculación.
class ChildCard extends StatelessWidget {
  final Child child;
  final VoidCallback? onTap;

  const ChildCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPresent = child.status == 'inside';
    final lastEventText =
        child.lastEvent ?? (isPresent ? 'En el colegio' : 'Aún no ingresa');
    final lastEventTime = child.lastEventTime != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(child.lastEventTime!)
        : '';

    return GestureDetector(
      onTap: onTap,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
