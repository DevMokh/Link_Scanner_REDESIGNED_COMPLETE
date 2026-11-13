import 'package:flutter/material.dart';

import '../core/theme.dart';

/// حاوية بطاقة موحّدة (كحلي داكن بحد أزرق هادي)
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: glassDecoration(border: borderColor),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: C.accent,
              borderRadius: BorderRadius.circular(4),
              boxShadow: glow(C.accent, opacity: 0.5, blur: 8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: C.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

InputDecoration fieldDecoration({String? hint, Widget? suffix}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: C.muted, fontSize: 13),
    filled: true,
    fillColor: alpha(C.surface2, 0.8),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.all(14),
    enabledBorder: border(alpha(C.accent, 0.35)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: C.accent, width: 1.6),
    ),
    border: border(C.line),
  );
}

void toast(BuildContext context, String message) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(content: Text(message)));
}

ButtonStyle outlineButtonStyle() => OutlinedButton.styleFrom(
      foregroundColor: C.text,
      side: BorderSide(color: alpha(C.accent, 0.45)),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

ButtonStyle filledButtonStyle() => FilledButton.styleFrom(
      backgroundColor: C.accent,
      foregroundColor: C.onAccent,
      elevation: 6,
      shadowColor: alpha(C.accent, 0.55),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    );

/// زر رئيسي كبير بتدرّج أزرق → سماوي (مثل زر "ابدأ الفحص").
/// لو [onPressed] = null بيتعتّم ومبيستجيبش.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.height = 56,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: <Color>[C.accentDeep, C.accent]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled ? glow(C.accent, opacity: 0.38, blur: 20) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: C.onAccent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: C.onAccent,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
