import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../services/inbox.dart';
import '../services/message_analyzer.dart';
import '../services/qr_analyzer.dart';
import '../services/settings_store.dart';
import '../services/strings.dart';
import '../widgets/common.dart';
import '../widgets/scale_header.dart';
import 'history_screen.dart';
import 'home_dashboard.dart';
import 'image_scan_screen.dart';
import 'message_scan_screen.dart';
import 'more_screen.dart';
import 'qr_scan_screen.dart';
import 'url_scan_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  String _lastClip = '';

  // ترتيب التبويبات: 0 الرئيسية، 1 رابط، 2 رسالة، 3 السجل، 4 المزيد.
  List<Widget> get _pages => <Widget>[
        HomeDashboard(
          onTab: (i) => setState(() => _index = i),
          onQr: _openQr,
          onImage: _openImage,
          onTrain: () => openTrain(context),
          onLearn: () => openLearn(context),
          onSettings: () => openSettings(context),
          onMenu: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const UrlScanScreen(),
        const MessageScanScreen(),
        const HistoryScreen(),
        MoreScreen(onQr: _openQr, onImage: _openImage),
      ];

  /// مسح QR من أي مكان: لو فيه رابط يتفحص في تبويب الرابط، وغير كده نعرض المحتوى.
  Future<void> _openQr() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScanScreen()),
    );
    if (raw == null || !mounted) return;
    final info = QrAnalyzer.classify(raw);
    if (info.link != null) {
      setState(() => _index = 1);
      Inbox.toUrl.value = Incoming(info.link!);
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
              SelectableText(
                info.raw,
                style: const TextStyle(color: C.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  void _openImage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ImageScanScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Inbox.shared.addListener(_onShared);
    Inbox.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboard());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Inbox.shared.removeListener(_onShared);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  /// نص جاي من "مشاركة" أو تحديد نص: رابط واحد -> فحص رابط، غير كده -> فحص رسالة
  void _onShared() {
    final inc = Inbox.shared.value;
    if (inc == null) return;
    final text = inc.text;
    final links = MessageAnalyzer.extractLinks(text);
    final singleLink = links.length == 1 && (text.length - links.first.length) < 12;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (singleLink) {
        setState(() => _index = 1);
        Inbox.toUrl.value = Incoming(links.first);
      } else {
        setState(() => _index = 2);
        Inbox.toMessage.value = Incoming(text);
      }
    });
  }

  Future<void> _checkClipboard() async {
    if (!SettingsStore.instance.clipWatch) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    try {
      final d = await Clipboard.getData(Clipboard.kTextPlain);
      final t = d?.text?.trim();
      if (t == null || t.isEmpty || t == _lastClip) return;
      _lastClip = t;
      final links = MessageAnalyzer.extractLinks(t);
      if (links.isEmpty || !mounted) return;
      final first = links.first;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: const Text('في رابط منسوخ. تحب تفحصه؟'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'افحص',
          textColor: C.emerald,
          onPressed: () {
            setState(() => _index = 1);
            Inbox.toUrl.value = Incoming(first);
          },
        ),
      ));
    } catch (_) {
      // أندرويد منع قراءة الحافظة الآن: نتجاهل
    }
  }

  void _selectTab(int index) {
    Navigator.of(context).pop();
    setState(() => _index = index);
  }

  Widget _buildDrawer(BuildContext context) {
    Widget item(IconData icon, String title, int index) {
      final selected = _index == index;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          selected: selected,
          selectedTileColor: alpha(C.emerald, 0.14),
          leading: Icon(icon, color: selected ? C.emerald : C.muted),
          title: Text(title, style: TextStyle(
            color: selected ? C.emerald : C.text,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 13,
          )),
          trailing: selected ? const Icon(Icons.chevron_left_rounded, color: C.emerald) : null,
          onTap: () => _selectTab(index),
        ),
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A3518), C.surface, C.surface],
                ),
                border: Border(bottom: BorderSide(color: alpha(C.emerald, 0.45))),
              ),
              child: const Column(
                children: [
                  LinkShieldMark(size: 78),
                  SizedBox(height: 9),
                  Text('كاشف الروابط', style: TextStyle(color: C.text, fontSize: 19, fontWeight: FontWeight.w900)),
                  SizedBox(height: 3),
                  Text('Link Scanner', style: TextStyle(color: C.emerald, fontSize: 13, fontWeight: FontWeight.w900)),
                  SizedBox(height: 5),
                  Text('أمانك يبدأ بالفحص', style: TextStyle(color: C.muted, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  item(Icons.home_rounded, 'الرئيسية', 0),
                  item(Icons.link_rounded, 'فحص الروابط', 1),
                  item(Icons.mark_email_unread_rounded, 'فحص الرسائل', 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    child: ListTile(
                      leading: const Icon(Icons.qr_code_scanner_rounded, color: C.muted),
                      title: const Text('فحص QR', style: TextStyle(color: C.text, fontSize: 13, fontWeight: FontWeight.w600)),
                      onTap: () { Navigator.pop(context); _openQr(); },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    child: ListTile(
                      leading: const Icon(Icons.image_search_rounded, color: C.muted),
                      title: const Text('فحص الصور', style: TextStyle(color: C.text, fontSize: 13, fontWeight: FontWeight.w600)),
                      onTap: () { Navigator.pop(context); _openImage(); },
                    ),
                  ),
                  item(Icons.history_rounded, 'سجل الفحوصات', 3),
                  item(Icons.apps_rounded, 'أدوات الأمان الإضافية', 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(color: C.line),
                  ),
                  ListTile(
                    leading: const Icon(Icons.school_rounded, color: C.muted),
                    title: const Text('دروس الحماية', style: TextStyle(color: C.text, fontSize: 13)),
                    onTap: () { Navigator.pop(context); openLearn(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_rounded, color: C.muted),
                    title: const Text('الإعدادات', style: TextStyle(color: C.text, fontSize: 13)),
                    onTap: () { Navigator.pop(context); openSettings(context); },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alpha(C.emerald, 0.06),
                  border: Border.all(color: alpha(C.emerald, 0.24)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Text('كاشف الروابط • حماية ووعي رقمي', textAlign: TextAlign.center,
                    style: TextStyle(color: C.muted, fontSize: 10.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لـ SettingsStore هنا يخلي الشاشة كلها (وشاشاتها الفرعية) تعيد
    // البناء لما لغة الواجهة تتغيّر من الإعدادات.
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(context),
          body: IndexedStack(index: _index, children: _pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: <NavigationDestination>[
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: tr(S.navHome),
              ),
              NavigationDestination(
                icon: const Icon(Icons.link_rounded),
                selectedIcon: const Icon(Icons.link_rounded),
                label: tr(S.navLink),
              ),
              NavigationDestination(
                icon: const Icon(Icons.mark_email_unread_outlined),
                selectedIcon: const Icon(Icons.mark_email_unread_rounded),
                label: tr(S.navMessage),
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_rounded),
                selectedIcon: const Icon(Icons.history_rounded),
                label: tr(S.navHistory),
              ),
              NavigationDestination(
                icon: const Icon(Icons.apps_outlined),
                selectedIcon: const Icon(Icons.apps_rounded),
                label: tr(S.navMore),
              ),
            ],
          ),
        );
      },
    );
  }
}
