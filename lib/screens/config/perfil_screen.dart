import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../services/perfil_service.dart';
import '../../theme/theme.dart';
import '../../utils/date_format.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/form_widgets.dart';
import '../../utils/notificaciones.dart';
import '../barra_lateral.dart';
import 'ajustes_widgets.dart';

/// Ajustes → Perfil: foto redonda (se elige de la galería / archivos) y
/// nombre + apellido. El NOMBRE es el que saluda en Inicio ("Buenos días, Sofía").
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final _nombreCtrl = TextEditingController(
    text: PerfilService.perfil.value.nombre,
  );
  late final _apellidoCtrl = TextEditingController(
    text: PerfilService.perfil.value.apellido,
  );
  bool _guardando = false;
  bool _cambiandoFoto = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    setState(() => _cambiandoFoto = true);
    try {
      final archivo = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Imágenes',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            uniformTypeIdentifiers: ['public.image'],
          ),
        ],
      );
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      final nombre = archivo.name;
      final punto = nombre.lastIndexOf('.');
      await PerfilService.guardarFoto(
        bytes,
        punto < 0 ? '' : nombre.substring(punto + 1),
      );
      if (mounted) mostrarExito(context, 'Foto de perfil actualizada.');
    } catch (e) {
      debugPrint('PerfilScreen: no se pudo cambiar la foto: $e');
      if (mounted) {
        mostrarAlerta(context, 'No se pudo usar esa imagen. Prueba con otra.');
      }
    } finally {
      if (mounted) setState(() => _cambiandoFoto = false);
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    await PerfilService.guardarNombre(
      nombre: _nombreCtrl.text,
      apellido: _apellidoCtrl.text,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    FocusScope.of(context).unfocus();
    mostrarExito(context, 'Perfil guardado.');
  }

  /// Cómo saludará Inicio con lo que hay escrito ahora mismo.
  String get _saludo {
    final nombre = _nombreCtrl.text.trim();
    final saludo = saludoSegunHora(DateTime.now());
    return nombre.isEmpty ? saludo : '$saludo, $nombre';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;

    Widget botonesFoto(Perfil perfil) => Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _cambiandoFoto ? null : _elegirFoto,
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: Text(perfil.rutaFoto == null ? 'Elegir foto' : 'Cambiar foto'),
        ),
        if (perfil.rutaFoto != null)
          TextButton(
            onPressed: _cambiandoFoto ? null : PerfilService.quitarFoto,
            child: const Text('Quitar foto'),
          ),
      ],
    );

    // Vista previa del saludo: para qué sirve el nombre, sin ir a Inicio.
    Widget saludo({required bool centrado}) => Column(
      crossAxisAlignment: centrado
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        const TextoKicker('Así te saluda Valtiq'),
        const SizedBox(height: 6),
        Text(
          _saludo,
          key: const ValueKey('perfil-saludo'),
          textAlign: centrado ? TextAlign.center : TextAlign.start,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );

    return PaginaAjustes(
      titulo: 'Perfil',
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder<Perfil>(
                  valueListenable: PerfilService.perfil,
                  builder: (context, perfil, _) => LayoutBuilder(
                    // Foto a la izquierda con el saludo y los botones al
                    // lado; en pantallas angostas, todo centrado en columna.
                    builder: (context, constraints) =>
                        constraints.maxWidth >= 480
                        ? Row(
                            children: [
                              FotoPerfil(perfil: perfil, radio: 64),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    saludo(centrado: false),
                                    const SizedBox(height: AppSpacing.md),
                                    botonesFoto(perfil),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              FotoPerfil(perfil: perfil, radio: 56),
                              const SizedBox(height: AppSpacing.md),
                              saludo(centrado: true),
                              const SizedBox(height: AppSpacing.md),
                              botonesFoto(perfil),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilaCampos(
                  children: [
                    CampoEtiquetado(
                      etiqueta: 'Nombre',
                      ayuda: 'Así te saludará Valtiq.',
                      child: TextField(
                        key: const ValueKey('perfil-nombre'),
                        controller: _nombreCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Tu nombre',
                        ),
                      ),
                    ),
                    CampoEtiquetado(
                      etiqueta: 'Apellido (opcional)',
                      child: TextField(
                        key: const ValueKey('perfil-apellido'),
                        controller: _apellidoCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _guardar(),
                        decoration: const InputDecoration(
                          hintText: 'Tu apellido',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FormSaveButton(onPressed: _guardar, loading: _guardando),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tu nombre y tu foto se guardan en este dispositivo y '
                  'van incluidos en la copia de seguridad.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
