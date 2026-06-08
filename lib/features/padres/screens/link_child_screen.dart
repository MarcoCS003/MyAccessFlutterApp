import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular Hijo'),
      ),
      body: Column(
        children: [
          // Top 60% - Área de Escáner de Cámara
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                // Simulación de vista previa de cámara
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            color: Colors.white24, size: 64),
                        const SizedBox(height: 8),
                        Text(
                          'Escáner Activo',
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                // Overlay con marco central de escaneo
                if (!_isManualTab)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth * 0.6;
                      return Stack(
                        children: [
                          // Caja de Escaneo Animada
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
                          // Línea Láser Animada
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

          // Bottom 40% - Tarjeta blanca con Tab Selector
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
                    // Tab selector
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

                    // Contenido según Tab
                    Expanded(
                      child: _isManualTab
                          ? Row(
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
                                  onPressed: () {
                                    if (_codeController.text.isNotEmpty) {
                                      ref
                                          .read(childrenProvider.notifier)
                                          .linkChildManually(
                                              _codeController.text);
                                      Navigator.pop(context);
                                    }
                                  },
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
                                  child: const Text('Buscar'),
                                ),
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
