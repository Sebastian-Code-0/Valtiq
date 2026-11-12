import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/database.dart';
import '../../services/smtp_service.dart';
import '../../theme/theme.dart';
import '../../utils/error_messages.dart';
import '../../utils/form_widgets.dart';
import '../../utils/notificaciones.dart';
import '../../utils/selector_pildoras.dart';
import 'ajustes_widgets.dart';

class ConfigSmtpScreen extends StatefulWidget {
  const ConfigSmtpScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<ConfigSmtpScreen> createState() => _ConfigSmtpScreenState();
}

typedef _Preset = ({String nombre, String servidor, int puerto, bool ssl});

const _presets = <_Preset>[
  (nombre: 'Gmail', servidor: 'smtp.gmail.com', puerto: 587, ssl: false),
  (nombre: 'Outlook', servidor: 'smtp.office365.com', puerto: 587, ssl: false),
  (nombre: 'Yahoo', servidor: 'smtp.mail.yahoo.com', puerto: 587, ssl: false),
];

class _ConfigSmtpScreenState extends State<ConfigSmtpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _servidorCtrl = TextEditingController();
  final _puertoCtrl = TextEditingController(text: '587');
  final _usuarioCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _destinoCtrl = TextEditingController();
  final _remitenteCtrl = TextEditingController(text: 'Valtiq');

  bool _ssl = false;
  bool _habilitado = false;
  bool _mostrarPassword = false;
  bool _guardando = false;
  bool _probando = false;
  bool _cargando = true;
  bool _tieneContrasena = false;

  @override
  void initState() {
    super.initState();
    _servidorCtrl.addListener(_onServidorChanged);
    _cargarConfig();
  }

  void _onServidorChanged() => setState(() {});

  void _aplicarPreset(_Preset preset) {
    setState(() {
      _servidorCtrl.text = preset.servidor;
      _puertoCtrl.text = preset.puerto.toString();
      _ssl = preset.ssl;
    });
  }

  Future<void> _cargarConfig() async {
    try {
      final config = await widget.db.configSmtpDao.getConfig();
      if (!mounted) return;
      setState(() {
        _servidorCtrl.text = config.servidor;
        _puertoCtrl.text = config.puerto.toString();
        _usuarioCtrl.text = config.usuario;
        _destinoCtrl.text = config.correoDestino;
        _remitenteCtrl.text = config.nombreRemitente;
        _ssl = config.ssl;
        _habilitado = config.habilitado;
        _tieneContrasena = config.tieneContrasena;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _servidorCtrl.removeListener(_onServidorChanged);
    _servidorCtrl.dispose();
    _puertoCtrl.dispose();
    _usuarioCtrl.dispose();
    _passCtrl.dispose();
    _destinoCtrl.dispose();
    _remitenteCtrl.dispose();
    super.dispose();
  }

  bool _esEmailValido(String email) {
    final regex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email.trim());
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_destinoCtrl.text.trim().isNotEmpty &&
        !_esEmailValido(_destinoCtrl.text)) {
      mostrarAlerta(context, 'El correo destino no tiene un formato válido');
      return;
    }
    setState(() => _guardando = true);
    final passTexto = _passCtrl.text;
    final contrasena = (passTexto.isEmpty && _tieneContrasena)
        ? null
        : passTexto;
    try {
      await widget.db.configSmtpDao.guardarConfig(
        servidor: _servidorCtrl.text.trim(),
        puerto: int.tryParse(_puertoCtrl.text.trim()) ?? 587,
        usuario: _usuarioCtrl.text.trim(),
        contrasena: contrasena,
        correoDestino: _destinoCtrl.text.trim(),
        nombreRemitente: _remitenteCtrl.text.trim().isEmpty
            ? 'Valtiq'
            : _remitenteCtrl.text.trim(),
        ssl: _ssl,
        habilitado: _habilitado,
      );
      if (!mounted) return;
      setState(() {
        if (passTexto.isNotEmpty) _tieneContrasena = true;
      });
      mostrarExito(context, 'Configuración guardada');
    } catch (e) {
      if (!mounted) return;
      mostrarAlerta(context, mensajeAmigableGuardado(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _probar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _probando = true);

    try {
      final password = _passCtrl.text.isNotEmpty
          ? _passCtrl.text
          : (_tieneContrasena
                ? await widget.db.configSmtpDao.getPassword() ?? ''
                : '');

      final config = ConfigSmtp(
        id: 1,
        servidor: _servidorCtrl.text.trim(),
        puerto: int.tryParse(_puertoCtrl.text.trim()) ?? 587,
        usuario: _usuarioCtrl.text.trim(),
        tieneContrasena: password.isNotEmpty,
        correoDestino: _destinoCtrl.text.trim(),
        nombreRemitente: _remitenteCtrl.text.trim().isEmpty
            ? 'Valtiq'
            : _remitenteCtrl.text.trim(),
        ssl: _ssl,
        habilitado: true,
        actualizadoEn: DateTime.now(),
      );

      final result = await SmtpService.probarConfiguracion(
        config: config,
        password: password,
      );
      if (!mounted) return;
      if (result.exito) {
        mostrarExito(
          context,
          result.mensaje ?? 'OK',
          duracion: const Duration(seconds: 6),
        );
      } else {
        mostrarAlerta(
          context,
          result.mensaje ?? 'Falló',
          duracion: const Duration(seconds: 6),
        );
      }
    } catch (_) {
      if (!mounted) return;
      mostrarAlerta(
        context,
        'No se pudo probar la configuración. Intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  Future<void> _abrirAppPasswords() async {
    final uri = Uri.parse('https://myaccount.google.com/apppasswords');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        mostrarAlerta(context, 'No se pudo abrir el navegador');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final servidor = _servidorCtrl.text.trim();
    final esGmail = servidor == 'smtp.gmail.com';
    // El proveedor cuyo servidor está escrito ahora (o ninguno).
    _Preset? elegido;
    for (final p in _presets) {
      if (p.servidor == servidor) elegido = p;
    }
    const espacio = SizedBox(height: AppSpacing.md);

    return Form(
      key: _formKey,
      child: PaginaAjustes(
        titulo: 'Recordatorios por correo',
        children: [
          TarjetaFilas(
            children: [
              FilaAjuste.interruptor(
                icono: Icons.mark_email_read_outlined,
                titulo: 'Enviar recordatorios por correo',
                subtitulo:
                    'Los recordatorios de tipo "correo" o "ambos" te '
                    'llegarán también por email.',
                valor: _habilitado,
                onChanged: (v) => setState(() => _habilitado = v),
              ),
            ],
          ),
          espacio,
          FormSection(
            title: 'Servidor',
            icon: Icons.dns_outlined,
            children: [
              CampoEtiquetado(
                etiqueta: 'Tu proveedor de correo',
                ayuda: 'Al elegir uno se llenan solos el servidor y el puerto.',
                child: GrupoPildoras<_Preset?>(
                  opciones: {for (final p in _presets) p: p.nombre},
                  valor: elegido,
                  onElegir: (p) {
                    if (p != null) _aplicarPreset(p);
                  },
                ),
              ),
              if (esGmail) ...[
                espacio,
                AvisoDiscreto(
                  titulo: 'Gmail pide una contraseña de aplicación',
                  texto:
                      'No uses tu contraseña normal de Google: Gmail exige '
                      'una "Contraseña de aplicación" para enviar correos '
                      'desde otra app.',
                  accion: OutlinedButton.icon(
                    onPressed: _abrirAppPasswords,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Crear contraseña de aplicación'),
                  ),
                ),
              ],
              espacio,
              FilaCampos(
                children: [
                  CampoEtiquetado(
                    etiqueta: 'Servidor de correo (SMTP)',
                    child: TextFormField(
                      controller: _servidorCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'smtp.gmail.com',
                      ),
                      validator: _requeridoSiActivo,
                    ),
                  ),
                  CampoEtiquetado(
                    etiqueta: 'Puerto',
                    child: TextFormField(
                      controller: _puertoCtrl,
                      style: monoStyle(fontSize: 15),
                      decoration: const InputDecoration(hintText: '587 / 465'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1 || n > 65535) {
                          return 'Puerto inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchTile(
                icon: Icons.lock_outline,
                title: 'Usar SSL/TLS',
                subtitle:
                    'Actívalo para puerto 465. Para 587 (STARTTLS) déjalo '
                    'apagado.',
                value: _ssl,
                onChanged: (v) => setState(() => _ssl = v),
              ),
            ],
          ),
          espacio,
          FormSection(
            title: 'Tu cuenta de envío',
            icon: Icons.key,
            children: [
              FilaCampos(
                children: [
                  CampoEtiquetado(
                    etiqueta: 'Usuario / correo de envío',
                    child: TextFormField(
                      controller: _usuarioCtrl,
                      decoration: const InputDecoration(
                        hintText: 'tu-correo@gmail.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _requeridoSiActivo,
                    ),
                  ),
                  CampoEtiquetado(
                    etiqueta: 'Contraseña / token',
                    ayuda: _tieneContrasena
                        ? 'Ya hay una guardada. Déjala vacía para conservarla.'
                        : null,
                    child: TextFormField(
                      controller: _passCtrl,
                      decoration: InputDecoration(
                        hintText: _tieneContrasena ? '••••••••' : null,
                        suffixIcon: IconButton(
                          tooltip: _mostrarPassword ? 'Ocultar' : 'Mostrar',
                          icon: Icon(
                            _mostrarPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _mostrarPassword = !_mostrarPassword,
                          ),
                        ),
                      ),
                      obscureText: !_mostrarPassword,
                      validator: (v) {
                        if (!_habilitado) return null;
                        if ((v == null || v.isEmpty) && !_tieneContrasena) {
                          return 'Requerido si el envío está activado';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          espacio,
          FormSection(
            title: 'A dónde llegan',
            icon: Icons.send_outlined,
            children: [
              FilaCampos(
                children: [
                  CampoEtiquetado(
                    etiqueta: 'Correo destino',
                    ayuda: 'A dónde llegan los recordatorios.',
                    child: TextFormField(
                      controller: _destinoCtrl,
                      decoration: const InputDecoration(
                        hintText: 'correo@ejemplo.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _requeridoSiActivo,
                    ),
                  ),
                  CampoEtiquetado(
                    etiqueta: 'Nombre del remitente',
                    ayuda: 'Quién aparece como autor del correo.',
                    child: TextFormField(controller: _remitenteCtrl),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _probando ? null : _probar,
            icon: _probando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(
              _probando ? 'Enviando prueba...' : 'Enviar correo de prueba',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FormSaveButton(onPressed: _guardar, loading: _guardando),
        ],
      ),
    );
  }

  String? _requeridoSiActivo(String? v) {
    if (!_habilitado) return null;
    if (v == null || v.trim().isEmpty) {
      return 'Requerido si el envío está activado';
    }
    return null;
  }
}
