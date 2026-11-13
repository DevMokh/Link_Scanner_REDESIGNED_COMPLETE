import 'package:cobra_shield/core/app_info.dart';
import 'package:cobra_shield/core/models.dart';
import 'package:cobra_shield/core/theme.dart';
import 'package:cobra_shield/widgets/app_drawer.dart';
import 'package:cobra_shield/widgets/app_header.dart';
import 'package:cobra_shield/widgets/brand_logo.dart';
import 'package:cobra_shield/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// سجل نداءات القائمة الجانبية عشان نتأكد إن كل بند بيودّي لوجهته الحقيقية.
class _Calls {
  final List<String> log = <String>[];

  AppDrawer drawer({int selectedTab = 0}) {
    return AppDrawer(
      selectedTab: selectedTab,
      onTab: (i) => log.add('tab$i'),
      onQr: () => log.add('qr'),
      onImage: () => log.add('image'),
      onSender: () => log.add('sender'),
      onBatch: () => log.add('batch'),
      onTrain: () => log.add('train'),
      onLearn: () => log.add('learn'),
      onSettings: () => log.add('settings'),
      onExit: () => log.add('exit'),
    );
  }
}

Widget _app(Widget home) {
  return MaterialApp(
    theme: buildTheme(),
    locale: const Locale('ar'),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: home,
  );
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('AppDrawer', () {
    final key = GlobalKey<ScaffoldState>();

    Future<_Calls> open(WidgetTester tester, {int selectedTab = 0}) async {
      _tall(tester);
      final calls = _Calls();
      await tester.pumpWidget(
        _app(
          Scaffold(
            key: key,
            drawer: calls.drawer(selectedTab: selectedTab),
            body: const SizedBox.expand(),
          ),
        ),
      );
      key.currentState!.openDrawer();
      await tester.pumpAndSettle();
      return calls;
    }

    testWidgets('بيعرض الاسم والشعار والإصدار الحقيقي', (tester) async {
      await open(tester);
      expect(find.text(kAppNameAr), findsOneWidget);
      expect(find.text(kAppNameEn), findsOneWidget);
      expect(find.byType(LinkScannerLogo), findsOneWidget);
      expect(find.textContaining('$kAppVersion ($kAppBuild)'), findsOneWidget);
    });

    testWidgets('كل بند بيستدعي وجهته ويقفل القائمة', (tester) async {
      final labels = <String, String>{
        'فحص الروابط': 'tab1',
        'فحص الرسائل': 'tab2',
        'فحص رمز QR': 'qr',
        'فحص الصور': 'image',
        'فحص المرسل': 'sender',
        'الفحص المجمّع': 'batch',
        'سجل الفحوصات': 'tab3',
        'تدرّب على الكشف': 'train',
        'دروس الحماية': 'learn',
        'أدوات الأمان الإضافية': 'tab4',
        'الإعدادات': 'settings',
        'الرئيسية': 'tab0',
      };
      for (final e in labels.entries) {
        final calls = await open(tester);
        await tester.tap(find.text(e.key));
        await tester.pumpAndSettle();
        expect(calls.log, <String>[e.value], reason: e.key);
        expect(find.text(kAppNameAr), findsNothing, reason: 'القائمة لازم تتقفل');
      }
    });

    testWidgets('زر الخروج بيستدعي onExit', (tester) async {
      final calls = await open(tester);
      await tester.tap(find.text('خروج'));
      await tester.pumpAndSettle();
      expect(calls.log, <String>['exit']);
    });
  });

  group('AppHeader', () {
    testWidgets('بدون Drawer: مفيش زر قائمة', (tester) async {
      await tester.pumpWidget(
        _app(const Scaffold(body: AppHeader(title: 'عنوان', subtitle: 'فرعي'))),
      );
      expect(find.text('عنوان'), findsOneWidget);
      expect(find.text('فرعي'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsNothing);
      expect(find.byType(LinkScannerLogo), findsOneWidget);
    });

    testWidgets('مع Drawer: زر القائمة بيفتحها فعلًا', (tester) async {
      final calls = _Calls();
      await tester.pumpWidget(
        _app(
          Scaffold(
            drawer: calls.drawer(),
            body: const AppHeader(title: 'عنوان', subtitle: 'فرعي'),
          ),
        ),
      );
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(find.text(kAppNameAr), findsOneWidget);
    });

    testWidgets('أيقونة أداة بدل الشعار لما icon تتحدد', (tester) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: AppHeader(title: 'أداة', subtitle: 'وصف', icon: Icons.qr_code_2_rounded),
          ),
        ),
      );
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
      expect(find.byType(LinkScannerLogo), findsNothing);
    });
  });

  group('PrimaryButton', () {
    testWidgets('بينفّذ الضغطة', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Center(
              child: PrimaryButton(
                label: 'ابدأ الفحص',
                icon: Icons.radar_rounded,
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ابدأ الفحص'));
      expect(taps, 1);
    });

    testWidgets('معطّل (onPressed = null) مبيستجيبش', (tester) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: Center(
              child: PrimaryButton(
                label: 'معطّل',
                icon: Icons.radar_rounded,
                onPressed: null,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('معطّل'), warnIfMissed: false);
      expect(tester.takeException(), isNull);
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(PrimaryButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, lessThan(1));
    });
  });

  group('الثيم', () {
    test('الألوان: كحلي داكن وأزرق سماوي، والأخضر للأمان والأحمر للخطر', () {
      expect(C.bg.computeLuminance(), lessThan(0.01));
      expect(C.accent.b, greaterThan(C.accent.r));
      expect(C.accent.b, greaterThan(C.accent.g));
      expect(C.green.g, greaterThan(C.green.r));
      expect(C.green.g, greaterThan(C.green.b));
      expect(C.red.r, greaterThan(C.red.g));
      expect(levelColor(RiskLevel.low), C.green);
      expect(levelColor(RiskLevel.critical), C.red);
      final t = buildTheme();
      expect(t.scaffoldBackgroundColor, C.bg);
      expect(t.colorScheme.primary, C.accent);
    });
  });
}
