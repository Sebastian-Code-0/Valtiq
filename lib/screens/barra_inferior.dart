import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Una sección de la barra inferior del celular.
class ItemBarraInferior {
  const ItemBarraInferior(
    this.nombre,
    this.icono,
    this.iconoElegido, {
    this.nombreCompleto,
    this.contador = 0,
  });

  /// Texto corto que cabe debajo del ícono.
  final String nombre;
  final IconData icono;
  final IconData iconoElegido;

  /// Nombre real de la sección si [nombre] es una abreviación (para el
  /// texto de ayuda y los lectores de pantalla).
  final String? nombreCompleto;

  /// Número de la insignia (0 = sin insignia).
  final int contador;
}

/// Barra de secciones del celular: una píldora que "flota", separada de los
/// bordes y del fondo de la pantalla. La sección elegida lleva un fondo
/// tenue del color de marca.
class BarraInferior extends StatelessWidget {
  const BarraInferior({
    super.key,
    required this.items,
    required this.indice,
    required this.onElegir,
  });

  final List<ItemBarraInferior> items;
  final int indice;
  final ValueChanged<int> onElegir;

  /// Separación de la barra con los lados y con el fondo de la pantalla.
  static const margen = 12.0;

  /// Alto de la franja que desvanece el contenido justo encima de la barra.
  static const _altoVelo = 20.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // El contenido no se corta en seco al llegar a la barra: se
        // desvanece hacia el color del fondo.
        Positioned(
          left: 0,
          right: 0,
          top: -_altoVelo,
          height: _altoVelo,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.fondo.withValues(alpha: 0), c.fondo],
                ),
              ),
            ),
          ),
        ),
        ColoredBox(
          color: c.fondo,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(margen, 0, margen, margen),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: c.superficie,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: c.divisor, width: AppSpacing.borde),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: oscuro ? 0.5 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (final (i, item) in items.indexed)
                    Expanded(
                      child: _Boton(
                        item: item,
                        elegido: i == indice,
                        onTap: () => onElegir(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Boton extends StatelessWidget {
  const _Boton({
    required this.item,
    required this.elegido,
    required this.onTap,
  });

  final ItemBarraInferior item;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final color = elegido ? c.acento : c.textoSecundario;
    return Semantics(
      selected: elegido,
      button: true,
      label: item.nombreCompleto ?? item.nombre,
      child: Tooltip(
        message: item.nombreCompleto ?? item.nombre,
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: elegido ? c.acentoSuave : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        elegido ? item.iconoElegido : item.icono,
                        size: 22,
                        color: color,
                      ),
                      if (item.contador > 0)
                        Positioned(
                          top: -4,
                          left: 14,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16),
                            height: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: ShapeDecoration(
                              color: c.acentoRelleno,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              item.contador > 99 ? '99+' : '${item.contador}',
                              style: TextStyle(
                                fontSize: 10,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: c.sobreAcento,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Si el texto no cabe (letra grande del sistema), se
                  // encoge en vez de cortarse.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.nombre,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: fuenteTexto,
                        fontSize: 10.5,
                        height: 1.2,
                        fontWeight: elegido ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
