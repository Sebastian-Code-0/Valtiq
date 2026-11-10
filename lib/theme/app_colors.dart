import 'package:flutter/material.dart';

/// Paleta base: los valores crudos de color. Las pantallas NO deberían usar
/// esto directamente — usan `context.colores` (ver [ValtiqColores]), que
/// elige el valor correcto según el tema claro u oscuro. Cambiar la paleta
/// de la app = cambiar valores aquí y en [ValtiqColores.claro]/[oscuro].
abstract class AppColors {
  static const primario = Color(0xFF1E3A5F);
  static const acento = Color(0xFF1E8A63);
  static const alerta = Color(0xFFE05C5C);

  // Hoy comparte el mismo valor que acento. Debe seguir siendo un verde de
  // éxito aunque el acento cambie de color.
  static const positivo = Color(0xFF1E8A63);

  static const fondoClaro = Color(0xFFF5F0E6);
  static const superficieClaro = Color(0xFFFAF6ED);
  static const textoClaro = Color(0xFF211E19);
  static const textoSecundarioClaro = Color(0xFF756F63);
  static const divisorClaro = Color(0xFFE4DECF);

  static const fondoOscuro = Color(0xFF121212);
  static const superficieOscuro = Color(0xFF1C1C1C);
  static const textoOscuro = Color(0xFFF1EFE9);
  static const textoSecundarioOscuro = Color(0xFF9A9D97);
  static const divisorOscuro = Color(0xFF2A2A2A);
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

  /// Color de marca: botones principales, elementos seleccionados.
  final Color acento;

  /// Texto/íconos que van ENCIMA del acento.
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
    acento: AppColors.acento,
    sobreAcento: Colors.white,
    secundario: AppColors.primario,
    positivo: AppColors.positivo,
    alerta: AppColors.alerta,
  );

  static const oscuro = ValtiqColores(
    fondo: AppColors.fondoOscuro,
    superficie: AppColors.superficieOscuro,
    texto: AppColors.textoOscuro,
    textoSecundario: AppColors.textoSecundarioOscuro,
    divisor: AppColors.divisorOscuro,
    acento: AppColors.acento,
    sobreAcento: Colors.white,
    secundario: AppColors.primario,
    positivo: AppColors.positivo,
    alerta: AppColors.alerta,
  );

  @override
  ValtiqColores copyWith({
    Color? fondo,
    Color? superficie,
    Color? texto,
    Color? textoSecundario,
    Color? divisor,
    Color? acento,
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
