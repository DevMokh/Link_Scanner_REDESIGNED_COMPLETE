import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cobra_shield/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinkScannerLogo', () {
    testWidgets('بيترسم بالحجم المطلوب والارتفاع = العرض × aspect', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: Center(child: LinkScannerLogo(size: 100)),
        ),
      );
      final box = tester.getSize(find.byType(LinkScannerLogo));
      expect(box.width, 100);
      expect(box.height, closeTo(100 * LinkScannerLogo.aspect, 0.001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('بيترسم بدون Glow وبلون مخصص بدون أخطاء', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: LinkScannerLogo(size: 48, color: Colors.amber, glowing: false),
          ),
        ),
      );
      expect(find.byType(LinkScannerLogo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LogoPainter', () {
    const w = 200.0;
    const h = 220.0;

    test('مسار الدرع جوه حدود اللوحة', () {
      final b = LogoPainter.shieldPath(w, h, 1.0).getBounds();
      expect(b.left, greaterThanOrEqualTo(0));
      expect(b.top, greaterThanOrEqualTo(0));
      expect(b.right, lessThanOrEqualTo(w));
      expect(b.bottom, lessThanOrEqualTo(h));
    });

    test('الإطار الداخلي أصغر من الخارجي وجواه', () {
      final outer = LogoPainter.shieldPath(w, h, 1.0).getBounds();
      final inner = LogoPainter.shieldPath(w, h, 0.86).getBounds();
      expect(inner.left, greaterThan(outer.left));
      expect(inner.right, lessThan(outer.right));
      expect(inner.top, greaterThan(outer.top));
      expect(inner.bottom, lessThan(outer.bottom));
    });

    test('رمز الرابط كله جوه الدرع (أطراف الحلقتين)', () {
      final shield = LogoPainter.shieldPath(w, h, 1.0);
      // أطراف المحور المائل (45°) للحلقتين + نص عرض الخط.
      final reach = w * (0.135 + 0.43 / 2 + 0.048 / 2);
      final d = reach * math.cos(math.pi / 4);
      final cx = w / 2;
      final cy = h / 2;
      expect(shield.contains(Offset(cx + d, cy - d)), isTrue);
      expect(shield.contains(Offset(cx - d, cy + d)), isTrue);
      // وعرض الحلقة (عمودي على المحور) كمان جوه.
      final side = w * (0.205 / 2 + 0.048 / 2) * math.cos(math.pi / 4);
      expect(shield.contains(Offset(cx + side, cy + side)), isTrue);
      expect(shield.contains(Offset(cx - side, cy - side)), isTrue);
    });

    test('الرسم على Canvas ما بيرميش استثناء (بـ Glow وبدونه)', () {
      for (final glowing in <bool>[true, false]) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        LogoPainter(color: Colors.green, glowing: glowing)
            .paint(canvas, const Size(w, h));
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
        picture.dispose();
      }
    });

    test('shouldRepaint بيتغيّر مع اللون أو الـ Glow بس', () {
      const a = LogoPainter(color: Colors.green);
      expect(a.shouldRepaint(const LogoPainter(color: Colors.green)), isFalse);
      expect(a.shouldRepaint(const LogoPainter(color: Colors.red)), isTrue);
      expect(
        a.shouldRepaint(const LogoPainter(color: Colors.green, glowing: false)),
        isTrue,
      );
    });
  });
}
