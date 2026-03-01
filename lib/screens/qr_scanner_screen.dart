import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned || !mounted) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue ?? barcode.displayValue;
      if (raw == null || raw.isEmpty) continue;

      final code = _extractGameCode(raw);
      if (code != null) {
        _hasScanned = true;
        Navigator.pop(context, code);
        return;
      }

      // Barcode detected but doesn't look like a game code — show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not a valid game code: $raw'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
  }

  /// Extract game code from scanned value.
  /// Supports both raw codes (ABC123 / ABC-123) and URLs containing codes.
  String? _extractGameCode(String value) {
    // Strip whitespace and hyphens, normalise to upper case
    final cleaned = value.trim().toUpperCase().replaceAll(RegExp(r'[-\s]'), '');

    // Direct match: exactly 6 alphanumeric chars (letters + digits)
    if (RegExp(r'^[A-Z0-9]{6}$').hasMatch(cleaned)) {
      return cleaned;
    }

    // Try to extract from URL (e.g., chalkman://join?code=ABC123)
    final uri = Uri.tryParse(value);
    if (uri != null) {
      final codeParam = uri.queryParameters['code'];
      if (codeParam != null) {
        final code = codeParam.toUpperCase().replaceAll(RegExp(r'[-\s]'), '');
        if (RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
          return code;
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay with scanning frame
          _buildScanOverlay(),

          // Bottom instructions
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Point camera at the game QR code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Torch toggle
                IconButton(
                  onPressed: () => _controller.toggleTorch(),
                  icon: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, state, child) {
                      return Icon(
                        state.torchState == TorchState.on
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: Colors.white,
                        size: 28,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - scanSize) / 2;
        final top = (constraints.maxHeight - scanSize) / 2.5;

        return Stack(
          children: [
            // Dark overlay with cutout
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // Any color, will be cut out
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corner brackets
            Positioned(
              left: left,
              top: top,
              child: _buildCorner(0),
            ),
            Positioned(
              right: left,
              top: top,
              child: _buildCorner(1),
            ),
            Positioned(
              left: left,
              bottom: constraints.maxHeight - top - scanSize,
              child: _buildCorner(2),
            ),
            Positioned(
              right: left,
              bottom: constraints.maxHeight - top - scanSize,
              child: _buildCorner(3),
            ),
          ],
        );
      },
    );
  }

  /// Build corner bracket decorations (0=TL, 1=TR, 2=BL, 3=BR)
  Widget _buildCorner(int position) {
    const size = 24.0;
    const thickness = 3.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          position: position,
          color: AppTheme.feltGreen,
          thickness: thickness,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final int position;
  final Color color;
  final double thickness;

  _CornerPainter({
    required this.position,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (position) {
      case 0: // Top-left
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
      case 1: // Top-right
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
      case 2: // Bottom-left
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
      case 3: // Bottom-right
        path.moveTo(0, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
