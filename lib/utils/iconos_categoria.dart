import 'package:flutter/material.dart';

import 'categoria_gasto.dart';

/// Íconos que se pueden elegir para una categoría. La clave es lo que se
/// guarda en la base (`Categorias.icono`); los íconos van escritos aquí uno
/// por uno porque Flutter solo incluye en la app los que aparecen así en el
/// código.
const iconosCategoria = <String, IconData>{
  // Las de las categorías de fábrica (misma clave que el nombre del enum).
  'alimentacion': Icons.restaurant_outlined,
  'ropa': Icons.checkroom_outlined,
  'transporte': Icons.directions_bus_outlined,
  'entretenimiento': Icons.movie_outlined,
  'salud': Icons.health_and_safety_outlined,
  'educacion': Icons.school_outlined,
  'hogar': Icons.home_outlined,
  'carro': Icons.directions_car_outlined,
  'moto': Icons.two_wheeler_outlined,
  'mascotas': Icons.pets_outlined,
  'serviciosPublicos': Icons.lightbulb_outline,
  'restaurantes': Icons.fastfood_outlined,
  'cuidadoPersonal': Icons.spa_outlined,
  'tecnologia': Icons.devices_outlined,
  'viajes': Icons.flight_outlined,
  'suscripciones': Icons.subscriptions_outlined,
  'otros': Icons.category_outlined,
  // Más para elegir.
  'mercado': Icons.shopping_cart_outlined,
  'cafe': Icons.local_cafe_outlined,
  'licor': Icons.local_bar_outlined,
  'regalo': Icons.card_giftcard_outlined,
  'bebe': Icons.child_friendly_outlined,
  'familia': Icons.family_restroom_outlined,
  'gimnasio': Icons.fitness_center_outlined,
  'deporte': Icons.sports_soccer_outlined,
  'juegos': Icons.sports_esports_outlined,
  'musica': Icons.music_note_outlined,
  'libros': Icons.menu_book_outlined,
  'celular': Icons.smartphone_outlined,
  'internet': Icons.wifi,
  'agua': Icons.water_drop_outlined,
  'gas': Icons.local_fire_department_outlined,
  'gasolina': Icons.local_gas_station_outlined,
  'parqueadero': Icons.local_parking,
  'taxi': Icons.local_taxi_outlined,
  'bicicleta': Icons.pedal_bike,
  'farmacia': Icons.local_pharmacy_outlined,
  'belleza': Icons.content_cut,
  'lavanderia': Icons.local_laundry_service_outlined,
  'herramientas': Icons.build_outlined,
  'muebles': Icons.chair_outlined,
  'plantas': Icons.local_florist_outlined,
  'trabajo': Icons.work_outline,
  'impuestos': Icons.account_balance_outlined,
  'banco': Icons.credit_card_outlined,
  'ahorro': Icons.savings_outlined,
  'donacion': Icons.volunteer_activism_outlined,
  'fiesta': Icons.celebration_outlined,
  'hotel': Icons.hotel_outlined,
  'tienda': Icons.storefront_outlined,
  'compras': Icons.shopping_bag_outlined,
};

/// Colores que se pueden elegir para una categoría: los de las categorías
/// de fábrica y unos cuantos más del mismo tono apagado. Ninguno es el vino
/// de la marca ni el rojo de alerta.
const coloresCategoria = <Color>[
  Color(0xFFE8935B),
  Color(0xFFC77DA3),
  Color(0xFF5B8DBE),
  Color(0xFF8B7FD1),
  Color(0xFF6FA88A),
  Color(0xFFC9A227),
  Color(0xFFA6754D),
  Color(0xFF3FA7A0),
  Color(0xFF5568C8),
  Color(0xFFB8644A),
  Color(0xFFD9C23A),
  Color(0xFF8A9A3B),
  Color(0xFFB565B8),
  Color(0xFF4FB3D4),
  Color(0xFF6C7FA8),
  Color(0xFFD98A7A),
  Color(0xFF8B93A3),
  Color(0xFF7A9E5B),
  Color(0xFFCF7F4A),
  Color(0xFF9C6FB0),
];

/// Ícono de una clave guardada; si no existe (respaldo de una versión
/// futura, por ejemplo), el de "Otros".
IconData iconoDeClave(String clave) =>
    iconosCategoria[clave] ?? Icons.category_outlined;

/// Clave del catálogo para cada categoría de fábrica.
String claveDeFabrica(CategoriaGasto c) => c.name;
