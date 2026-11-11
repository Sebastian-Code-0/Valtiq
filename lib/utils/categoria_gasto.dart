import 'package:flutter/material.dart';

enum CategoriaGasto {
  alimentacion('Alimentación', Icons.restaurant_outlined, Color(0xFFE8935B)),
  ropa('Ropa', Icons.checkroom_outlined, Color(0xFFC77DA3)),
  transporte('Transporte', Icons.directions_bus_outlined, Color(0xFF5B8DBE)),
  entretenimiento('Entretenimiento', Icons.movie_outlined, Color(0xFF8B7FD1)),
  salud('Salud', Icons.health_and_safety_outlined, Color(0xFF6FA88A)),
  educacion('Educación', Icons.school_outlined, Color(0xFFC9A227)),
  hogar('Hogar', Icons.home_outlined, Color(0xFFA6754D)),
  // Agregadas en 2026-11 (las más pedidas). "Otros" queda siempre al final.
  carro('Carro', Icons.directions_car_outlined, Color(0xFF3FA7A0)),
  moto('Moto', Icons.two_wheeler_outlined, Color(0xFF5568C8)),
  mascotas('Mascotas', Icons.pets_outlined, Color(0xFFB8644A)),
  serviciosPublicos(
    'Servicios públicos',
    Icons.lightbulb_outline,
    Color(0xFFD9C23A),
  ),
  restaurantes('Restaurantes', Icons.fastfood_outlined, Color(0xFF8A9A3B)),
  cuidadoPersonal('Cuidado personal', Icons.spa_outlined, Color(0xFFB565B8)),
  tecnologia('Tecnología', Icons.devices_outlined, Color(0xFF4FB3D4)),
  viajes('Viajes', Icons.flight_outlined, Color(0xFF6C7FA8)),
  suscripciones(
    'Suscripciones',
    Icons.subscriptions_outlined,
    Color(0xFFD98A7A),
  ),
  otros('Otros', Icons.category_outlined, Color(0xFF8B93A3));

  const CategoriaGasto(this.nombre, this.icono, this.color);

  final String nombre;
  final IconData icono;
  // Paleta fija, independiente del acento y de la alerta: ninguna categoría
  // debe poder confundirse visualmente con una alerta o con el acento.
  final Color color;

  static List<String> get nombres =>
      values.map((c) => c.nombre).toList(growable: false);

  static IconData iconoPara(String nombre) {
    return values
        .firstWhere((c) => c.nombre == nombre, orElse: () => otros)
        .icono;
  }

  static Color colorPara(String nombre) {
    return values
        .firstWhere((c) => c.nombre == nombre, orElse: () => otros)
        .color;
  }
}
