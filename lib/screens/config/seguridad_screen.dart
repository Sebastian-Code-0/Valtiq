import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';
import '../../theme/theme.dart';
import '../lock/configurar_pin_screen.dart';

class SeguridadScreen extends StatefulWidget {
  const SeguridadScreen({super.key});

  @override
  State<SeguridadScreen> createState() => _SeguridadScreenState();
}

class _SeguridadScreenState extends State<SeguridadScreen> {
  bool _cargando = true;
  bool _bloqueoActivo = false;
  bool _usaBiometria = true;
  bool _biometriaDisponible = false;
  Duration _timeout = AppLockService.timeoutPorDefecto;

  static const _opcionesTimeout = [
    Duration.zero,
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final activo = await AppLockService.bloqueoActivo();
    final bio = await AppLockService.usaBiometria();
    final bioDisponible = await AppLockService.biometriaDisponible();
    final timeout = await AppLockService.timeoutReloqueo();
    if (!mounted) return;
    setState(() {
      _bloqueoActivo = activo;
      _usaBiometria = bio;
      _biometriaDisponible = bioDisponible;
      _timeout = timeout;
      _cargando = false;
    });
  }

  Future<void> _activar() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfigurarPinScreen(esCambio: false),
      ),
    );
    if (ok == true) {
      await _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueo activado')),
      );
    }
  }

  Future<void> _desactivar() async {
    final pin = await _pedirPinActual(
      titulo: 'Ingresá tu PIN para desactivar el bloqueo',
    );
    if (pin == null) return;
    final ok = await AppLockService.verificarPin(pin);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN incorrecto')));
      return;
    }
    await AppLockService.desactivar();
    await _cargar();
  }

  Future<void> _cambiarPin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfigurarPinScreen(esCambio: true),
      ),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN actualizado')));
    }
  }

  Future<String?> _pedirPinActual({required String titulo}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  String _nombreTimeout(Duration d) {
    if (d == Duration.zero) return 'Inmediato';
    if (d.inMinutes < 1) return '${d.inSeconds} segundos';
    return d.inMinutes == 1 ? '1 minuto' : '${d.inMinutes} minutos';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Card(
                  child: SwitchListTile(
                    title: const Text('Bloqueo con PIN/biometría'),
                    subtitle: const Text(
                      'Pide desbloquear la app cada vez que la abrís',
                    ),
                    value: _bloqueoActivo,
                    onChanged: (v) => v ? _activar() : _desactivar(),
                  ),
                ),
                if (_bloqueoActivo) ...[
                  const SizedBox(height: AppSpacing.md),
                  if (_biometriaDisponible)
                    Card(
                      child: SwitchListTile(
                        title: const Text('Usar biometría'),
                        subtitle: const Text(
                          'Huella, rostro o PIN del sistema, cuando esté '
                          'disponible',
                        ),
                        value: _usaBiometria,
                        onChanged: (v) async {
                          await AppLockService.setUsaBiometria(v);
                          setState(() => _usaBiometria = v);
                        },
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: ListTile(
                      title: const Text('Bloquear después de'),
                      subtitle: Text(
                        'Al volver de segundo plano — ${_nombreTimeout(_timeout)}',
                      ),
                      trailing: DropdownButton<Duration>(
                        value: _timeout,
                        underline: const SizedBox.shrink(),
                        items: _opcionesTimeout
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(_nombreTimeout(d)),
                              ),
                            )
                            .toList(),
                        onChanged: (d) async {
                          if (d == null) return;
                          await AppLockService.setTimeoutReloqueo(d);
                          setState(() => _timeout = d);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.password_outlined),
                      title: const Text('Cambiar PIN'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _cambiarPin,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
