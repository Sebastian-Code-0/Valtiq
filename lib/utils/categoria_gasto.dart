import 'package:flutter/material.dart';

enum CategoriaGasto {
  alimentacion('Alimentación', Icons.restaurant_outlined),
  ropa('Ropa', Icons.checkroom_outlined),
  transporte('Transporte', Icons.directions_bus_outlined),
  entretenimiento('Entretenimiento', Icons.movie_outlined),
  salud('Salud', Icons.health_and_safety_outlined),
  educacion('Educación', Icons.school_outlined),
  hogar('Hogar', Icons.home_outlined),
  otros('Otros', Icons.category_outlined);

  const CategoriaGasto(this.nombre, this.icono);

  final String nombre;
  final IconData icono;

  static List<String> get nombres =>
      values.map((c) => c.nombre).toList(growable: false);

  static IconData iconoPara(String nombre) {
    return values
        .firstWhere((c) => c.nombre == nombre, orElse: () => otros)
        .icono;
  }
}
