import 'package:flutter/material.dart';

/// Fuentes incluidas en `assets/fonts/` (declaradas en pubspec.yaml).
/// Nunca se descargan de internet.
const String fuenteTexto = 'Manrope';
const String fuenteMono = 'JetBrains Mono';

TextTheme textTheme() =>
    ThemeData.light().textTheme.apply(fontFamily: fuenteTexto);

TextStyle monoStyle({double? fontSize, FontWeight? fontWeight, Color? color}) {
  return TextStyle(
    fontFamily: fuenteMono,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}
