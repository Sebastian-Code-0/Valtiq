import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'settings_screen.dart';

/// Cuerpo común de una sección de Ajustes: una columna centrada que no se
/// estira de más en pantallas anchas (mismo ancho que los formularios).
class PaginaAjustes extends StatelessWidget {
  const PaginaAjustes({
    super.key,
    required this.titulo,
    required this.children,
    this.anchoMaximo = 760,
  });

  /// Solo se ve cuando la sección se abre como página suelta.
  final String titulo;
  final List<Widget> children;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraAjustes(context, titulo),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: anchoMaximo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una sola tarjeta con varias filas separadas por una línea fina (como
/// las listas de Finanzas), con título opcional.
class TarjetaFilas extends StatelessWidget {
  const TarjetaFilas({super.key, required this.children, this.titulo});

  final String? titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titulo != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                child: Text(
                  titulo!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            for (final (i, hijo) in children.indexed) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 22,
                  endIndent: 22,
                  color: c.divisor,
                ),
              hijo,
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila de [TarjetaFilas]: ícono en recuadro, título, explicación y algo a
/// la derecha (interruptor, flecha, valor). [abajo] va debajo del texto
/// (por ejemplo unas píldoras o una barra).
class FilaAjuste extends StatelessWidget {
  const FilaAjuste({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.trailing,
    this.abajo,
    this.onTap,
    this.colorIcono,
  });

  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Widget? trailing;
  final Widget? abajo;
  final VoidCallback? onTap;
  final Color? colorIcono;

  /// Fila con interruptor: tocar cualquier parte lo cambia.
  factory FilaAjuste.interruptor({
    Key? key,
    required IconData icono,
    required String titulo,
    String? subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) => FilaAjuste(
    key: key,
    icono: icono,
    titulo: titulo,
    subtitulo: subtitulo,
    onTap: () => onChanged(!valor),
    trailing: Switch(value: valor, onChanged: onChanged),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 14, 12),
        child: Row(
          crossAxisAlignment: abajo == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorIcono?.withValues(alpha: 0.14) ?? c.relieve,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icono,
                size: 18,
                color: colorIcono ?? c.textoSecundario,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitulo != null)
                    Text(
                      subtitulo!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.textoSecundario,
                      ),
                    ),
                  if (abajo != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    abajo!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Aviso informativo discreto: se ve como una tarjeta más (sin rojo), solo
/// el ícono lleva el color de marca. Igual que el del Plan de pago.
class AvisoDiscreto extends StatelessWidget {
  const AvisoDiscreto({
    super.key,
    required this.texto,
    this.titulo,
    this.icono = Icons.info_outline,
    this.accion,
  });

  final String? titulo;
  final String texto;
  final IconData icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRecuadro),
        border: Border.all(color: c.divisor, width: AppSpacing.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: c.acento),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null) ...[
                  Text(
                    titulo!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  texto,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.45,
                    color: c.textoSecundario,
                  ),
                ),
                if (accion != null) ...[
                  const SizedBox(height: AppSpacing.sm + 4),
                  accion!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
