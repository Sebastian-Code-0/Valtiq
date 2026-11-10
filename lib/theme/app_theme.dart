import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract class AppTheme {
  static ThemeData light() => _construir(Brightness.light, ValtiqColores.claro);

  static ThemeData dark() => _construir(Brightness.dark, ValtiqColores.oscuro);

  /// Un solo constructor para ambos temas: los dos se arman igual y solo
  /// cambian los colores de [c]. Así no se desincronizan.
  static ThemeData _construir(Brightness brillo, ValtiqColores c) {
    final esOscuro = brillo == Brightness.dark;
    final esquema = esOscuro
        ? ColorScheme.dark(
            primary: c.acento,
            secondary: c.secundario,
            error: c.alerta,
            surface: c.superficie,
            onSurface: c.texto,
            onPrimary: c.sobreAcento,
          )
        : ColorScheme.light(
            primary: c.acento,
            secondary: c.secundario,
            error: c.alerta,
            surface: c.superficie,
            onSurface: c.texto,
            onPrimary: c.sobreAcento,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brillo,
      extensions: [c],
      splashFactory: InkRipple.splashFactory,
      splashColor: c.acento.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
      colorScheme: esquema,
      scaffoldBackgroundColor: c.fondo,
      textTheme: textTheme().apply(bodyColor: c.texto, displayColor: c.texto),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.texto,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: c.superficie,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: c.textoSecundario.withValues(alpha: 0.12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.secundario,
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
        fillColor: c.superficie,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divisor, thickness: 0.5),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.superficie,
        selectedItemColor: c.acento,
        unselectedItemColor: c.textoSecundario,
      ),
    );
  }
}
