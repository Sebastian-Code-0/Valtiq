import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Una opción de [SelectorPildoras].
class OpcionPildora {
  const OpcionPildora(this.nombre, [this.icono]);

  final String nombre;
  final IconData? icono;
}

/// Fila de botones tipo píldora para cambiar de sección dentro de una
/// pantalla (Ajustes, Deudas). La elegida va rellena con el color de marca.
///
/// Con ratón no se puede arrastrar una fila para deslizarla, así que en
/// pantallas anchas (PC, tablet) las píldoras se acomodan en las líneas que
/// hagan falta. En celular van en una sola fila que se desliza con el dedo,
/// para no gastar media pantalla.
class SelectorPildoras extends StatelessWidget {
  const SelectorPildoras({
    super.key,
    required this.opciones,
    required this.seleccionada,
    required this.onElegir,
    this.margen = AppSpacing.md,
    this.repartirEnCelular = false,
  });

  final List<OpcionPildora> opciones;
  final int seleccionada;
  final ValueChanged<int> onElegir;

  /// Margen a izquierda y derecha.
  final double margen;

  /// En celular, repartir el ancho entre las píldoras (todas a la vista, sin
  /// deslizar). Solo para selectores de pocas opciones (2 o 3).
  final bool repartirEnCelular;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final theme = Theme.of(context);
    Widget pildora(int i) {
      final elegida = i == seleccionada;
      final color = elegida ? c.sobreAcento : c.texto;
      final icono = opciones[i].icono;
      return Semantics(
        button: true,
        selected: elegida,
        child: Material(
          color: elegida ? c.acentoRelleno : Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(
              color: elegida ? c.acentoRelleno : c.divisor,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onElegir(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icono != null) ...[
                    Icon(icono, size: 18, color: color),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        opciones[i].nombre,
                        maxLines: 1,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: margen),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < opciones.length; i++)
                  SizedBox(height: 44, child: pildora(i)),
              ],
            ),
          );
        }
        if (repartirEnCelular) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: margen),
            child: SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < opciones.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: pildora(i)),
                  ],
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: margen),
            itemCount: opciones.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => pildora(i),
          ),
        );
      },
    );
  }
}
