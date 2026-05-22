import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primario,
        secondary: AppColors.acento,
        error: AppColors.alerta,
        surface: AppColors.superficieClaro,
        onSurface: AppColors.textoClaro,
      ),
      scaffoldBackgroundColor: AppColors.fondoClaro,
      textTheme: textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textoClaro,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.superficieClaro,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficieClaro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 0.5,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.superficieClaro,
        selectedItemColor: AppColors.acento,
        unselectedItemColor: AppColors.textoSecundarioClaro,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.acento,
        secondary: AppColors.primario,
        error: AppColors.alerta,
        surface: AppColors.superficieOscuro,
        onSurface: AppColors.textoOscuro,
      ),
      scaffoldBackgroundColor: AppColors.fondoOscuro,
      textTheme: textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textoOscuro,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.superficieOscuro,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficieOscuro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 0.5,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.superficieOscuro,
        selectedItemColor: AppColors.acento,
        unselectedItemColor: AppColors.textoSecundarioOscuro,
      ),
    );
  }
}
