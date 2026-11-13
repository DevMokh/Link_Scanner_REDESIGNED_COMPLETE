import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_info.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../services/advanced_scanner.dart';
import '../services/history_store.dart';
import '../services/inbox.dart';
import '../services/qr_analyzer.dart';
import '../services/settings_store.dart';
import '../services/strings.dart';
import '../services/url_analyzer.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/intel_tiles.dart';
import '../widgets/scan_report.dart';
import 'qr_scan_screen.dart';

class UrlScanScreen extends StatefulWidget {
  const UrlScanScreen({super.key});

  @override
  State<UrlScanScreen> createState() => _UrlScanScreenState();
}

class _UrlScanScreenState extends State<UrlScanScreen> {
  final TextEditingController _ctrl = TextEditingController();
  ScanResult? _result;
  AdvancedReport? _adv;
  bool _running = false;
  String _step = '';

  /// نص الرابط وقت الفحص (المستخدم ممكن يعدّل الحقل بعد الفحص).
  String _scanned = '';

  /// رقم الفحص الحالي: بيستخدم كمفتاح عشان انتقال النتيجة يتحرّك بنعومة.
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    Inbox.toUrl.addListener(_onInbox);
  }

  @override
  void dispose() {
    Inbox.toUrl.removeListener(_onInbox);
    _ctrl.dispose();
    super.dispose();
  }

  // رابط جاي من المشاركة أو من تنبيه الحافظة
  void _onInbox() {
    final inc = Inbox.toUrl.value;
    if (inc == null || !mounted) return;
    _ctrl.text = inc.text;
    _scan();
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text?.trim();
    if (t == null || t.isEmpty) {
      if (mounted) toast(context, 'الحافظة فاضية');
      return;
    }
    _ctrl.text = t;
    _scan();
  }

  Future<void> _scanQr() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScanScreen()),
    );
    if (raw == null || !mounted) return;
    final info = QrAnalyzer.classify(raw);
    if (info.link != null) {
      _ctrl.text = info.link!;
      _scan();
      toast(context, 'تم قراءة الرمز وفحص الرابط');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface2,
        title: Text('رمز QR: ${info.title}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(info.note, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: C.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.line),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    info.raw.length > 400
                        ? '${info.raw.substring(0, 400)}...'
                        : info.raw,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _result = null;
      _adv = null;
      _scanned = '';
    });
  }

  void _scan() {
    FocusScope.of(context).unfocus();
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      toast(context, 'الصق رابطًا أو اكتبه أولًا');
      return;
    }
    final r = UrlAnalyzer.analyze(raw);
    setState(() {
      _result = r;
      _adv = null;
      _running = false;
      _scanned = raw;
      _seq++;
    });
    // مدخل غير صالح أو فشل تحليل: مفيش درجة خطر، فمش بيتسجّل في السجل كفحص.
    if (!r.hasScore) return;
    // اسم السجل = المضيف الكامل (Hostname) مش الدومين المسجّل بس.
    final name = r.parts?.host ?? raw;
    final short = name.length > 60 ? '${name.substring(0, 60)}...' : name;
    HistoryStore.instance.add(HistoryItem(
      id: DateTime.now().microsecondsSinceEpoch,
      kind: ScanKind.url,
      title: short,
      score: r.effectiveScore,
      time: DateTime.now(),
    ));
  }

  Future<bool> _askConsent() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface2,
        title: const Text('الفحص المتقدم (أونلاين)'),
        content: const SingleChildScrollView(
          child: Text(
            'هذا الفحص يتصل بالإنترنت:\n\n'
            '• الموقع نفسه: لتتبع التحويلات (HEAD فقط، بدون تحميل صفحة). الموقع يعرف عنوان IP الخاص بك.\n'
            '• rdap.org وسجل الدومين: يُرسل اسم الدومين فقط لمعرفة عمره.\n'
            '• Google Safe Browsing و VirusTotal: فقط لو أضفت مفتاحًا، ويُرسل لهما الرابط كاملًا.\n'
            '• قاعدة OpenPhish: محلية بعد التحديث ولا يُرسل شيء.\n\n'
            'هل تريد المتابعة؟',
            style: TextStyle(height: 1.6, fontSize: 13.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: C.accent,
              foregroundColor: C.onAccent,
            ),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _advanced() async {
    final r = _result;
    if (r == null || r.parts == null) return;
    final s = SettingsStore.instance;
    if (!s.intelConsent) {
      final ok = await _askConsent();
      if (!ok) return;
      await s.setIntelConsent(true);
    }
    if (!mounted) return;
    setState(() {
      _running = true;
      _step = 'جارٍ التحضير...';
      _adv = null;
    });
    try {
      final rep = await AdvancedScanner.run(r, onStep: (t) {
        if (mounted) setState(() => _step = t);
      });
      if (!mounted) return;
      setState(() {
        _running = false;
        _adv = rep;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _running = false);
      toast(context, 'تعذر إكمال الفحص المتقدم');
    }
  }

  /// الرابط اللي هيتعرض/يتنسخ: الشكل بعد التنظيف لو موجود، وغير كده اللي اتكتب.
  String _shownUrl(ScanResult r) {
    final clean = r.parts?.normalizedUrl ?? '';
    return clean.isNotEmpty ? clean : _scanned;
  }

  Future<void> _shareReport(ScanResult r) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: r.toReport(), subject: 'تقرير $kAppName'),
      );
    } catch (_) {
      if (mounted) toast(context, 'تعذرت المشاركة');
    }
  }

  Widget _inputPanel() {
    return Panel(
      borderColor: alpha(C.accent, 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, color: C.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'الرابط المراد فحصه',
                style: TextStyle(color: C.text, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _ctrl,
            builder: (context, value, _) {
              return TextField(
                controller: _ctrl,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _scan(),
                autocorrect: false,
                enableSuggestions: false,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: C.text,
                ),
                decoration: fieldDecoration(
                  hint: 'https://example.com/login',
                  suffix: value.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'مسح',
                          icon: const Icon(Icons.close_rounded, color: C.muted),
                          onPressed: _clear,
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'ابدأ الفحص',
            icon: Icons.radar_rounded,
            onPressed: _scan,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _paste,
                  style: outlineButtonStyle(),
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text('لصق وفحص'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scanQr,
                  style: outlineButtonStyle(),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const Text('رمز QR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'الفحص الأساسي يتم داخل جهازك بدون إرسال الرابط لأي جهة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _tip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: C.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: C.muted, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// إرشادات تظهر قبل أول فحص (نصائح ثابتة، مش أرقام ولا نتائج).
  Widget _tipsPanel() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('قبل ما تفتح أي رابط'),
          _tip(Icons.mark_email_unread_outlined,
              'افحص الرابط الأول، خصوصًا لو جاي في رسالة أو إعلان أو من شخص متعرفوش.'),
          _tip(Icons.alt_route_rounded,
              'الروابط المختصرة بتخفي الوجهة الحقيقية. الفحص المتقدم بيتتبّع التحويلات ويكشفها.'),
          _tip(Icons.rule_rounded,
              '"لا مؤشرات خطر" مش ضمان إن الموقع آمن: دومين جديد أو موقع مخترق ممكن يعدّي بدون إشارة.'),
        ],
      ),
    );
  }

  /// بطاقة الرابط المفحوص (الشكل بعد التنظيف) مع زر نسخ.
  Widget _scannedUrlCard(ScanResult r) {
    final url = _shownUrl(r);
    if (url.isEmpty) return const SizedBox.shrink();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.travel_explore_rounded, color: C.accent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'الرابط المفحوص',
                  style: TextStyle(color: C.text, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'نسخ الرابط',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_rounded, size: 18, color: C.accent),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (mounted) toast(context, 'تم نسخ الرابط');
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alpha(C.surface2, 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                url,
                style: const TextStyle(
                  color: C.text,
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// إجراءات المستخدم بعد النتيجة: مشاركة التقرير + فحص رابط آخر.
  Widget _actions(ScanResult r) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareReport(r),
            style: outlineButtonStyle(),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('مشاركة التقرير'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clear,
            style: outlineButtonStyle(),
            icon: const Icon(Icons.add_link_rounded, size: 20),
            label: const Text('فحص رابط آخر'),
          ),
        ),
      ],
    );
  }

  Widget _advancedPanel() {
    final a = _adv;
    final s = SettingsStore.instance;
    final sources = <String>[
      'التحويلات',
      'عمر الدومين',
      'OpenPhish',
      if (s.gsbKey.isNotEmpty) 'Google',
      if (s.vtKey.isNotEmpty) 'VirusTotal',
    ];
    return Panel(
      borderColor: alpha(C.accent, 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.travel_explore_rounded, color: C.accent, size: 22),
              SizedBox(width: 8),
              Text(
                'الفحص المتقدم (أونلاين)',
                style: TextStyle(color: C.text, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'يكشف الوجهة الحقيقية، وعمر الدومين، ويقارنه بقوائم التهديدات. المصادر الآن: ${sources.join(' + ')}.',
            style: const TextStyle(color: C.muted, fontSize: 12.5, height: 1.45),
          ),
          const SizedBox(height: 10),
          if (_running) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(color: C.accent, minHeight: 5),
            ),
            const SizedBox(height: 8),
            Text(_step, style: const TextStyle(color: C.muted, fontSize: 12.5)),
          ] else
            PrimaryButton(
              onPressed: _advanced,
              icon: Icons.public_rounded,
              label: a == null ? 'ابدأ الفحص المتقدم' : 'أعد الفحص',
              height: 50,
            ),
          if (a != null && !_running) ...[
            const SizedBox(height: 14),
            const Text(
              'مسار الرابط',
              style: TextStyle(color: C.text, fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            const SizedBox(height: 6),
            ChainView(chain: a.expand.chain),
            if (a.expand.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  a.expand.error!,
                  style: const TextStyle(color: C.amber, fontSize: 12.5),
                ),
              )
            else if (!a.expand.redirected)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'الرابط لا يعيد التوجيه (حالة السيرفر: ${a.expand.statusCode ?? '-'}).',
                  style: const TextStyle(color: C.muted, fontSize: 12.5),
                ),
              ),
            const SizedBox(height: 14),
            const Text(
              'نتائج المصادر',
              style: TextStyle(color: C.text, fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            for (final r in a.intel) IntelTile(result: r),
            if (a.partial)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'فحص جزئي: تعذر ${a.failedSources.join('، ')}. النتيجة النهائية لا تشمل هذه المصادر، وفشلها لا يعني إن الرابط آمن.',
                  style: const TextStyle(color: C.amber, fontSize: 12.5, height: 1.45),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// كل ما يظهر بعد الفحص: الرابط، الحكم، تفكيك الرابط، الفحص المتقدم، الأسباب، الإجراءات.
  Widget _resultColumn(ScanResult r, AdvancedReport? adv) {
    return Column(
      key: ValueKey<int>(_seq),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _scannedUrlCard(r),
        const SizedBox(height: 14),
        ScanSummaryCard(result: r, heading: 'النتيجة الأساسية (على جهازك)'),
        if (r.parts != null) ...[
          const SizedBox(height: 14),
          UrlBreakdown(parts: r.parts!),
          const SizedBox(height: 14),
          _advancedPanel(),
        ],
        if (adv != null) ...[
          const SizedBox(height: 16),
          ScanSummaryCard(
            result: adv.toResult(r),
            heading: 'النتيجة النهائية بعد الفحص المتقدم',
          ),
          const SizedBox(height: 14),
          FindingsList(
            findings: adv.toResult(r).findings,
            title: 'كل المؤشرات بعد الفحص المتقدم',
          ),
        ] else ...[
          const SizedBox(height: 14),
          FindingsList(findings: r.findings),
        ],
        const SizedBox(height: 12),
        _actions(adv == null ? r : adv.toResult(r)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final adv = _adv;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AppHeader(
          title: tr(S.urlTitle),
          subtitle: tr(S.urlSubtitle),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _inputPanel(),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: r == null
                    ? KeyedSubtree(key: const ValueKey<int>(-1), child: _tipsPanel())
                    : _resultColumn(r, adv),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
