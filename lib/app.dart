import 'package:flutter/material.dart';

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
      home: const HomeShell(),
    );
  }
}
