import 'package:flutter/material.dart';

enum CategoriaGasto {
  alimentacion('Alimentación', Icons.restaurant_outlined, Color(0xFFE8935B)),
  ropa('Ropa', Icons.checkroom_outlined, Color(0xFFC77DA3)),
  transporte('Transporte', Icons.directions_bus_outlined, Color(0xFF5B8DBE)),
  entretenimiento('Entretenimiento', Icons.movie_outlined, Color(0xFF8B7FD1)),
  salud('Salud', Icons.health_and_safety_outlined, Color(0xFF6FA88A)),
  educacion('Educación', Icons.school_outlined, Color(0xFFC9A227)),
  hogar('Hogar', Icons.home_outlined, Color(0xFFA6754D)),
  otros('Otros', Icons.category_outlined, Color(0xFF8B93A3));

  const CategoriaGasto(this.nombre, this.icono, this.color);

  final String nombre;
  final IconData icono;
  // Paleta fija, independiente de AppColors.acento (el usuario puede cambiar
  // el acento entre 6 presets) y de AppColors.alerta — ninguna categoría debe
  // poder confundirse visualmente con una alerta o con el acento activo.
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
