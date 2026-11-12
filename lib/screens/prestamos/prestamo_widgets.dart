import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';

/// Iniciales para el círculo: "Pedro Gómez" → "PG".
String inicialesDe(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return partes.take(2).map((p) => p.substring(0, 1).toUpperCase()).join();
}

/// Círculo con las iniciales de la persona a la que se le prestó.
class AvatarPersona extends StatelessWidget {
  const AvatarPersona({super.key, required this.nombre, this.lado = 40});

  final String nombre;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final iniciales = inicialesDe(nombre);
    return Container(
      width: lado,
      height: lado,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.relieve, shape: BoxShape.circle),
      child: iniciales.isEmpty
          ? Icon(Icons.person_outline, size: lado * 0.5, color: c.texto)
          : Text(
              iniciales,
              style: TextStyle(
                fontFamily: fuenteTexto,
                fontSize: lado * 0.32,
                fontWeight: FontWeight.w700,
                color: c.texto,
              ),
            ),
    );
  }
}

/// "2,5% mensual", "24% anual" o "Sin interés".
String etiquetaTasaPrestamo(Prestamo p) {
  if (p.tasaInteres <= 0 || p.tipoInteres == 'ninguno') return 'Sin interés';
  final t = p.tasaInteres;
  final numero =
      (t == t.truncateToDouble() ? t.toStringAsFixed(0) : t.toStringAsFixed(2))
          .replaceAll('.', ',');
  return '$numero% ${p.tipoInteres}';
}
