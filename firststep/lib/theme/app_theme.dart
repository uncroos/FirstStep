import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.navy,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: base.textTheme.copyWith(
        // 일반 섹션 타이틀
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),

        // 🔥 앱 메인 타이틀 (FirstStep / CheckList)
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontSize: 40, // 기존 대비 약 2배
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),

        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}