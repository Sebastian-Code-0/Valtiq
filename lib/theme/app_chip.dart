import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.neutra = false});

  final String label;

  /// Etiqueta gris (un dato, como la tasa) en vez de la del color de marca.
  final bool neutra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: ShapeDecoration(
        color: neutra ? c.relieve : c.acentoSuave,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: theme.textTheme.bodySmall?.copyWith(
          color: neutra ? c.textoSecundario : c.acento,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AtenuableCard extends StatelessWidget {
  const AtenuableCard({super.key, required this.atenuada, required this.child});

  final bool atenuada;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return atenuada ? Opacity(opacity: 0.6, child: child) : child;
  }
}
