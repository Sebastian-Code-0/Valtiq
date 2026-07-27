import 'package:flutter/material.dart';

abstract class AppColors {
  static const primario = Color(0xFF1E3A5F);
  static const acento = Color(0xFF2DD4A0);
  static const alerta = Color(0xFFE05C5C);

  // Hoy comparte el mismo valor que acento porque el verde de marca por
  // defecto ya es un verde de éxito. Si acento cambia a otro preset, este
  // valor debe seguir fijo como verde de éxito y no seguir al preset dinámico.
  static const positivo = Color(0xFF2DD4A0);

  static const fondoClaro = Color(0xFFF8F9FA);
  static const superficieClaro = Color(0xFFFFFFFF);
  static const textoClaro = Color(0xFF1A1A2E);
  static const textoSecundarioClaro = Color(0xFF6B7280);

  static const fondoOscuro = Color(0xFF121820);
  static const superficieOscuro = Color(0xFF1E2530);
  static const textoOscuro = Color(0xFFF1F5F9);
  static const textoSecundarioOscuro = Color(0xFF94A3B8);
}
