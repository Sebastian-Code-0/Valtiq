import 'package:flutter/material.dart';

import '../theme/theme.dart';

void _mostrar(
  BuildContext context,
  String mensaje,
  IconData icono,
  Color color, {
  Duration? duracion,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: color,
      duration: duracion ?? const Duration(seconds: 4),
      content: Row(
        children: [
          Icon(icono, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(mensaje)),
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
    AppColors.positivo,
    duracion: duracion,
  );
}

void mostrarAlerta(BuildContext context, String mensaje, {Duration? duracion}) {
  _mostrar(
    context,
    mensaje,
    Icons.error_outline,
    AppColors.alerta,
    duracion: duracion,
  );
}

void mostrarInfo(BuildContext context, String mensaje, {Duration? duracion}) {
  _mostrar(
    context,
    mensaje,
    Icons.info_outline,
    Theme.of(context).colorScheme.primary,
    duracion: duracion,
  );
}
