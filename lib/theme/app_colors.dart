import 'package:flutter/material.dart';

abstract class AppColors {
  static const primario = Color(0xFF1E3A5F);
  static const acento = Color(0xFF1E8A63);
  static const alerta = Color(0xFFE05C5C);

  // Hoy comparte el mismo valor que acento porque el verde Esmeralda oscuro
  // por defecto ya es un verde de éxito. Si acento cambia a otro preset, este
  // valor debe seguir fijo como verde de éxito y no seguir al preset dinámico.
  static const positivo = Color(0xFF1E8A63);

  static const fondoClaro = Color(0xFFF5F0E6);
  static const superficieClaro = Color(0xFFFFFFFF);
  static const textoClaro = Color(0xFF211E19);
  static const textoSecundarioClaro = Color(0xFF756F63);

  static const fondoOscuro = Color(0xFF0D110F);
  static const superficieOscuro = Color(0xFF161C19);
  static const textoOscuro = Color(0xFFF1EFE9);
  static const textoSecundarioOscuro = Color(0xFF9A9D97);
}
