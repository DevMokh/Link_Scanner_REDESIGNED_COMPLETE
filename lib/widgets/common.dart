import 'package:flutter/material.dart';

import '../core/theme.dart';

/// حاوية بطاقة موحّدة بحدود خضراء وإضاءة هادئة.
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
    final edge = borderColor ?? alpha(C.line, 0.82);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0B1B10), C.surface, Color(0xFF040B06)],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: alpha(borderColor ?? C.emerald, 0.075),
            blurRadius: 16,
            spreadRadius: 0.5,
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 11),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 17,
            decoration: BoxDecoration(
              color: C.emerald,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: alpha(C.emerald, 0.7), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: C.text,
                fontSize: 15,
                fontWeight: FontWeight.w900,
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
        borderSide: BorderSide(color: c, width: 1.1),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: C.muted, fontSize: 13),
    filled: true,
    fillColor: const Color(0xFF030A05),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.all(15),
    enabledBorder: border(alpha(C.line, 0.9)),
    focusedBorder: border(C.emerald),
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
      side: BorderSide(color: alpha(C.emerald, 0.55)),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

ButtonStyle filledButtonStyle() => FilledButton.styleFrom(
      backgroundColor: C.emerald,
      foregroundColor: C.onAccent,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
      elevation: 5,
      shadowColor: alpha(C.emerald, 0.4),
    );
