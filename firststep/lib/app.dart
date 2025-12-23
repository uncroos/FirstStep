import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'shell/main_shell.dart';

class FirstStepApp extends StatelessWidget {
  const FirstStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FirstStep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainShell(),
    );
  }
}