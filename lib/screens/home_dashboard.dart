import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../services/history_store.dart';
import '../services/settings_store.dart';
import '../services/threat_feed.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';
import '../widgets/stats_card.dart';

const List<String> _tips = <String>[
  'لو رسالة بتهدّدك بإيقاف حسابك خلال ساعات، دي علامة نصب كلاسيكية. البنوك الحقيقية مش بتستعجلك كده.',
  'محدش رسمي (بنك، محفظة، شركة اتصالات) هيطلب منك كود التحقق أو الـ CVV في مكالمة أو رسالة. اقفل الخط.',
  'اقرأ اسم الدومين من اليمين لليسار قبل الـ.com أو .eg. الجزء الأهم هو أقرب حاجة لنوع الامتداد.',
  'لو حد قالك "رقمي اتغير" وطلب فلوس، اتصل بالرقم القديم أو اسأله سؤال يعرفه هو بس قبل ما تحول.',
  'رمز QR ممكن يتلصق فوق رمز حقيقي في محل أو عداد ركن. راجع اسم الموقع بعد ما تفحصه قبل الدفع.',
  'لا تثبت تطبيق تحكم عن بعد بناءً على طلب حد اتصل بيك وقال إنه دعم فني.',
  'وظيفة بتطلب فلوس تسجيل مقدمًا هي نصب في الأغلب، مهما كان المرتب المعروض مغري.',
  'لو الرسالة فيها رابط ومعاه استعجال أو تهديد، افتراض إنه نصب أأمن ليك من فتحه.',
  'غيّر كلمة السر فورًا لو ضغطت على رابط مشبوه وكتبت بياناتك، وفعّل التحقق بخطوتين لو متاح.',
  'الجهات الحكومية (تموين، تأمينات، كهرباء) مش بترسل روابط دفع أو تهديد بقطع خدمة برسالة SMS.',
];

String _tipOfDay() {
  final day = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
  return _tips[day % _tips.length];
}

String _t(String ar, String en) => SettingsStore.instance.english ? en : ar;

/// تدرّج بطاقة الحالة: أزرق (جاهز) / كهرماني (قاعدة التهديدات محتاجة تحديث).
const List<Color> _heroReady = <Color>[Color(0xFF1B3A8A), Color(0xFF0F6FA8)];
const List<Color> _heroWarn = <Color>[Color(0xFF5A4310), Color(0xFF8A5A12)];

/// عدد الفحوصات اللي مستواها "خطير" أو "احتيال مرجّح" (نفس تصنيف الدرجات في السجل).
int countThreats(List<HistoryItem> items) {
  var n = 0;
  for (final it in items) {
    if (it.level == RiskLevel.high || it.level == RiskLevel.critical) n++;
  }
  return n;
}

/// عدد فحوصات الروابط في السجل.
int countUrlScans(List<HistoryItem> items) {
  var n = 0;
  for (final it in items) {
    if (it.kind == ScanKind.url) n++;
  }
  return n;
}

/// "منذ كام" لآخر فحص.
String agoText(DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return _t('الآن', 'just now');
  if (d.inMinutes < 60) return _t('منذ ${d.inMinutes} دقيقة', '${d.inMinutes} min ago');
  if (d.inHours < 24) return _t('منذ ${d.inHours} ساعة', '${d.inHours} h ago');
  return _t('منذ ${d.inDays} يوم', '${d.inDays} d ago');
}

/// الشاشة الرئيسية: لوحة تحكم بإحصائيات حقيقية من سجل الفحوصات على الجهاز.
/// مفيش أي رقم تجريبي: كل رقم مصدره [HistoryStore] أو [ThreatFeed].
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.onTab,
    required this.onQr,
    required this.onImage,
    required this.onSender,
    required this.onBatch,
    required this.onTrain,
    required this.onLearn,
    required this.onSettings,
    required this.onMenu,
  });

  /// 0 الرئيسية، 1 رابط، 2 رسالة، 3 السجل، 4 المزيد
  final void Function(int tabIndex) onTab;
  final VoidCallback onQr;
  final VoidCallback onImage;
  final VoidCallback onSender;
  final VoidCallback onBatch;
  final VoidCallback onTrain;
  final VoidCallback onLearn;
  final VoidCallback onSettings;
  final VoidCallback onMenu;

  Widget _topBar(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, top + 10, 12, 0),
      child: Row(
        children: [
          const LinkScannerLogo(size: 34, glowing: false),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              children: [
                Text(
                  kAppNameAr,
                  style: TextStyle(
                    color: C.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  kAppNameEn,
                  style: TextStyle(
                    color: C.accent,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _t('القائمة', 'Menu'),
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded, color: C.accent, size: 28),
          ),
        ],
      ),
    );
  }

  /// بطاقة الحالة: الشعار + حالة الجاهزية. الحالة هنا "جاهز للفحص" (حسب حداثة قاعدة التهديدات)،
  /// مش ضمان أمان: التطبيق بيفحص لما تطلب منه بس، مفيش حماية لحظية في الخلفية.
  Widget _hero({required bool ready, required String detail}) {
    final c = ready ? C.accent : C.amber;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: ready ? _heroReady : _heroWarn,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: alpha(c, 0.5)),
          boxShadow: glow(c, opacity: 0.3, blur: 22),
        ),
        child: Row(
          children: [
            LinkScannerLogo(
              size: 60,
              color: ready ? const Color(0xFFBFEAFF) : const Color(0xFFFFE2A8),
              glowing: false,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ready
                        ? _t('جاهز للفحص', 'Ready to scan')
                        : _t('حدّث قاعدة التهديدات', 'Update the threat list'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: glassDecoration(border: alpha(color, 0.45), radius: 18, glowing: true),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(color: C.text, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quick(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: glassDecoration(radius: 18),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: alpha(C.accent, 0.12),
                  border: Border.all(color: alpha(C.accent, 0.5)),
                  boxShadow: glow(C.accent, opacity: 0.18, blur: 12),
                ),
                child: Icon(icon, color: C.accent, size: 23),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: C.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
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
        final detail = items.isEmpty
            ? _t('ابدأ بفحص رابط أو رسالة وصلتك. الفحص بيتم لما تطلبه بس.',
                'Start by scanning a link or a message. Scanning happens only when you ask.')
            : '${_t('آخر فحص', 'Last scan')}: ${agoText(items.first.time)}. '
                '${_t('الفحص بيتم لما تطلبه بس.', 'Scanning happens only when you ask.')}';
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _topBar(context),
            _hero(ready: !stale, detail: detail),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _stat(Icons.link_rounded, '${countUrlScans(items)}',
                          _t('الروابط المفحوصة', 'Links scanned'), C.accent),
                      const SizedBox(width: 10),
                      _stat(Icons.warning_amber_rounded, '${countThreats(items)}',
                          _t('التهديدات المكتشفة', 'Threats found'), C.red),
                      const SizedBox(width: 10),
                      _stat(Icons.manage_search_rounded, '${items.length}',
                          _t('عمليات الفحص', 'Scans'), C.accent),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      items.length >= HistoryStore.maxItems
                          ? _t('من سجل فحوصاتك على الجهاز (بيحتفظ بآخر ${HistoryStore.maxItems} فحص).',
                              'From your on-device history (keeps the last ${HistoryStore.maxItems} scans).')
                          : _t('من سجل فحوصاتك المحفوظ على الجهاز.',
                              'From your on-device scan history.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: C.muted, fontSize: 11.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    onPressed: () => onTab(1),
                    icon: Icons.radar_rounded,
                    label: _t('فحص رابط جديد', 'Scan a new link'),
                  ),
                  const SizedBox(height: 14),
                  SectionTitle(_t('أدوات سريعة', 'Quick tools')),
                  Row(
                    children: [
                      _quick(Icons.qr_code_scanner_rounded,
                          _t('فحص QR', 'QR'), onQr),
                      const SizedBox(width: 10),
                      _quick(Icons.image_search_rounded,
                          _t('فحص الصور', 'Images'), onImage),
                      const SizedBox(width: 10),
                      _quick(Icons.mark_email_unread_rounded,
                          _t('فحص الرسائل', 'Messages'), () => onTab(2)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _quick(Icons.alternate_email_rounded,
                          _t('فحص المرسل', 'Sender'), onSender),
                      const SizedBox(width: 10),
                      _quick(Icons.playlist_add_check_rounded,
                          _t('فحص مجمّع', 'Batch'), onBatch),
                      const SizedBox(width: 10),
                      _quick(Icons.apps_rounded, _t('المزيد', 'More'),
                          () => onTab(4)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SectionTitle(_t('تعلّم', 'Learn')),
                  Row(
                    children: [
                      _quick(Icons.sports_esports_rounded,
                          _t('تدرّب', 'Train'), onTrain),
                      const SizedBox(width: 10),
                      _quick(Icons.school_rounded,
                          _t('دروس الحماية', 'Lessons'), onLearn),
                      const SizedBox(width: 10),
                      _quick(Icons.settings_rounded,
                          _t('الإعدادات', 'Settings'), onSettings),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Panel(
                    borderColor: alpha(C.amber, 0.4),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: C.amber, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _tipOfDay(),
                            style: const TextStyle(
                              color: C.text,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    Panel(
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                      child: Column(
                        children: [
                          const Icon(Icons.shield_outlined, color: C.muted, size: 38),
                          const SizedBox(height: 10),
                          Text(
                            _t('لسه معملتش أي فحص. ابدأ برابط أو رسالة وصلتك.',
                                "You haven't scanned anything yet. Start with a link or a message."),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: C.muted, height: 1.5),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    StatsCard(items: items),
                    const SizedBox(height: 14),
                    SectionTitle(
                      _t('آخر عمليات الفحص', 'Recent scans'),
                      trailing: TextButton(
                        onPressed: () => onTab(3),
                        child: Text(_t('عرض الكل', 'View all')),
                      ),
                    ),
                    for (final it in items.take(3)) _recent(it),
                  ],
                  if (stale) ...[
                    const SizedBox(height: 14),
                    Panel(
                      borderColor: alpha(C.amber, 0.4),
                      child: Row(
                        children: [
                          const Icon(Icons.update_rounded, color: C.amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feed.updated == null
                                  ? 'قاعدة مصادر التهديدات لسه مش محمّلة. حمّلها من المزيد ← الإعدادات.'
                                  : 'قاعدة مصادر التهديدات قديمة. حدّثها من المزيد ← الإعدادات للحصول على أحدث كشف.',
                              style: const TextStyle(color: C.muted, fontSize: 12.5, height: 1.5),
                            ),
                          ),
                          TextButton(
                            onPressed: onSettings,
                            child: Text(_t('الإعدادات', 'Settings')),
                          ),
                        ],
                      ),
                    ),
                  ],
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
      decoration: glassDecoration(border: alpha(c, 0.35), radius: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: alpha(c, 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: alpha(c, 0.5)),
            ),
            child: Text(
              '${it.score}',
              style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection:
                      it.kind == ScanKind.url ? TextDirection.ltr : TextDirection.rtl,
                  child: Text(
                    it.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: C.text, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${it.level.label} · ${agoText(it.time)}',
                  style: TextStyle(color: c, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Icon(
            it.kind == ScanKind.url
                ? Icons.link_rounded
                : Icons.mark_email_unread_rounded,
            color: C.muted,
            size: 18,
          ),
        ],
      ),
    );
  }
}
