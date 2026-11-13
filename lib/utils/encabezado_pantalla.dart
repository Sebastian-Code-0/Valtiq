import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Encabezado de una pantalla: una línea pequeña en mayúsculas ([kicker],
/// p. ej. "3 ACTIVAS") y debajo el título grande. A la derecha puede llevar
/// una acción (el botón de crear).
class EncabezadoPantalla extends StatelessWidget {
  const EncabezadoPantalla({
    super.key,
    required this.titulo,
    this.kicker,
    this.accion,
    this.multilinea = false,
  });

  final String titulo;

  /// Si el título no cabe, sigue en el renglón de abajo en vez de cortarse
  /// con "…" (el saludo de Inicio lleva el nombre de la persona).
  final bool multilinea;

  /// Se muestra en mayúsculas; se escribe normal ("3 activas").
  final String? kicker;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    // Título grande en ventanas anchas; más contenido en celular.
    final ancho = MediaQuery.sizeOf(context).width >= 600;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kicker != null) ...[
                TextoKicker(kicker!),
                const SizedBox(height: 6),
              ],
              Text(
                titulo,
                maxLines: multilinea ? null : 1,
                overflow: multilinea ? null : TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: fuenteTexto,
                  fontSize: ancho ? 40 : 30,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: c.texto,
                ),
              ),
            ],
          ),
        ),
        if (accion != null) ...[const SizedBox(width: AppSpacing.md), accion!],
      ],
    );
  }
}

/// Texto pequeño en mayúsculas y con las letras separadas, para rotular.
class TextoKicker extends StatelessWidget {
  const TextoKicker(this.texto, {super.key, this.color});

  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: fuenteTexto,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: color ?? context.colores.textoSecundario,
      ),
    );
  }
}

/// Botón de crear de una pantalla: píldora con texto en ventanas anchas,
/// botón redondo con "+" en celular.
class BotonCrear extends StatelessWidget {
  const BotonCrear({
    super.key,
    required this.texto,
    required this.onPressed,
    this.heroTag,
  });

  /// "Nueva deuda". En celular queda como texto de ayuda del botón.
  final String texto;
  final VoidCallback onPressed;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 600) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: Text(texto),
      );
    }
    return FloatingActionButton.small(
      heroTag: heroTag,
      tooltip: texto,
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}

/// Botón discreto, en rojo, para vaciar un historial (deudas pagadas,
/// préstamos cobrados). Va en la misma fila de las pestañas, a la derecha.
/// En celular es solo el ícono (el texto no cabe junto a las pestañas).
/// Quien lo usa pide la confirmación.
class BotonLimpiarHistorial extends StatelessWidget {
  const BotonLimpiarHistorial({
    super.key,
    required this.onPressed,
    this.texto = 'Limpiar historial',
  });

  final VoidCallback onPressed;

  /// Lo que dice el botón (y su texto de ayuda en celular).
  final String texto;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    if (MediaQuery.sizeOf(context).width < 600) {
      return IconButton(
        onPressed: onPressed,
        tooltip: texto,
        color: c.alerta,
        icon: const Icon(Icons.delete_sweep_outlined),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: c.alerta),
      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
      label: Text(texto),
    );
  }
}
