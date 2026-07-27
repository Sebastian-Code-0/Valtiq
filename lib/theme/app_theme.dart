import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract class AppTheme {
  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
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
    );
  }

  static ThemeData light([Color acento = AppColors.acento]) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      splashFactory: InkRipple.splashFactory,
      splashColor: acento.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        primary: acento,
        secondary: AppColors.primario,
        error: AppColors.alerta,
        surface: AppColors.superficieClaro,
        onSurface: AppColors.textoClaro,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.fondoClaro,
      textTheme: textTheme().apply(
        bodyColor: AppColors.textoClaro,
        displayColor: AppColors.textoClaro,
      ),
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
      elevatedButtonTheme: _elevatedButtonTheme(),
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.superficieClaro,
        selectedItemColor: acento,
        unselectedItemColor: AppColors.textoSecundarioClaro,
      ),
    );
  }

  static ThemeData dark([Color acento = AppColors.acento]) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      splashFactory: InkRipple.splashFactory,
      splashColor: acento.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: acento,
        secondary: AppColors.primario,
        error: AppColors.alerta,
        surface: AppColors.superficieOscuro,
        onSurface: AppColors.textoOscuro,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.fondoOscuro,
      textTheme: textTheme().apply(
        bodyColor: AppColors.textoOscuro,
        displayColor: AppColors.textoOscuro,
      ),
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
      elevatedButtonTheme: _elevatedButtonTheme(),
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.superficieOscuro,
        selectedItemColor: acento,
        unselectedItemColor: AppColors.textoSecundarioOscuro,
      ),
    );
  }
}
