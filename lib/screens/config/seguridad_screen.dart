import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';
import '../../theme/theme.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_pildoras.dart';
import '../lock/configurar_pin_screen.dart';
import 'ajustes_widgets.dart';
import 'settings_screen.dart';

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
      mostrarExito(context, 'Bloqueo activado');
    }
  }

  Future<void> _desactivar() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const VerificarPinScreen(titulo: 'Desactivar bloqueo'),
      ),
    );
    if (ok != true) return;
    await AppLockService.desactivar();
    await _cargar();
    if (!mounted) return;
    mostrarInfo(context, 'Bloqueo desactivado');
  }

  Future<void> _cambiarPin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfigurarPinScreen(esCambio: true),
      ),
    );
    if (ok == true && mounted) {
      mostrarExito(context, 'PIN actualizado');
    }
  }

  /// Texto corto para las píldoras.
  String _nombreTimeout(Duration d) {
    if (d == Duration.zero) return 'Inmediato';
    if (d.inMinutes < 1) return '${d.inSeconds} s';
    return '${d.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: barraAjustes(context, 'Seguridad'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return PaginaAjustes(
      titulo: 'Seguridad',
      children: [
        TarjetaFilas(
          children: [
            FilaAjuste.interruptor(
              icono: Icons.lock_outline,
              titulo: 'Bloqueo con PIN/biometría',
              subtitulo: 'Pide desbloquear la app cada vez que la abres',
              valor: _bloqueoActivo,
              onChanged: (v) => v ? _activar() : _desactivar(),
            ),
            if (_bloqueoActivo) ...[
              if (_biometriaDisponible)
                FilaAjuste.interruptor(
                  icono: Icons.fingerprint,
                  titulo: 'Usar biometría',
                  subtitulo:
                      'Huella, rostro o PIN del sistema, cuando esté '
                      'disponible',
                  valor: _usaBiometria,
                  onChanged: (v) async {
                    await AppLockService.setUsaBiometria(v);
                    setState(() => _usaBiometria = v);
                  },
                ),
              FilaAjuste(
                icono: Icons.timer_outlined,
                titulo: 'Bloquear después de',
                subtitulo: 'Cuánto esperar al salir de Valtiq y volver',
                abajo: GrupoPildoras<Duration>(
                  opciones: {
                    for (final d in {..._opcionesTimeout, _timeout})
                      d: _nombreTimeout(d),
                  },
                  valor: _timeout,
                  onElegir: (d) async {
                    await AppLockService.setTimeoutReloqueo(d);
                    setState(() => _timeout = d);
                  },
                ),
              ),
              FilaAjuste(
                icono: Icons.password_outlined,
                titulo: 'Cambiar PIN',
                trailing: Icon(
                  Icons.chevron_right,
                  color: context.colores.textoSecundario,
                ),
                onTap: _cambiarPin,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
