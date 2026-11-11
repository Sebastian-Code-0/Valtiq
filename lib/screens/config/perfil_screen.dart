import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../services/perfil_service.dart';
import '../../theme/theme.dart';
import '../../utils/form_widgets.dart';
import '../../utils/notificaciones.dart';
import '../barra_lateral.dart';
import 'settings_screen.dart';

/// Ajustes → Perfil: foto redonda (se elige de la galería / archivos) y
/// nombre + apellido. El NOMBRE es el que saluda en Inicio ("Hola, Sofía").
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final nombre = TextField(
      controller: _nombreCtrl,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Nombre',
        helperText: 'Así te saludará Valtiq',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
    );
    final apellido = TextField(
      controller: _apellidoCtrl,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _guardar(),
      decoration: const InputDecoration(
        labelText: 'Apellido',
        helperText: 'Opcional',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
    );

    return Scaffold(
      appBar: barraAjustes(context, 'Perfil'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      ValueListenableBuilder<Perfil>(
                        valueListenable: PerfilService.perfil,
                        builder: (context, perfil, _) => Column(
                          children: [
                            FotoPerfil(perfil: perfil, radio: 56),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _cambiandoFoto
                                      ? null
                                      : _elegirFoto,
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    perfil.rutaFoto == null
                                        ? 'Elegir foto'
                                        : 'Cambiar foto',
                                  ),
                                ),
                                if (perfil.rutaFoto != null)
                                  TextButton(
                                    onPressed: _cambiandoFoto
                                        ? null
                                        : PerfilService.quitarFoto,
                                    child: Text(
                                      'Quitar foto',
                                      style: TextStyle(color: c.alerta),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Nombre y apellido lado a lado si hay espacio; uno
                      // debajo del otro en pantallas angostas.
                      LayoutBuilder(
                        builder: (context, constraints) =>
                            constraints.maxWidth >= 480
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: nombre),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(child: apellido),
                                ],
                              )
                            : Column(
                                children: [
                                  nombre,
                                  const SizedBox(height: AppSpacing.md),
                                  apellido,
                                ],
                              ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FormSaveButton(onPressed: _guardar, loading: _guardando),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Tu nombre y tu foto se guardan solo en este '
                        'dispositivo y no se incluyen en la copia de '
                        'seguridad.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: c.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
