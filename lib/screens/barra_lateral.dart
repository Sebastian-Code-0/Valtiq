import 'dart:io';

import 'package:flutter/material.dart';

import '../services/perfil_service.dart';
import '../theme/theme.dart';

/// Ancho mínimo de la ventana para mostrar el menú lateral. Por debajo
/// (celular, ventana angosta) se usa la barra de navegación inferior.
const double anchoMinimoBarraLateral = 900;

/// Ancho fijo del menú lateral.
const double anchoBarraLateral = 264;

/// Una entrada del menú lateral.
class ItemBarraLateral {
  const ItemBarraLateral(this.etiqueta, {this.contador = 0});

  final String etiqueta;

  /// Número en la insignia de la derecha (no se muestra si es 0).
  final int contador;
}

/// Menú lateral de la versión de PC: logo y nombre arriba, las secciones
/// una debajo de otra y, al fondo, Ajustes y el perfil.
///
/// A propósito NO son tarjetas: solo texto beige, y la sección actual se
/// marca con un bloque de color de superficie detrás.
class BarraLateral extends StatelessWidget {
  const BarraLateral({
    super.key,
    required this.items,
    required this.indice,
    required this.indiceAjustes,
    required this.onElegir,
    required this.onPerfil,
  });

  final List<ItemBarraLateral> items;

  /// Índice seleccionado (puede ser [indiceAjustes]).
  final int indice;

  /// Índice que representa a "Ajustes" (va separado, al fondo).
  final int indiceAjustes;
  final ValueChanged<int> onElegir;
  final VoidCallback onPerfil;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final theme = Theme.of(context);
    return Container(
      width: anchoBarraLateral,
      decoration: BoxDecoration(
        color: c.fondo,
        // La línea que separa el menú del contenido.
        border: Border(right: BorderSide(color: c.divisor)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo_icono.png',
                      height: 36,
                      color: c.acento,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Valtiq',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: c.texto,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Si la ventana es bajita, las secciones se desplazan; Ajustes
              // y el perfil se quedan siempre visibles abajo.
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _Entrada(
                        etiqueta: items[i].etiqueta,
                        contador: items[i].contador,
                        seleccionada: indice == i,
                        onTap: () => onElegir(i),
                      ),
                  ],
                ),
              ),
              _Entrada(
                etiqueta: 'Ajustes',
                seleccionada: indice == indiceAjustes,
                onTap: () => onElegir(indiceAjustes),
              ),
              const SizedBox(height: AppSpacing.sm),
              Divider(color: c.divisor, height: 1),
              const SizedBox(height: AppSpacing.sm),
              _PerfilResumen(onTap: onPerfil),
            ],
          ),
        ),
      ),
    );
  }
}

class _Entrada extends StatelessWidget {
  const _Entrada({
    required this.etiqueta,
    required this.seleccionada,
    required this.onTap,
    this.contador = 0,
  });

  final String etiqueta;
  final bool seleccionada;
  final VoidCallback onTap;
  final int contador;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        button: true,
        selected: seleccionada,
        child: Material(
          color: seleccionada ? c.superficie : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      etiqueta,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: seleccionada ? c.texto : c.textoSecundario,
                        fontWeight: seleccionada
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (contador > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.acentoRelleno,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        contador > 99 ? '99+' : '$contador',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: c.sobreAcento,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Foto redonda + nombre, al fondo del menú. Toca para ir a Ajustes → Perfil.
class _PerfilResumen extends StatelessWidget {
  const _PerfilResumen({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final theme = Theme.of(context);
    return ValueListenableBuilder<Perfil>(
      valueListenable: PerfilService.perfil,
      builder: (context, perfil, _) {
        final sinNombre = perfil.nombre.isEmpty;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                FotoPerfil(perfil: perfil, radio: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sinNombre ? 'Tu perfil' : perfil.nombreCompleto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: c.texto,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        sinNombre ? 'Agrega tu nombre' : 'Ver perfil',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: c.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Foto de perfil redonda. Sin foto: un círculo con la inicial del nombre
/// (o un ícono de persona si tampoco hay nombre).
class FotoPerfil extends StatelessWidget {
  const FotoPerfil({super.key, required this.perfil, required this.radio});

  final Perfil perfil;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final ruta = perfil.rutaFoto;
    return CircleAvatar(
      radius: radio,
      backgroundColor: c.acentoRelleno,
      foregroundImage: ruta == null ? null : FileImage(File(ruta)),
      child: perfil.inicial.isEmpty
          ? Icon(Icons.person, color: c.sobreAcento, size: radio)
          : Text(
              perfil.inicial,
              style: TextStyle(
                color: c.sobreAcento,
                fontSize: radio * 0.9,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
