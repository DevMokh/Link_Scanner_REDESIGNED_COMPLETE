import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_info.dart';
import 'core/theme.dart';
import 'screens/home_shell.dart';

class LinkScannerApp extends StatelessWidget {
  const LinkScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = buildTheme();
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeShell(),
    );
  }
}
