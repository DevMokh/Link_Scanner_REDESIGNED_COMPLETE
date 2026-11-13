import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme.dart';

/// شاشة الكاميرا لقراءة رمز QR. ترجع (pop) بالنص المقروء، أو null لو أُغلقت.
/// القراءة كلها على الجهاز ولا يُرسل شيء.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _done = false;
  bool _torch = false;

  /// حركة خط المسح داخل إطار التصويب (زخرفة بصرية فقط، مالهاش علاقة بالقراءة نفسها).
  late final AnimationController _scanLine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _scanLine.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.trim().isNotEmpty) {
        _done = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(v);
        return;
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torch = !_torch);
    } catch (_) {
      // الجهاز بدون فلاش
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // إطار التصويب: أركان سماوية + خط مسح متحرك
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: AnimatedBuilder(
                animation: _scanLine,
                builder: (context, _) => CustomPaint(
                  painter: _QrFramePainter(_scanLine.value),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: alpha(Colors.black, 0.55),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: _toggleTorch,
                    style: IconButton.styleFrom(
                      backgroundColor: alpha(Colors.black, 0.55),
                      foregroundColor: _torch ? C.amber : Colors.white,
                    ),
                    icon: Icon(
                      _torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: alpha(Colors.black, 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: alpha(C.accent, 0.4)),
                ),
                child: const Text(
                  'وجّه الكاميرا ناحية رمز QR. هنفحصه قبل ما تفتحه.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رسم إطار التصويب: أربعة أركان سماوية بتوهج خفيف + خط مسح أفقي.
class _QrFramePainter extends CustomPainter {
  _QrFramePainter(this.t);

  /// موضع خط المسح (0..1) من أعلى الإطار لأسفله.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 38.0;
    const r = 22.0;
    final w = size.width;
    final h = size.height;

    Path corners() {
      final p = Path();
      // أعلى اليسار
      p.moveTo(0, arm);
      p.lineTo(0, r);
      p.quadraticBezierTo(0, 0, r, 0);
      p.lineTo(arm, 0);
      // أعلى اليمين
      p.moveTo(w - arm, 0);
      p.lineTo(w - r, 0);
      p.quadraticBezierTo(w, 0, w, r);
      p.lineTo(w, arm);
      // أسفل اليمين
      p.moveTo(w, h - arm);
      p.lineTo(w, h - r);
      p.quadraticBezierTo(w, h, w - r, h);
      p.lineTo(w - arm, h);
      // أسفل اليسار
      p.moveTo(arm, h);
      p.lineTo(r, h);
      p.quadraticBezierTo(0, h, 0, h - r);
      p.lineTo(0, h - arm);
      return p;
    }

    final path = corners();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = alpha(C.accent, 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = C.accent,
    );

    final y = 14 + (h - 28) * t;
    final line = Rect.fromLTWH(14, y - 1.5, w - 28, 3);
    canvas.drawRect(
      line,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            alpha(C.accent, 0),
            C.accent,
            alpha(C.accent, 0),
          ],
        ).createShader(line)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _QrFramePainter old) => old.t != t;
}
