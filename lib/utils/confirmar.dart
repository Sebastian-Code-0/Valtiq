import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Ventana de confirmación con el estilo de la app. Devuelve `true` solo si
/// se toca el botón de confirmar. Con [peligro], ese botón va en rojo (para
/// lo que borra).
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String accion,
  bool peligro = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final c = ctx.colores;
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  mensaje,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: c.textoSecundario,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: AppSpacing.sm,
                  overflowSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: peligro
                          ? FilledButton.styleFrom(
                              backgroundColor: c.alerta,
                              foregroundColor: c.fondo,
                            )
                          : null,
                      child: Text(accion),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return ok == true;
}
