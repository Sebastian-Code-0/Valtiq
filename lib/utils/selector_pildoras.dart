import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Una opción de [SelectorPildoras].
class OpcionPildora {
  const OpcionPildora(this.nombre, [this.icono]);

  final String nombre;
  final IconData? icono;
}

/// Una píldora de un selector. La elegida va rellena con el color del texto
/// (clara en tema oscuro, negra en tema claro); las demás, sin fondo.
class _Pildora extends StatelessWidget {
  const _Pildora({
    required this.nombre,
    required this.elegida,
    required this.onTap,
    this.icono,
  });

  final String nombre;
  final IconData? icono;
  final bool elegida;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final color = elegida ? c.fondo : c.textoSecundario;
    return Semantics(
      button: true,
      selected: elegida,
      enabled: onTap != null,
      child: Material(
        color: elegida ? c.texto : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icono != null) ...[
                  Icon(icono, size: 17, color: color),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      nombre,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: fuenteTexto,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: color,
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
}

/// Pista redondeada que contiene las píldoras.
BoxDecoration _pista(BuildContext context, {required bool enTarjeta}) {
  final c = context.colores;
  return BoxDecoration(
    // Dentro de una tarjeta, la pista se marca con el tono de relieve; sobre
    // el fondo de la pantalla, con el color de tarjeta y un borde fino.
    color: enTarjeta ? c.relieve : c.superficie,
    borderRadius: BorderRadius.circular(_altoPildora / 2 + _aire),
    border: enTarjeta
        ? null
        : Border.all(color: c.divisor, width: AppSpacing.borde),
  );
}

const _altoPildora = 38.0;
const _aire = 4.0;

/// Pestañas en forma de píldora para cambiar de sección dentro de una
/// pantalla (Ajustes, Deudas): una pista redondeada con las opciones dentro
/// y la elegida rellena.
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
    this.centrado = false,
  });

  final List<OpcionPildora> opciones;
  final int seleccionada;
  final ValueChanged<int> onElegir;

  /// Margen a izquierda y derecha.
  final double margen;

  /// En celular, repartir el ancho entre las píldoras (todas a la vista, sin
  /// deslizar). Solo para selectores de pocas opciones (2 o 3).
  final bool repartirEnCelular;

  /// Centrar la pista en el ancho disponible (si no lo ocupa todo) en vez
  /// de pegarla a la izquierda.
  final bool centrado;

  @override
  Widget build(BuildContext context) {
    Widget pildora(int i) => _Pildora(
      nombre: opciones[i].nombre,
      icono: opciones[i].icono,
      elegida: i == seleccionada,
      onTap: () => onElegir(i),
    );
    final pista = _pista(context, enTarjeta: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (repartirEnCelular && constraints.maxWidth < 600) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: margen),
            child: Container(
              height: _altoPildora + 2 * _aire,
              padding: const EdgeInsets.all(_aire),
              decoration: pista,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < opciones.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(child: pildora(i)),
                  ],
                ],
              ),
            ),
          );
        }
        // Siempre UNA sola línea. Si las opciones caben, la pista mide lo
        // que ellas; si no caben, la pista ocupa todo el ancho y las
        // opciones se deslizan dentro (con el dedo, o arrastrando con el
        // ratón). Antes, en PC se partían en dos líneas disparejas.
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: margen),
          child: Align(
            alignment: centrado ? Alignment.center : Alignment.centerLeft,
            child: Container(
              height: _altoPildora + 2 * _aire,
              padding: const EdgeInsets.all(_aire),
              decoration: pista,
              clipBehavior: Clip.antiAlias,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: PointerDeviceKind.values.toSet(),
                  scrollbars: false,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < opciones.length; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        SizedBox(
                          height: _altoPildora,
                          child: Builder(
                            builder: (ctx) => _Pildora(
                              nombre: opciones[i].nombre,
                              icono: opciones[i].icono,
                              elegida: i == seleccionada,
                              onTap: () {
                                onElegir(i);
                                // Trae a la vista la opción tocada si estaba
                                // cortada por el borde.
                                Scrollable.ensureVisible(
                                  ctx,
                                  alignment: 0.5,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Selector de una opción entre pocas, para usar DENTRO de una tarjeta o de
/// un formulario (estrategia del plan, tipo de interés…). Hace lo mismo que
/// una lista desplegable, pero con todas las opciones a la vista.
class GrupoPildoras<T> extends StatelessWidget {
  const GrupoPildoras({
    super.key,
    required this.opciones,
    required this.valor,
    required this.onElegir,
  });

  /// Valor → texto que se muestra.
  final Map<T, String> opciones;
  final T valor;

  /// `null` deja el grupo apagado (no se puede cambiar).
  final ValueChanged<T>? onElegir;

  @override
  Widget build(BuildContext context) {
    final activo = onElegir != null;
    return Opacity(
      opacity: activo ? 1 : 0.5,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(_aire),
          decoration: _pista(context, enTarjeta: true),
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [
              for (final o in opciones.entries)
                SizedBox(
                  height: _altoPildora,
                  child: _Pildora(
                    nombre: o.value,
                    elegida: o.key == valor,
                    onTap: activo ? () => onElegir!(o.key) : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
