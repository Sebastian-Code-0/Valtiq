import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract class AppTheme {
  static const _textoBoton = TextStyle(
    fontFamily: fuenteTexto,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static OutlineInputBorder _bordeCampo(Color color, [double ancho = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCampo),
        borderSide: BorderSide(color: color, width: ancho),
      );

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
            onSecondary: c.sobreAcento,
            onError: c.sobreAcento,
            surfaceTint: Colors.transparent,
          )
        : ColorScheme.light(
            primary: c.acento,
            secondary: c.secundario,
            error: c.alerta,
            surface: c.superficie,
            onSurface: c.texto,
            onPrimary: c.sobreAcento,
            onSecondary: c.sobreAcento,
            onError: c.sobreAcento,
            surfaceTint: Colors.transparent,
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusTarjeta),
          side: BorderSide(color: c.divisor, width: AppSpacing.borde),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDialogo),
          side: BorderSide(color: c.divisor, width: AppSpacing.borde),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusRecuadro),
          side: BorderSide(color: c.divisor, width: AppSpacing.borde),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusRecuadro),
        ),
        contentTextStyle: TextStyle(color: c.sobreAcento),
      ),
      // Todos los botones son píldoras de al menos 44 px de alto.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.acentoRelleno,
          foregroundColor: c.sobreAcento,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
          textStyle: _textoBoton,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.acentoRelleno,
          foregroundColor: c.sobreAcento,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
          textStyle: _textoBoton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.texto,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const StadiumBorder(),
          side: BorderSide(color: c.divisor, width: AppSpacing.borde),
          textStyle: _textoBoton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.acento,
          shape: const StadiumBorder(),
          textStyle: _textoBoton,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.relieve,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          fontFamily: fuenteTexto,
          fontSize: 13,
          color: c.texto,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.acentoRelleno,
        foregroundColor: c.sobreAcento,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
      ),
      // Campos de texto: fondo un poco más marcado que la tarjeta, borde
      // fino y esquinas redondeadas.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.relieve,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: c.textoSecundario),
        border: _bordeCampo(c.divisor),
        enabledBorder: _bordeCampo(c.divisor),
        disabledBorder: _bordeCampo(c.divisor.withValues(alpha: 0.5)),
        focusedBorder: _bordeCampo(c.acento, 1.5),
        errorBorder: _bordeCampo(c.alerta),
        focusedErrorBorder: _bordeCampo(c.alerta, 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.sobreAcento : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.acentoRelleno : null,
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divisor, thickness: 0.5),
    );
  }
}
