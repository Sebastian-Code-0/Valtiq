import 'package:flutter/material.dart';

import 'app_colors.dart';

extension AppThemeExtension on ThemeData {
  Color get colorSecundario =>
      (extension<ValtiqColores>() ??
              (brightness == Brightness.dark
                  ? ValtiqColores.oscuro
                  : ValtiqColores.claro))
          .textoSecundario;
}
