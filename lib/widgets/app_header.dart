import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'brand_logo.dart';

/// ترويسة الشاشات: كحلي بتدرّج هادي + شعار الدرع (أو أيقونة الأداة لو [icon] اتحدّدت)
/// + العنوان والعنوان الفرعي. مرسومة بالكود: لا صور ولا حقوق.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  final String title;
  final String subtitle;

  /// أيقونة أداة (للشاشات الفرعية). null = شعار التطبيق.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    // لو الـ Scaffold اللي فوقنا ليه قائمة جانبية (تبويبات الشاشة الرئيسية) بنعرض زر القائمة.
    final scaffold = Scaffold.maybeOf(context);
    final hasMenu = scaffold != null && scaffold.hasDrawer;
    final badge = icon == null
        ? const LinkScannerLogo(size: 44, glowing: false)
        : Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: alpha(C.accent, 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: alpha(C.accent, 0.45)),
            ),
            child: Icon(icon, color: C.accent, size: 27),
          );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[alpha(C.accentDeep, 0.28), C.bg],
        ),
        border: Border(bottom: BorderSide(color: alpha(C.accent, 0.18))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, top + 18, 20, 20),
        child: Row(
          children: [
            badge,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: C.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: C.muted, fontSize: 13.5),
                  ),
                ],
              ),
            ),
            if (hasMenu)
              IconButton(
                tooltip: 'القائمة',
                onPressed: () => scaffold?.openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: C.accent),
              ),
          ],
        ),
      ),
    );
  }
}
