import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/teacher_provider.dart';

class TeacherQRScreen extends ConsumerStatefulWidget {
  const TeacherQRScreen({super.key});

  @override
  ConsumerState<TeacherQRScreen> createState() => _TeacherQRScreenState();
}

class _TeacherQRScreenState extends ConsumerState<TeacherQRScreen> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref.read(authProvider.notifier).refreshUser();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final qrCode = ref.watch(teacherQrProvider);

    final userName = user?.name ?? 'Profesor IJL';
    final userEmail = user?.email ?? 'profesor@ijl.edu.mx';

    return Scaffold(
      backgroundColor: AppTheme.bgLightColor,
      appBar: AppBar(
        title: Text(
          'Mi Código de Acceso',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        automaticallyImplyLeading: false,
        actions: [
          if (qrCode != null)
            IconButton(
              tooltip: 'Actualizar código QR',
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              onPressed: _isRefreshing ? null : _refresh,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              if (qrCode != null)
                    _QrReadyCard(
                      qrPayload: jsonEncode({
                        'idS': '0',
                        'personId': qrCode,
                        'type': 'teacher',
                      }),
                      userName: userName,
                      userEmail: userEmail,
                    )
                  else if (_isRefreshing)
                    const _QrLoadingCard()
                  else
                    const _QrEmptyCard(),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sensors_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Acerca tu teléfono al lector del checador o muéstralo a los padres.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textPrimaryColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrReadyCard extends StatelessWidget {
  final String qrPayload;
  final String userName;
  final String userEmail;

  const _QrReadyCard({
    required this.qrPayload,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppTheme.accentGoldColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'MAESTRO',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Muestra este código para que los padres te vinculen',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          QrImageView(
            data: qrPayload,
            size: 220.0,
            backgroundColor: Colors.white,
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppTheme.primaryColor,
            ),
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            userName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrLoadingCard extends StatelessWidget {
  const _QrLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Cargando tu código QR…',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _QrEmptyCard extends StatelessWidget {
  const _QrEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            color: AppTheme.textSecondaryColor,
            size: 72,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay código QR asignado',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu cuenta aún no está enlazada con un maestro en el sistema. '
            'Pide al administrador del colegio que vincule tu usuario con tu '
            'registro de maestro o usa el botón de actualizar más tarde.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}