import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/errors/failures.dart';
import '../../../core/theme/theme.dart';
import '../providers/children_provider.dart';
import '../providers/student_by_qr_provider.dart';
import '../widgets/child_card.dart';

class LinkChildConfirmScreen extends ConsumerStatefulWidget {
  final String code;
  final int? id;

  const LinkChildConfirmScreen({super.key, required this.code, this.id});

  @override
  ConsumerState<LinkChildConfirmScreen> createState() =>
      _LinkChildConfirmScreenState();
}

class _LinkChildConfirmScreenState
    extends ConsumerState<LinkChildConfirmScreen> {
  bool _isLinking = false;

  Future<void> _linkChild() async {
    setState(() => _isLinking = true);

    try {
      await ref.read(childrenProvider.notifier).linkChild(widget.code);
      if (mounted) {
        context.go('/home');
      }
    } on Failure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al vincular alumno'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = (id: widget.id, reference: widget.code);
    final studentAsync = ref.watch(studentByQrProvider(qrData));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar vinculación'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: studentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Error al buscar alumno: $e',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          data: (student) {
            if (student == null) {
              return _buildNotFound(context);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Se encontró el siguiente alumno:',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Código escaneado: ${widget.code}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                ChildCard(child: student),
                const Spacer(),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLinking ? null : _linkChild,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isLinking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Vincular alumno'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _isLinking ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimaryColor,
                      side: const BorderSide(color: AppTheme.borderLightColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 64),
          const SizedBox(height: 16),
          Text(
            'No se encontró ningún alumno con ese código',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Código escaneado: ${widget.code}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Escanear otro código'),
          ),
        ],
      ),
    );
  }
}
