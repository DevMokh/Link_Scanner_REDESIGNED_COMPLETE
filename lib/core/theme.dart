import 'package:flutter/material.dart';

import 'models.dart';

/// الهوية البصرية لكاشف الروابط: أسود عميق وأخضر نيون.
class C {
  C._();

  static const Color bg = Color(0xFF020704);
  static const Color surface = Color(0xFF07130B);
  static const Color surface2 = Color(0xFF0B1D11);
  static const Color line = Color(0xFF087A35);
  static const Color emerald = Color(0xFF00F566);
  static const Color emeraldSoft = Color(0xFF14C968);
  static const Color lime = Color(0xFF8CFF4A);
  static const Color amber = Color(0xFFFFC857);
  static const Color orange = Color(0xFFFF8A3D);
  static const Color red = Color(0xFFFF354D);
  static const Color text = Color(0xFFF0FFF4);
  static const Color muted = Color(0xFF9AB6A2);
  static const Color onAccent = Color(0xFF001B09);
}

/// لون بشفافية (بدون withOpacity لتفادي اختلاف نسخ Flutter)
Color alpha(Color c, double o) => c.withAlpha((o * 255).round());

Color levelColor(RiskLevel l) {
  switch (l) {
    case RiskLevel.low:
      return C.emerald;
    case RiskLevel.medium:
      return C.amber;
    case RiskLevel.high:
      return C.orange;
    case RiskLevel.critical:
      return C.red;
  }
}

Color severityColor(Severity s) {
  switch (s) {
    case Severity.good:
      return C.emerald;
    case Severity.info:
      return C.muted;
    case Severity.warn:
      return C.amber;
    case Severity.danger:
      return C.red;
  }
}

IconData severityIcon(Severity s) {
  switch (s) {
    case Severity.good:
      return Icons.check_circle_rounded;
    case Severity.info:
      return Icons.info_rounded;
    case Severity.warn:
      return Icons.warning_amber_rounded;
    case Severity.danger:
      return Icons.dangerous_rounded;
  }
}

String fmtTime(DateTime t) {
  String two(int n) => n < 10 ? '0$n' : '$n';
  return '${t.day}/${t.month}  ${two(t.hour)}:${two(t.minute)}';
}

ThemeData buildTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: C.emerald,
    brightness: Brightness.dark,
  );
  final scheme = base.copyWith(
    primary: C.emerald,
    onPrimary: C.onAccent,
    secondary: C.lime,
    surface: C.surface,
    onSurface: C.text,
    error: C.red,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    appBarTheme: const AppBarThemeData(
      backgroundColor: C.bg,
      foregroundColor: C.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: C.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: rounded.copyWith(
        side: const BorderSide(color: C.line, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerColor: alpha(C.emerald, 0.22),
    iconTheme: const IconThemeData(color: C.emerald),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: C.text, fontWeight: FontWeight.w900),
      titleMedium: TextStyle(color: C.text, fontWeight: FontWeight.w800),
      bodyLarge: TextStyle(color: C.text),
      bodyMedium: TextStyle(color: C.text),
      bodySmall: TextStyle(color: C.muted),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF030A05),
      indicatorColor: alpha(C.emerald, 0.18),
      surfaceTintColor: Colors.transparent,
      height: 70,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? C.emerald : C.muted,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? C.emerald : C.muted,
          )),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.surface2,
      contentTextStyle: TextStyle(color: C.text),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface2,
      surfaceTintColor: Colors.transparent,
      shape: rounded.copyWith(
        side: BorderSide(color: alpha(C.emerald, 0.45)),
      ),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      width: 310,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.emerald,
        foregroundColor: C.onAccent,
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.text,
        side: const BorderSide(color: C.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
  );
}
