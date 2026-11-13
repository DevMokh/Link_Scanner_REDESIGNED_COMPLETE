import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_info.dart';
import '../core/theme.dart';
import '../services/settings_store.dart';
import 'brand_logo.dart';

/// القائمة الجانبية: كل بند بيودّي لوجهة حقيقية موجودة في التطبيق (مفيش بنود شكلية).
/// ترتيب التبويبات: 0 الرئيسية، 1 رابط، 2 رسالة، 3 السجل، 4 المزيد.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.selectedTab,
    required this.onTab,
    required this.onQr,
    required this.onImage,
    required this.onSender,
    required this.onBatch,
    required this.onTrain,
    required this.onLearn,
    required this.onSettings,
    this.onExit,
  });

  final int selectedTab;
  final void Function(int tab) onTab;
  final VoidCallback onQr;
  final VoidCallback onImage;
  final VoidCallback onSender;
  final VoidCallback onBatch;
  final VoidCallback onTrain;
  final VoidCallback onLearn;
  final VoidCallback onSettings;

  /// الخروج من التطبيق. الافتراضي: إغلاق النشاط (SystemNavigator.pop).
  final VoidCallback? onExit;

  static String _t(String ar, String en) =>
      SettingsStore.instance.english ? en : ar;

  /// بيقفل القائمة الأول وبعدين بينفّذ الوجهة (عشان الصفحة الجديدة متتفتحش فوق القائمة).
  void _go(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback action, {
    bool selected = false,
  }) {
    final fg = selected ? C.onAccent : C.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _go(context, action),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(colors: <Color>[C.accentDeep, C.accent])
                  : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected ? glow(C.accent, opacity: 0.3, blur: 14) : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? C.onAccent : C.accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        return Drawer(
          backgroundColor: C.bg,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[alpha(C.accent, 0.14), C.bg],
                    ),
                  ),
                  child: Column(
                    children: [
                      const LinkScannerLogo(size: 76),
                      const SizedBox(height: 10),
                      const Text(
                        kAppNameAr,
                        style: TextStyle(
                          color: C.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        kAppNameEn,
                        style: TextStyle(
                          color: C.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      _item(context, Icons.home_rounded, _t('الرئيسية', 'Home'),
                          () => onTab(0),
                          selected: selectedTab == 0),
                      _item(context, Icons.link_rounded,
                          _t('فحص الروابط', 'Scan links'), () => onTab(1),
                          selected: selectedTab == 1),
                      _item(
                          context,
                          Icons.mark_email_unread_rounded,
                          _t('فحص الرسائل', 'Scan messages'),
                          () => onTab(2),
                          selected: selectedTab == 2),
                      _item(context, Icons.qr_code_scanner_rounded,
                          _t('فحص رمز QR', 'Scan a QR code'), onQr),
                      _item(context, Icons.image_search_rounded,
                          _t('فحص الصور', 'Scan an image'), onImage),
                      _item(context, Icons.alternate_email_rounded,
                          _t('فحص المرسل', 'Check a sender'), onSender),
                      _item(context, Icons.playlist_add_check_rounded,
                          _t('الفحص المجمّع', 'Batch scan'), onBatch),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Divider(),
                      ),
                      _item(context, Icons.history_rounded,
                          _t('سجل الفحوصات', 'Scan history'), () => onTab(3),
                          selected: selectedTab == 3),
                      _item(context, Icons.sports_esports_rounded,
                          _t('تدرّب على الكشف', 'Train your detection'), onTrain),
                      _item(context, Icons.school_rounded,
                          _t('دروس الحماية', 'Protection lessons'), onLearn),
                      _item(
                          context,
                          Icons.apps_rounded,
                          _t('أدوات الأمان الإضافية', 'More security tools'),
                          () => onTab(4),
                          selected: selectedTab == 4),
                      _item(context, Icons.settings_rounded,
                          _t('الإعدادات', 'Settings'), onSettings),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Column(
                    children: [
                      Text(
                        '${_t('الإصدار', 'Version')} $kAppVersion ($kAppBuild)',
                        style: const TextStyle(color: C.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onExit ?? () => SystemNavigator.pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: C.text,
                            side: BorderSide(color: alpha(C.accent, 0.45)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: Text(_t('خروج', 'Exit')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
