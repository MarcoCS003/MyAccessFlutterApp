import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/theme.dart';
import '../models/qr_code_data.dart';

class LinkChildScreen extends ConsumerStatefulWidget {
  const LinkChildScreen({super.key});

  @override
  ConsumerState<LinkChildScreen> createState() => _LinkChildScreenState();
}

class _LinkChildScreenState extends ConsumerState<LinkChildScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isManualTab = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  bool _isNavigating = false;
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
    _scannerController.dispose();
    _animationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Normaliza el contenido leído del QR. El backend genera códigos con
  /// formato JSON: `{"idS": "123", "personId": "STU005", "type": "student"}`
  /// donde `personId` es la referencia bancaria/qr_code del estudiante.
  QrCodeData _parseQrData(String code) {
    return QrCodeData.fromCode(code);
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_isNavigating) return;

    final barcode = capture.barcodes.firstOrNull;
    final rawCode = barcode?.rawValue;
    if (rawCode == null || rawCode.isEmpty) return;

    final now = DateTime.now();
    if (_lastScanTime != null && now.difference(_lastScanTime!).inSeconds < 3) {
      return;
    }
    if (_lastScannedCode == rawCode) return;

    _lastScanTime = now;
    _lastScannedCode = rawCode;

    debugPrint('[LinkChildScreen] QR detectado: $rawCode');
    HapticFeedback.lightImpact();

    final qrData = _parseQrData(rawCode);
    debugPrint(
      '[LinkChildScreen] Código parseado: id=${qrData.id}, ref=${qrData.reference}',
    );

    if (qrData.reference.isNotEmpty) {
      _codeController.text = qrData.reference;
      _showConfirmation(qrData);
    }
  }

  void _showConfirmation(QrCodeData qrData) async {
    if (_isNavigating || qrData.reference.trim().isEmpty) return;
    setState(() => _isNavigating = true);

    await _scannerController.stop();

    if (!mounted) return;
    final idParam = qrData.id != null ? '&id=${qrData.id}' : '';
    await context.push('/link-child/confirm?code=${qrData.reference}$idParam');

    if (mounted) {
      setState(() {
        _isNavigating = false;
        _lastScannedCode = null;
        _lastScanTime = null;
      });
      if (!_isManualTab) {
        await _scannerController.start();
      }
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
                    controller: _scannerController,
                    onDetect: _onQrDetected,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, child) {
                      debugPrint(
                        '[MobileScanner] errorBuilder: ${error.errorCode} | '
                        '${error.errorDetails?.message} | '
                        'permissionDenied=${error.errorCode == MobileScannerErrorCode.permissionDenied}',
                      );
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.errorColor,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No se pudo iniciar la cámara',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error.toString(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    debugPrint(
                                      '[MobileScanner] retrying start...',
                                    );
                                    _scannerController.start();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reintentar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if (_isManualTab)
                  Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.keyboard_alt_outlined,
                            color: Colors.white24,
                            size: 64,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Modo manual activado',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
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
                                  width: 2,
                                ),
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
                        fontWeight: FontWeight.w500,
                      ),
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
                            onTap: () => setState(() => _isManualTab = false),
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
                            onTap: () => setState(() => _isManualTab = true),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () => _showConfirmation(
                                        QrCodeData.fromCode(
                                          _codeController.text,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.themeNavyColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                      ),
                                      child: const Text('Buscar'),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'El código QR se encuentra impreso en la credencial escolar física del estudiante.',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_lastScannedCode != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Último código detectado:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _lastScannedCode!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ],
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
