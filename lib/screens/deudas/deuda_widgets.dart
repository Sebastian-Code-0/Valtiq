import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import '../../utils/tipo_deuda.dart';

/// Cuadro de imagen de una deuda. Por ahora muestra un ícono según el tipo
/// (persona, tarjeta, banco…); cuando exista la galería de imágenes, aquí
/// irá la foto o el logo de cada deuda.
class ImagenDeuda extends StatelessWidget {
  const ImagenDeuda({super.key, required this.tipo, this.lado = 44});

  /// `Deudas.tipo` tal como está guardado.
  final String tipo;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color: c.acentoSuave,
        borderRadius: BorderRadius.circular(lado * 0.32),
      ),
      child: Icon(
        TipoDeuda.desdeClave(tipo).icono,
        size: lado * 0.5,
        color: c.acento,
      ),
    );
  }
}

String _numero(double t) =>
    t == t.truncateToDouble() ? t.toStringAsFixed(0) : t.toStringAsFixed(2);

/// "42% anual", "2,5% mensual" o "Sin interés".
String etiquetaTasa(Deuda deuda) {
  if (deuda.tasaInteres <= 0 || deuda.tipoInteres == 'ninguno') {
    return 'Sin interés';
  }
  return '${_numero(deuda.tasaInteres).replaceAll('.', ',')}% '
      '${deuda.tipoInteres}';
}

/// "12 nov" si es de este año; "12 nov 2025" si no.
String fechaCorta(DateTime fecha, DateTime hoy) => fecha.year == hoy.year
    ? formatDiaMesCorto(fecha)
    : '${formatDiaMesCorto(fecha)} ${fecha.year}';
