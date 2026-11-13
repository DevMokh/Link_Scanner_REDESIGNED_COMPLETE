import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// شعار كاشف الروابط | Link Scanner: درع أزرق سماوي بداخله رمز رابط (Chain Link).
/// مرسوم بالكود بالكامل (بدون صور أو حقوق). مفيش عدسة مكبرة ولا أي عنصر تاني.
///
/// العرض = [size] والارتفاع = size × [LinkScannerLogo.aspect].
class LinkScannerLogo extends StatelessWidget {
  const LinkScannerLogo({
    super.key,
    this.size = 120,
    this.color,
    this.glowing = true,
  });

  /// نسبة الارتفاع للعرض.
  static const double aspect = 1.1;

  final double size;
  final Color? color;

  /// تأثير الـ Glow حوالين الدرع والرابط.
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * aspect,
      child: CustomPaint(
        painter: LogoPainter(color: color ?? C.accent, glowing: glowing),
      ),
    );
  }
}

/// رسام الشعار. الإحداثيات بنسب من العرض/الارتفاع (0..1) عشان يتكبّر ويتصغّر بدون فقد.
class LogoPainter extends CustomPainter {
  const LogoPainter({required this.color, this.glowing = true});

  final Color color;
  final bool glowing;

  /// مسار الدرع. [k] بيصغّر المسار ناحية المركز (للإطار الداخلي).
  static Path shieldPath(double w, double h, double k) {
    Offset p(double x, double y) {
      return Offset(w * (0.5 + (x - 0.5) * k), h * (0.5 + (y - 0.5) * k));
    }

    final start = p(0.5, 0.02);
    final path = Path()..moveTo(start.dx, start.dy);

    void curve(double x1, double y1, double x2, double y2, double x, double y) {
      final a = p(x1, y1);
      final b = p(x2, y2);
      final e = p(x, y);
      path.cubicTo(a.dx, a.dy, b.dx, b.dy, e.dx, e.dy);
    }

    void line(double x, double y) {
      final e = p(x, y);
      path.lineTo(e.dx, e.dy);
    }

    curve(0.62, 0.10, 0.78, 0.14, 0.93, 0.14);
    line(0.93, 0.50);
    curve(0.93, 0.76, 0.74, 0.92, 0.5, 0.99);
    curve(0.26, 0.92, 0.07, 0.76, 0.07, 0.50);
    line(0.07, 0.14);
    curve(0.22, 0.14, 0.38, 0.10, 0.5, 0.02);
    path.close();
    return path;
  }

  /// رمز الرابط: حلقتان (كبسولتان) متشابكتان بميل 45 درجة.
  static void paintChain(Canvas canvas, double w, double h, Paint paint) {
    final center = Offset(w * 0.5, h * 0.5);
    final len = w * 0.43;
    final thick = w * 0.205;
    final gap = w * 0.135;
    const angle = -math.pi / 4;
    final dx = math.cos(angle) * gap;
    final dy = math.sin(angle) * gap;
    for (final sign in <double>[-1, 1]) {
      canvas.save();
      canvas.translate(center.dx + dx * sign, center.dy + dy * sign);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: len, height: thick),
          Radius.circular(thick / 2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outer = shieldPath(w, h, 1.0);
    final inner = shieldPath(w, h, 0.86);

    if (glowing) {
      canvas.drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.07
          ..color = alpha(color, 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.06),
      );
    }

    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[alpha(color, 0.30), alpha(color, 0.06)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..color = alpha(color, 0.45),
    );

    if (glowing) {
      paintChain(
        canvas,
        w,
        h,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.075
          ..color = alpha(color, 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
      );
    }
    paintChain(
      canvas,
      w,
      h,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.048
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant LogoPainter old) =>
      old.color != color || old.glowing != glowing;
}
