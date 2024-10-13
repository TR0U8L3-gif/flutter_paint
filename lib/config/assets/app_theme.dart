import 'package:flutter/material.dart';
import 'package:flutter_paint/config/assets/app_colors.dart';

class AppTheme {
  static ThemeData getTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: AppColorScheme.getColorScheme(brightness),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

class AppColorScheme {
  static ColorScheme getColorScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );
  }
}
