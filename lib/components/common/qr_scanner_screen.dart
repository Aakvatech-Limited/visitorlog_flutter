import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A reusable, beautifully styled QR / barcode scanner screen.
/// Returns the scanned value via [Navigator.pop].
class QRScannerScreen extends StatefulWidget {
  final String title;
  final String instruction;

  const QRScannerScreen({
    Key? key,
    this.title = 'Scan QR Code',
    this.instruction = 'Align the QR code inside the frame',
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double frameSize = 260.0;
    const double cornerLen = 28.0;
    const double cornerThick = 4.0;
    const Color brandColor = Color.fromRGBO(13, 29, 56, 1);
    const Color accentColor = Color(0xFF4FC3F7);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera feed ──────────────────────────────────────
          MobileScanner(
            onDetect: (capture) {
              if (_isScanned) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _isScanned = true;
                Navigator.pop(context, barcodes.first.rawValue ?? '');
              }
            },
          ),

          // ── Dark overlay with a transparent square hole ───────
          CustomPaint(
            size: Size.infinite,
            painter: _OverlayPainter(frameSize: frameSize),
          ),

          // ── Animated scan line inside the frame ───────────────
          Center(
            child: SizedBox(
              width: frameSize,
              height: frameSize,
              child: AnimatedBuilder(
                animation: _scanLineAnim,
                builder: (_, __) {
                  return Stack(
                    children: [
                      // Scan line
                      Positioned(
                        top: _scanLineAnim.value * (frameSize - 4),
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withOpacity(0),
                                accentColor,
                                accentColor.withOpacity(0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Corner brackets ───────────────────────────────────
          Center(
            child: SizedBox(
              width: frameSize,
              height: frameSize,
              child: CustomPaint(
                painter: _CornerPainter(
                  cornerLen: cornerLen,
                  cornerThick: cornerThick,
                  color: accentColor,
                ),
              ),
            ),
          ),

          // ── Top bar (back + title) ────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom instruction panel ──────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                  // subtle blur-glass feel via solid semi-transparent bg
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.instruction,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
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

/// Paints a dark overlay with a clear rectangular hole in the centre.
class _OverlayPainter extends CustomPainter {
  final double frameSize;
  const _OverlayPainter({required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.62);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = frameSize / 2;
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - half, cy - half, cx + half, cy + half),
      const Radius.circular(12),
    );
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(frameRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Paints four L-shaped corner brackets.
class _CornerPainter extends CustomPainter {
  final double cornerLen;
  final double cornerThick;
  final Color color;

  const _CornerPainter({
    required this.cornerLen,
    required this.cornerThick,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = cornerThick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final r = 12.0; // corner radius matching the frame

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(r, 0)
        ..lineTo(cornerLen, 0)
        ..moveTo(0, r)
        ..lineTo(0, cornerLen),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - cornerLen, 0)
        ..lineTo(w - r, 0)
        ..moveTo(w, r)
        ..lineTo(w, cornerLen),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - cornerLen)
        ..lineTo(0, h - r)
        ..moveTo(r, h)
        ..lineTo(cornerLen, h),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w, h - cornerLen)
        ..lineTo(w, h - r)
        ..moveTo(w - cornerLen, h)
        ..lineTo(w - r, h),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
