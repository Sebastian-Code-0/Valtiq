import 'package:flutter/material.dart';

import 'app_colors.dart';

extension AppThemeExtension on ThemeData {
  Color get colorSecundario => brightness == Brightness.dark
      ? AppColors.textoSecundarioOscuro
      : AppColors.textoSecundarioClaro;
}
