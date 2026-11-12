abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  /// Formas del rediseño 2026-11: tarjetas muy redondeadas, campos de
  /// texto y recuadros algo menos, ventanas un poco más. Los botones y las
  /// etiquetas son píldoras (StadiumBorder), no usan radio.
  static const double radiusTarjeta = 24;
  static const double radiusCampo = 14;
  static const double radiusRecuadro = 16;
  static const double radiusDialogo = 28;

  /// Grosor del borde de tarjetas, campos y ventanas.
  static const double borde = 1;

  /// Ancho máximo del contenido de una pantalla en PC.
  static const double anchoContenido = 1140;

  static const double labelColumnWidth = 130;
}
