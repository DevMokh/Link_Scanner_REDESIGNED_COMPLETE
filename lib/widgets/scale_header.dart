import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// شعار مرسوم من عناصر Flutter: درع ورمز رابط، دون الاعتماد على صورة خارجية.
class LinkShieldMark extends StatelessWidget {
  const LinkShieldMark({super.key, this.size = 58, this.symbol = Icons.link_rounded});

  final double size;
  final IconData symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [alpha(C.emerald, 0.28), alpha(C.emerald, 0.04), Colors.transparent],
        ),
        boxShadow: [
          BoxShadow(color: alpha(C.emerald, 0.24), blurRadius: size * 0.34, spreadRadius: 1),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shield_rounded, size: size * 0.94, color: C.emerald),
          Icon(Icons.shield_outlined, size: size * 0.84, color: C.lime),
          Container(
            width: size * 0.57,
            height: size * 0.57,
            decoration: BoxDecoration(
              color: C.bg,
              shape: BoxShape.circle,
              border: Border.all(color: alpha(C.emerald, 0.38)),
            ),
            child: Icon(symbol, size: size * 0.42, color: C.text),
          ),
        ],
      ),
    );
  }
}

/// ترويسة بنمط شبكة أمنية مضيئة وهوية كاشف الروابط.
class ScaleHeader extends StatelessWidget {
  const ScaleHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.link_rounded,
    this.onMenu,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF062713), Color(0xFF031108), C.bg],
          stops: [0, 0.58, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _HexPainter(alpha(C.emerald, 0.13))),
          ),
          Positioned(
            top: top + 14,
            left: 12,
            right: 12,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  if (onMenu != null)
                    IconButton(
                      tooltip: 'القائمة',
                      onPressed: onMenu,
                      icon: const Icon(Icons.menu_rounded, color: C.text, size: 27),
                    )
                  else
                    const SizedBox(width: 8),
                  const Spacer(),
                  const Text(
                    'LINK SCANNER',
                    style: TextStyle(
                      color: C.emerald,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.verified_user_rounded, color: C.emerald, size: 18),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 54, 20, 25),
            child: Row(
              children: [
                LinkShieldMark(size: 72, symbol: icon),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: C.text,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: C.emerald,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: C.emerald, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'أمانك يبدأ بالفحص',
                            style: TextStyle(color: C.muted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const r = 18.0;
    final w = r * 1.7320508;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    var row = 0;
    while (row * r * 1.5 < size.height + r * 2) {
      final y = row * r * 1.5;
      final offset = row.isOdd ? w / 2 : 0.0;
      for (var x = -w + offset; x < size.width + w; x += w) {
        _hex(canvas, Offset(x, y), r, paint);
      }
      row++;
    }
  }

  void _hex(Canvas canvas, Offset o, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 3 * i + math.pi / 6;
      final pt = Offset(o.dx + r * math.cos(a), o.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) => old.color != color;
}
