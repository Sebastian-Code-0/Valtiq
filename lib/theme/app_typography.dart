import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme textTheme() => GoogleFonts.interTextTheme();

TextStyle monoStyle({double? fontSize, FontWeight? fontWeight, Color? color}) {
  return GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}
