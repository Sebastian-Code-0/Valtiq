import 'package:flutter/material.dart';

/// Paleta base: los valores crudos de color. Las pantallas NO deberían usar
/// esto directamente — usan `context.colores` (ver [ValtiqColores]), que
/// elige el valor correcto según el tema claro u oscuro. Cambiar la paleta
/// de la app = cambiar valores aquí y en [ValtiqColores.claro]/[oscuro].
abstract class AppColors {
  // Vino (acento). En oscuro hay dos tonos: uno profundo para rellenar
  // botones y otro más claro para texto/íconos, porque un vino profundo
  // sobre negro no se lee.
  static const vinoRellenoOscuro = Color(0xFF6A1628);
  static const vinoTextoOscuro = Color(0xFFC25A70);
  static const vinoClaro = Color(0xFF5A1222);
  // Texto sobre vino: el mismo beige del fondo claro (nada de blancos).
  static const sobreVino = Color(0xFFEFE7DA);

  // Morado (apoyo)
  static const moradoOscuro = Color(0xFF7E5FA6);
  static const moradoClaro = Color(0xFF523270);

  // Verde (dinero que entra)
  static const verdeOscuro = Color(0xFF6FBF94);
  static const verdeClaro = Color(0xFF2F6B4F);

  // Rojo (alerta)
  static const alertaOscuro = Color(0xFFFF5C5C);
  static const alertaClaro = Color(0xFFC21F1F);

  // Tema oscuro: negro puro
  static const fondoOscuro = Color(0xFF000000);
  // Tarjetas casi negras con un punto de vino (antes #141112, un gris que
  // no pegaba con la paleta); el borde vino oscuro es lo que las separa
  // del fondo.
  static const superficieOscuro = Color(0xFF0D090A);
  static const divisorOscuro = Color(0xFF3A2027);
  // Texto: el beige del fondo claro, no blanco.
  static const textoOscuro = Color(0xFFEFE7DA);
  static const textoSecundarioOscuro = Color(0xFFA99B90);

  // Tema claro: beige lino (sin blancos)
  static const fondoClaro = Color(0xFFEFE7DA);
  // Tarjetas color arena, un paso MÁS oscuras que el fondo (antes #F7F1E6,
  // casi blanco).
  static const superficieClaro = Color(0xFFE6DBC8);
  static const divisorClaro = Color(0xFFCDBEA6);
  // Texto: el mismo negro puro del fondo oscuro.
  static const textoClaro = Color(0xFF000000);
  static const textoSecundarioClaro = Color(0xFF63554E);
}

/// Colores con significado ("tokens semánticos"), uno por tema.
///
/// Uso en pantallas: `context.colores.alerta`, `context.colores.positivo`…
/// Así, cada color puede tener un tono distinto en claro y en oscuro (por
/// ejemplo, un rojo más luminoso sobre fondo negro para que se lea bien)
/// sin tocar ninguna pantalla.
@immutable
class ValtiqColores extends ThemeExtension<ValtiqColores> {
  const ValtiqColores({
    required this.fondo,
    required this.superficie,
    required this.texto,
    required this.textoSecundario,
    required this.divisor,
    required this.acento,
    required this.acentoRelleno,
    required this.sobreAcento,
    required this.secundario,
    required this.positivo,
    required this.alerta,
  });

  /// Fondo de las pantallas.
  final Color fondo;

  /// Tarjetas, campos de texto, barra de navegación.
  final Color superficie;

  final Color texto;
  final Color textoSecundario;
  final Color divisor;

  /// Color de marca para TEXTO e ÍCONOS: lo seleccionado, enlaces, chips.
  final Color acento;

  /// Color de marca para RELLENAR: botones, botones flotantes, avisos.
  final Color acentoRelleno;

  /// Texto/íconos que van ENCIMA de [acentoRelleno].
  final Color sobreAcento;

  /// Color de apoyo de la marca (cuando el acento no alcanza).
  final Color secundario;

  /// Dinero que entra, metas cumplidas, éxito.
  final Color positivo;

  /// Dinero que sale, vencimientos, errores.
  final Color alerta;

  static const claro = ValtiqColores(
    fondo: AppColors.fondoClaro,
    superficie: AppColors.superficieClaro,
    texto: AppColors.textoClaro,
    textoSecundario: AppColors.textoSecundarioClaro,
    divisor: AppColors.divisorClaro,
    acento: AppColors.vinoClaro,
    acentoRelleno: AppColors.vinoClaro,
    sobreAcento: AppColors.sobreVino,
    secundario: AppColors.moradoClaro,
    positivo: AppColors.verdeClaro,
    alerta: AppColors.alertaClaro,
  );

  static const oscuro = ValtiqColores(
    fondo: AppColors.fondoOscuro,
    superficie: AppColors.superficieOscuro,
    texto: AppColors.textoOscuro,
    textoSecundario: AppColors.textoSecundarioOscuro,
    divisor: AppColors.divisorOscuro,
    acento: AppColors.vinoTextoOscuro,
    acentoRelleno: AppColors.vinoRellenoOscuro,
    sobreAcento: AppColors.sobreVino,
    secundario: AppColors.moradoOscuro,
    positivo: AppColors.verdeOscuro,
    alerta: AppColors.alertaOscuro,
  );

  @override
  ValtiqColores copyWith({
    Color? fondo,
    Color? superficie,
    Color? texto,
    Color? textoSecundario,
    Color? divisor,
    Color? acento,
    Color? acentoRelleno,
    Color? sobreAcento,
    Color? secundario,
    Color? positivo,
    Color? alerta,
  }) {
    return ValtiqColores(
      fondo: fondo ?? this.fondo,
      superficie: superficie ?? this.superficie,
      texto: texto ?? this.texto,
      textoSecundario: textoSecundario ?? this.textoSecundario,
      divisor: divisor ?? this.divisor,
      acento: acento ?? this.acento,
      acentoRelleno: acentoRelleno ?? this.acentoRelleno,
      sobreAcento: sobreAcento ?? this.sobreAcento,
      secundario: secundario ?? this.secundario,
      positivo: positivo ?? this.positivo,
      alerta: alerta ?? this.alerta,
    );
  }

  @override
  ValtiqColores lerp(ValtiqColores? other, double t) {
    if (other == null) return this;
    return ValtiqColores(
      fondo: Color.lerp(fondo, other.fondo, t)!,
      superficie: Color.lerp(superficie, other.superficie, t)!,
      texto: Color.lerp(texto, other.texto, t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
      divisor: Color.lerp(divisor, other.divisor, t)!,
      acento: Color.lerp(acento, other.acento, t)!,
      acentoRelleno: Color.lerp(acentoRelleno, other.acentoRelleno, t)!,
      sobreAcento: Color.lerp(sobreAcento, other.sobreAcento, t)!,
      secundario: Color.lerp(secundario, other.secundario, t)!,
      positivo: Color.lerp(positivo, other.positivo, t)!,
      alerta: Color.lerp(alerta, other.alerta, t)!,
    );
  }
}

extension ValtiqColoresContext on BuildContext {
  /// Colores del tema activo. Si por algún motivo el tema no los trae
  /// (por ejemplo, un widget de test montado sin `AppTheme`), cae a los
  /// del tema claro/oscuro según el brillo, en vez de romper.
  ValtiqColores get colores {
    final theme = Theme.of(this);
    return theme.extension<ValtiqColores>() ??
        (theme.brightness == Brightness.dark
            ? ValtiqColores.oscuro
            : ValtiqColores.claro);
  }
}
