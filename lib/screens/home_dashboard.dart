import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../services/history_store.dart';
import '../services/threat_feed.dart';
import '../widgets/common.dart';
import '../widgets/scale_header.dart';

const List<String> _tips = <String>[
  'لو رسالة بتهدّدك بإيقاف حسابك خلال ساعات، دي علامة نصب كلاسيكية. البنوك الحقيقية مش بتستعجلك كده.',
  'محدش رسمي هيطلب منك كود التحقق أو CVV في مكالمة أو رسالة. ما تشاركش بياناتك.',
  'راجع اسم النطاق بعناية قبل فتح الرابط، خصوصًا لو بيقلّد اسم شركة معروفة.',
  'لو حد قالك رقمي اتغير وطلب فلوس، اتأكد من هويته بمكالمة على الرقم القديم.',
  'رمز QR ممكن يفتح موقعًا مزيفًا؛ افحص الرابط قبل ما تتابع.',
  'ما تثبتش تطبيق تحكم عن بُعد بناءً على طلب شخص اتصل بيك بشكل مفاجئ.',
  'لو الرسالة فيها رابط ومعاه استعجال أو تهديد، افحص الرابط قبل فتحه.',
  'فعّل التحقق بخطوتين، وما تشاركش كلمات السر أو أكواد التحقق مع أي حد.',
];

String _tipOfDay() {
  final day = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
  return _tips[day.abs() % _tips.length];
}

/// لوحة التحكم الرئيسية. كل الأرقام المعروضة مستخرجة من سجل الفحوصات المحلي.
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.onTab,
    required this.onQr,
    required this.onImage,
    required this.onTrain,
    required this.onLearn,
    required this.onSettings,
    this.onMenu,
  });

  /// 0 الرئيسية، 1 رابط، 2 رسالة، 3 السجل، 4 المزيد.
  final void Function(int tabIndex) onTab;
  final VoidCallback onQr;
  final VoidCallback onImage;
  final VoidCallback onTrain;
  final VoidCallback onLearn;
  final VoidCallback onSettings;
  final VoidCallback? onMenu;

  Widget _metric(String label, String value, IconData icon, Color tint) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF06130A),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: alpha(tint, 0.48)),
          boxShadow: [BoxShadow(color: alpha(tint, 0.08), blurRadius: 12)],
        ),
        child: Column(
          children: [
            Icon(icon, color: tint, size: 22),
            const SizedBox(height: 7),
            Text(value, style: TextStyle(color: tint, fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: C.muted, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _quick(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final width = (MediaQuery.of(context).size.width - 48) / 3;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B2111), Color(0xFF040B06)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: alpha(C.emerald, 0.56)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: C.emerald, size: 25),
                const SizedBox(height: 7),
                Text(label, textAlign: TextAlign.center,
                    style: const TextStyle(color: C.text, fontWeight: FontWeight.w800, fontSize: 11.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryAction() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: [BoxShadow(color: alpha(C.emerald, 0.3), blurRadius: 18, spreadRadius: 0.5)],
      ),
      child: FilledButton.icon(
        onPressed: () => onTab(1),
        style: FilledButton.styleFrom(
          backgroundColor: C.emerald,
          foregroundColor: C.onAccent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        icon: const Icon(Icons.search_rounded, size: 24),
        label: const Text('افحص رابط جديد'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        HistoryStore.instance,
        ThreatFeed.instance,
      ]),
      builder: (context, _) {
        final items = HistoryStore.instance.items;
        final feed = ThreatFeed.instance;
        final stale = feed.updated == null ||
            DateTime.now().difference(feed.updated!) > const Duration(days: 14);
        final urlCount = items.where((e) => e.kind == ScanKind.url).length;
        final threats = items.where((e) => e.level != RiskLevel.low).length;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            ScaleHeader(
              title: 'كاشف الروابط',
              subtitle: 'Link Scanner • افحص قبل ما تفتح',
              onMenu: onMenu,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Panel(
                    borderColor: alpha(C.emerald, 0.72),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                    child: Row(
                      children: [
                        const LinkShieldMark(size: 54),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('محرك الفحص جاهز', style: TextStyle(color: C.emerald, fontWeight: FontWeight.w900, fontSize: 15)),
                              SizedBox(height: 4),
                              Text('حلّل الروابط والرسائل قبل التفاعل معها', style: TextStyle(color: C.muted, fontSize: 11.5, height: 1.4)),
                            ],
                          ),
                        ),
                        Icon(Icons.verified_user_rounded, color: C.emerald, size: 25),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _metric('كل الفحوصات', '${items.length}', Icons.radar_rounded, C.emerald),
                      const SizedBox(width: 8),
                      _metric('روابط مفحوصة', '$urlCount', Icons.link_rounded, C.lime),
                      const SizedBox(width: 8),
                      _metric('مؤشرات خطورة', '$threats', Icons.warning_amber_rounded, threats == 0 ? C.emerald : C.amber),
                    ],
                  ),
                  const SizedBox(height: 13),
                  _primaryAction(),
                  const SizedBox(height: 10),
                  const SectionTitle('أدوات سريعة'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quick(context, Icons.qr_code_scanner_rounded, 'فحص QR', onQr),
                      _quick(context, Icons.image_search_rounded, 'فحص الصور', onImage),
                      _quick(context, Icons.mark_email_unread_rounded, 'فحص الرسائل', () => onTab(2)),
                      _quick(context, Icons.link_rounded, 'فحص الروابط', () => onTab(1)),
                      _quick(context, Icons.apps_rounded, 'المزيد', () => onTab(4)),
                      _quick(context, Icons.school_rounded, 'دروس الحماية', onLearn),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Panel(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: C.lime, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('نصيحة أمان', style: TextStyle(color: C.lime, fontWeight: FontWeight.w900, fontSize: 13)),
                              const SizedBox(height: 5),
                              Text(_tipOfDay(), style: const TextStyle(color: C.text, fontSize: 12, height: 1.55)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SectionTitle(
                      'آخر الفحوصات',
                      trailing: TextButton(
                        onPressed: () => onTab(3),
                        child: const Text('عرض الكل'),
                      ),
                    ),
                    for (final it in items.take(3)) _recent(it),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Panel(
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Column(
                        children: [
                          Icon(Icons.shield_outlined, color: C.emerald, size: 34),
                          SizedBox(height: 8),
                          Text('لسه مفيش فحوصات محفوظة', style: TextStyle(color: C.text, fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('ابدأ بفحص رابط أو رسالة وصلتك.', textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  if (stale) ...[
                    const SizedBox(height: 12),
                    Panel(
                      borderColor: alpha(C.amber, 0.45),
                      child: Row(
                        children: [
                          const Icon(Icons.update_rounded, color: C.amber),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('مصادر التهديدات قد تحتاج إلى تحديث للحصول على أحدث المعلومات.',
                                style: TextStyle(color: C.muted, fontSize: 11.5, height: 1.45)),
                          ),
                          TextButton(onPressed: onSettings, child: const Text('الإعدادات')),
                        ],
                      ),
                    ),
                  ],
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SectionTitle('ملخص سجل الفحوصات'),
                    StatsCardCompat(items: items),
                  ],
                  const SizedBox(height: 5),
                  Center(
                    child: TextButton.icon(
                      onPressed: onTrain,
                      icon: const Icon(Icons.psychology_alt_rounded, size: 18),
                      label: const Text('جرّب تدريب اكتشاف الروابط الاحتيالية'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _recent(HistoryItem it) {
    final c = levelColor(it.level);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: alpha(c, 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: alpha(c, 0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: alpha(c, 0.55)),
            ),
            child: Text('${it.score}', style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Directionality(
              textDirection: it.kind == ScanKind.url ? TextDirection.ltr : TextDirection.rtl,
              child: Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: C.text, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),
          Icon(levelIcon(it.level), color: c, size: 18),
        ],
      ),
    );
  }
}

IconData levelIcon(RiskLevel level) {
  switch (level) {
    case RiskLevel.low:
      return Icons.check_circle_rounded;
    case RiskLevel.medium:
      return Icons.info_rounded;
    case RiskLevel.high:
    case RiskLevel.critical:
      return Icons.warning_rounded;
  }
}

/// يظهر الملخص الأصلي دون تغيير حساباته أو طريقة تخزين النتائج.
class StatsCardCompat extends StatelessWidget {
  const StatsCardCompat({super.key, required this.items});
  final List<HistoryItem> items;

  @override
  Widget build(BuildContext context) {
    final low = items.where((e) => e.level == RiskLevel.low).length;
    final medium = items.where((e) => e.level == RiskLevel.medium).length;
    final high = items.length - low - medium;
    return Panel(
      child: Row(
        children: [
          _part('لا مؤشرات', low, C.emerald),
          _part('مشبوه', medium, C.amber),
          _part('خطير', high, C.red),
        ],
      ),
    );
  }

  Widget _part(String title, int count, Color color) => Expanded(
        child: Column(
          children: [
            Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(title, style: const TextStyle(color: C.muted, fontSize: 10.5)),
          ],
        ),
      );
}
