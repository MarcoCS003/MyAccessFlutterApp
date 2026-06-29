import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/errors/failures.dart';
import '../../../core/theme/theme.dart';
import '../providers/children_provider.dart';

class LinkChildScreen extends ConsumerStatefulWidget {
  const LinkChildScreen({super.key});

  @override
  ConsumerState<LinkChildScreen> createState() => _LinkChildScreenState();
}

class _LinkChildScreenState extends ConsumerState<LinkChildScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  bool _isManualTab = false;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _linkChild(String code) async {
    if (code.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(childrenProvider.notifier).linkChild(code.trim());
      if (mounted) {
        context.pop();
      }
    } on Failure catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Error al vincular alumno');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onQrDetected(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      _linkChild(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular Hijo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                if (!_isManualTab)
                  MobileScanner(
                    onDetect: _onQrDetected,
                  ),
                if (_isManualTab)
                  Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.keyboard_alt_outlined,
                              color: Colors.white24, size: 64),
                          const SizedBox(height: 8),
                          Text(
                            'Modo manual activado',
                            style: GoogleFonts.inter(
                                color: Colors.white38, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_isManualTab)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth * 0.6;
                      return Stack(
                        children: [
                          Center(
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppTheme.accentLightColor,
                                    width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final topOffset =
                                  (constraints.maxHeight - size) / 2 +
                                      (_animationController.value * size);
                              return Positioned(
                                top: topOffset,
                                left: (constraints.maxWidth - size) / 2,
                                width: size,
                                child: Container(
                                  height: 2,
                                  color: AppTheme.accentLightColor,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      _isManualTab
                          ? 'Ingresa el código en el panel inferior'
                          : 'Alinea el código QR dentro del recuadro',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A002452),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isManualTab = false),
                            child: Column(
                              children: [
                                Text(
                                  'Escanear QR',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: !_isManualTab
                                        ? AppTheme.themeNavyColor
                                        : AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 2,
                                  color: !_isManualTab
                                      ? AppTheme.themeNavyColor
                                      : Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isManualTab = true),
                            child: Column(
                              children: [
                                Text(
                                  'Código manual',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: _isManualTab
                                        ? AppTheme.themeNavyColor
                                        : AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 2,
                                  color: _isManualTab
                                      ? AppTheme.themeNavyColor
                                      : Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _isManualTab
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _codeController,
                                        decoration: InputDecoration(
                                          labelText: 'Código del alumno',
                                          hintText: 'Ej: IJL-12345',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _linkChild(
                                              _codeController.text),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.themeNavyColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 16),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Buscar'),
                                    ),
                                  ],
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      color: AppTheme.errorColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: AppTheme.textSecondaryColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'El código QR se encuentra impreso en la credencial escolar física del estudiante.',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color:
                                            AppTheme.textSecondaryColor),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
