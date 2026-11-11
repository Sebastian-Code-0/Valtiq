import 'package:flutter/material.dart';

/// Qué clase de deuda es. Por ahora decide el ícono del cuadro de imagen de
/// la tarjeta; cuando exista la galería de imágenes, decidirá la imagen por
/// defecto. Se guarda en `Deudas.tipo` por su [clave].
enum TipoDeuda {
  persona('persona', 'Persona', Icons.person_outline),
  tarjeta('tarjeta', 'Tarjeta de crédito', Icons.credit_card),
  banco('banco', 'Banco o crédito', Icons.account_balance_outlined),
  tienda('tienda', 'Tienda o compra a cuotas', Icons.storefront_outlined),
  otro('otro', 'Otro', Icons.receipt_long_outlined);

  const TipoDeuda(this.clave, this.nombre, this.icono);

  final String clave;
  final String nombre;
  final IconData icono;

  static TipoDeuda desdeClave(String clave) =>
      values.firstWhere((t) => t.clave == clave, orElse: () => otro);
}
