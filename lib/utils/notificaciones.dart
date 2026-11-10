import 'package:flutter/material.dart';

import '../theme/theme.dart';

void _mostrar(
  BuildContext context,
  String mensaje,
  IconData icono,
  Color color, {
  Duration? duracion,
}) {
  // El verde y el rojo del tema oscuro son claros: con texto blanco encima
  // no se leen. Se elige texto claro u oscuro según el fondo del aviso.
  final textoAviso =
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? AppColors.sobreVino
      : AppColors.textoClaro;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: color,
      duration: duracion ?? const Duration(seconds: 4),
      content: Row(
        children: [
          Icon(icono, color: textoAviso, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: textoAviso)),
          ),
        ],
      ),
    ),
  );
}

void mostrarExito(BuildContext context, String mensaje, {Duration? duracion}) {
  _mostrar(
    context,
    mensaje,
    Icons.check_circle_outline,
    context.colores.positivo,
    duracion: duracion,
  );
}

void mostrarAlerta(BuildContext context, String mensaje, {Duration? duracion}) {
  _mostrar(
    context,
    mensaje,
    Icons.error_outline,
    context.colores.alerta,
    duracion: duracion,
  );
}

void mostrarInfo(BuildContext context, String mensaje, {Duration? duracion}) {
  _mostrar(
    context,
    mensaje,
    Icons.info_outline,
    context.colores.acentoRelleno,
    duracion: duracion,
  );
}
