import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../services/app_lock_service.dart';
import '../../services/backup_service.dart';
import '../../services/borrado_service.dart';
import '../../theme/theme.dart';
import '../../utils/encabezado_pantalla.dart';
import '../../utils/notificaciones.dart';
import 'ajustes_widgets.dart';

class RespaldoScreen extends StatefulWidget {
  const RespaldoScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<RespaldoScreen> createState() => _RespaldoScreenState();
}

class _RespaldoScreenState extends State<RespaldoScreen> {
  bool _exportando = false;
  bool _importando = false;
  bool _borrando = false;

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
            child: Text(
              'Importar',
              style: TextStyle(color: context.colores.alerta),
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

  Future<void> _borrarTodo() async {
    final pideClave = await AppLockService.bloqueoActivo();
    if (!mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _BorrarTodoDialog(pideClave: pideClave, onGuardarCopia: _exportar),
    );
    if (confirmado != true || !mounted) return;
    setState(() => _borrando = true);
    try {
      await BorradoService.borrarTodo(widget.db);
      if (!mounted) return;
      mostrarExito(context, 'Listo: Valtiq quedó como recién instalada.');
    } catch (_) {
      if (!mounted) return;
      mostrarAlerta(context, 'No se pudo borrar todo. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _borrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;

    Widget cola(bool ocupado) => ocupado
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(Icons.chevron_right, color: c.textoSecundario);

    return PaginaAjustes(
      titulo: 'Copia de seguridad',
      children: [
        TarjetaFilas(
          titulo: 'Tus datos',
          children: [
            FilaAjuste(
              icono: Icons.upload_outlined,
              titulo: 'Exportar datos',
              subtitulo: 'Guarda un archivo JSON con tus datos',
              trailing: cola(_exportando),
              onTap: _exportando ? null : _exportar,
            ),
            FilaAjuste(
              icono: Icons.download_outlined,
              titulo: 'Importar datos',
              subtitulo: 'Reemplaza tus datos desde un archivo',
              trailing: cola(_importando),
              onTap: _importando ? null : _importar,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const AvisoDiscreto(
          texto:
              'Por seguridad, la configuración de recordatorios por '
              'correo no se incluye en este respaldo. Si restauras '
              'estos datos en otro dispositivo, deberás configurarla '
              'de nuevo en Ajustes → Correo.',
        ),
        const SizedBox(height: AppSpacing.xl),
        // Separado del resto: es lo único de esta pantalla que destruye.
        // Aquí va discreto; el rojo fuerte queda para la confirmación.
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: AppSpacing.sm),
          child: TextoKicker('Zona de cuidado'),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Borrar todo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Deja Valtiq como recién instalada en este dispositivo: '
                  'borra todos tus datos, tu perfil y tus ajustes. No se '
                  'puede deshacer.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: c.textoSecundario,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _borrando ? null : _borrarTodo,
                  style: OutlinedButton.styleFrom(foregroundColor: c.alerta),
                  icon: const Icon(Icons.delete_forever_outlined, size: 18),
                  label: Text(_borrando ? 'Borrando...' : 'Borrar todo'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Confirmación de "Borrar todo". Para que no pase por accidente pide:
/// escribir la palabra BORRAR y, si la app tiene bloqueo, el PIN. Ofrece
/// guardar una copia antes.
class _BorrarTodoDialog extends StatefulWidget {
  const _BorrarTodoDialog({
    required this.pideClave,
    required this.onGuardarCopia,
  });

  final bool pideClave;
  final Future<void> Function() onGuardarCopia;

  @override
  State<_BorrarTodoDialog> createState() => _BorrarTodoDialogState();
}

class _BorrarTodoDialogState extends State<_BorrarTodoDialog> {
  static const _palabra = 'BORRAR';

  final _palabraCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String? _errorPin;
  bool _verificando = false;

  @override
  void dispose() {
    _palabraCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  bool get _palabraOk => _palabraCtrl.text.trim().toUpperCase() == _palabra;

  Future<void> _confirmar() async {
    if (!_palabraOk) return;
    if (widget.pideClave) {
      setState(() => _verificando = true);
      final ok = await AppLockService.verificarPin(_pinCtrl.text);
      if (!mounted) return;
      setState(() => _verificando = false);
      if (!ok) {
        setState(() => _errorPin = 'PIN incorrecto');
        return;
      }
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final secundario = theme.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      height: 1.45,
      color: c.textoSecundario,
    );
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Borrar todo?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Se borran tus deudas, préstamos, pagos, ingresos, gastos, '
                'recordatorios y presupuestos; tu perfil y tu foto; el PIN; '
                'el correo configurado y todos los ajustes. Valtiq queda '
                'como recién instalada. No se puede deshacer.',
                style: secundario,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: widget.onGuardarCopia,
                  icon: const Icon(Icons.upload_outlined, size: 18),
                  label: const Text('Guardar una copia antes'),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Para confirmar, escribe $_palabra',
                style: secundario?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const ValueKey('borrar-palabra'),
                controller: _palabraCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: _palabra),
                onChanged: (_) => setState(() {}),
              ),
              if (widget.pideClave) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tu PIN',
                  style: secundario?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: const ValueKey('borrar-pin'),
                  controller: _pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(errorText: _errorPin),
                  onChanged: (_) => setState(() => _errorPin = null),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: AppSpacing.sm,
                overflowSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: _palabraOk && !_verificando ? _confirmar : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.alerta,
                      foregroundColor: c.fondo,
                    ),
                    child: const Text('Borrar todo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
