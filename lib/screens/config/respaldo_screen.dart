import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/backup_service.dart';
import '../../theme/theme.dart';
import '../../utils/notificaciones.dart';

class RespaldoScreen extends StatefulWidget {
  const RespaldoScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<RespaldoScreen> createState() => _RespaldoScreenState();
}

class _RespaldoScreenState extends State<RespaldoScreen> {
  bool _exportando = false;
  bool _importando = false;

  String _nombreArchivoSugerido() {
    final hoy = DateTime.now();
    final y = hoy.year.toString().padLeft(4, '0');
    final m = hoy.month.toString().padLeft(2, '0');
    final d = hoy.day.toString().padLeft(2, '0');
    return 'valtiq_backup_$y-$m-$d.json';
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final datos = await BackupService(widget.db).exportarDatos();
      final jsonString = jsonEncode(datos);
      final nombreSugerido = _nombreArchivoSugerido();

      final resultado = await getSaveLocation(suggestedName: nombreSugerido);
      if (resultado == null) return;

      final archivo = XFile.fromData(
        utf8.encode(jsonString),
        mimeType: 'application/json',
        name: nombreSugerido,
      );
      await archivo.saveTo(resultado.path);

      if (!mounted) return;
      mostrarExito(context, 'Datos exportados');
    } catch (_) {
      if (!mounted) return;
      mostrarAlerta(context, 'No se pudo exportar los datos.');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<bool> _confirmarImportar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar datos'),
        content: const Text(
          'Esto reemplazará TODOS los datos actuales de la app (deudas, '
          'préstamos, ingresos, gastos y recordatorios) con los del '
          'archivo. Esta acción no se puede deshacer. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Importar',
              style: TextStyle(color: AppColors.alerta),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _importar() async {
    setState(() => _importando = true);
    try {
      final archivo = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
      if (archivo == null) return;

      final contenido = await archivo.readAsString();
      final json = jsonDecode(contenido);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('formato inválido');
      }

      if (!mounted) return;
      final confirmado = await _confirmarImportar();
      if (!confirmado) return;

      await BackupService(widget.db).importarDatos(json);

      if (!mounted) return;
      mostrarExito(context, 'Datos importados');
    } on FormatException catch (_) {
      if (!mounted) return;
      mostrarAlerta(context, 'El archivo no es un respaldo válido de Valtiq.');
    } catch (_) {
      if (!mounted) return;
      mostrarAlerta(context, 'No se pudo importar los datos.');
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorFondo = theme.colorScheme.surfaceContainerHighest;
    final colorBorde = theme.colorScheme.outline;

    return Scaffold(
      appBar: AppBar(title: const Text('Copia de seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorFondo,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: colorBorde),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Por seguridad, la configuración de correo SMTP no se '
                    'incluye en este respaldo. Si restauras estos datos en '
                    'otro dispositivo, deberás volver a configurar tu '
                    'servidor SMTP en Ajustes → Configuración SMTP.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: _exportando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined),
              title: const Text('Exportar datos'),
              subtitle: const Text('Guarda un archivo JSON con tus datos'),
              onTap: _exportando ? null : _exportar,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: _importando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              title: const Text('Importar datos'),
              subtitle: const Text('Reemplaza tus datos desde un archivo'),
              onTap: _importando ? null : _importar,
            ),
          ),
        ],
      ),
    );
  }
}
