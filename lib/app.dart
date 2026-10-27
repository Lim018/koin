import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/home_shell.dart';

class KoinApp extends StatelessWidget {
  const KoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Indonesian Material strings (date pickers, tooltips).
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeShell(),
    );
  }
}
