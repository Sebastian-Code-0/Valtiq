import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../services/smtp_service.dart';
import '../../theme/theme.dart';
import '../../utils/form_widgets.dart';

class ConfigSmtpScreen extends StatefulWidget {
  const ConfigSmtpScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<ConfigSmtpScreen> createState() => _ConfigSmtpScreenState();
}

typedef _Preset = ({String nombre, String servidor, int puerto, bool ssl});

const _presets = <_Preset>[
  (nombre: 'Gmail', servidor: 'smtp.gmail.com', puerto: 587, ssl: false),
  (
    nombre: 'Outlook',
    servidor: 'smtp.office365.com',
    puerto: 587,
    ssl: false,
  ),
  (
    nombre: 'Yahoo',
    servidor: 'smtp.mail.yahoo.com',
    puerto: 587,
    ssl: false,
  ),
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

  void _aplicarPreset(_Preset preset) {
    setState(() {
      _servidorCtrl.text = preset.servidor;
      _puertoCtrl.text = preset.puerto.toString();
      _ssl = preset.ssl;
    });
  }

  @override
  void initState() {
    super.initState();
    _cargarConfig();
  }

  Future<void> _cargarConfig() async {
    final config = await widget.db.configSmtpDao.getConfig();
    final password = await widget.db.configSmtpDao.getPassword();
    if (!mounted) return;
    setState(() {
      _servidorCtrl.text = config.servidor;
      _puertoCtrl.text = config.puerto.toString();
      _usuarioCtrl.text = config.usuario;
      _passCtrl.text = password ?? '';
      _destinoCtrl.text = config.correoDestino;
      _remitenteCtrl.text = config.nombreRemitente;
      _ssl = config.ssl;
      _habilitado = config.habilitado;
      _cargando = false;
    });
  }

  @override
  void dispose() {
    _servidorCtrl.dispose();
    _puertoCtrl.dispose();
    _usuarioCtrl.dispose();
    _passCtrl.dispose();
    _destinoCtrl.dispose();
    _remitenteCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    await widget.db.configSmtpDao.guardarConfig(
      servidor: _servidorCtrl.text.trim(),
      puerto: int.tryParse(_puertoCtrl.text.trim()) ?? 587,
      usuario: _usuarioCtrl.text.trim(),
      contrasena: _passCtrl.text,
      correoDestino: _destinoCtrl.text.trim(),
      nombreRemitente: _remitenteCtrl.text.trim().isEmpty
          ? 'Valtiq'
          : _remitenteCtrl.text.trim(),
      ssl: _ssl,
      habilitado: _habilitado,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada')),
    );
  }

  Future<void> _probar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _probando = true);

    final config = ConfigSmtp(
      id: 1,
      servidor: _servidorCtrl.text.trim(),
      puerto: int.tryParse(_puertoCtrl.text.trim()) ?? 587,
      usuario: _usuarioCtrl.text.trim(),
      tieneContrasena: _passCtrl.text.isNotEmpty,
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
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _probando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.mensaje ?? (result.exito ? 'OK' : 'Falló')),
        backgroundColor: result.exito ? AppColors.positivo : AppColors.alerta,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración SMTP')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Presets rápidos',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        for (final p in _presets)
                          OutlinedButton(
                            onPressed: () => _aplicarPreset(p),
                            child: Text(p.nombre),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Servidor',
              icon: Icons.dns_outlined,
              children: [
                TextFormField(
                  controller: _servidorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Servidor SMTP',
                    hintText: 'smtp.gmail.com',
                    prefixIcon: Icon(Icons.dns_outlined),
                  ),
                  validator: (v) {
                    if (!_habilitado) return null;
                    if (v == null || v.trim().isEmpty) {
                      return 'Requerido si SMTP está habilitado';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _puertoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Puerto',
                    hintText: '587 / 465',
                    prefixIcon: Icon(Icons.numbers),
                  ),
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
                const SizedBox(height: AppSpacing.sm),
                SwitchTile(
                  icon: Icons.lock_outline,
                  title: 'Usar SSL/TLS',
                  subtitle:
                      'Actívalo para puerto 465. Para 587 (STARTTLS) déjalo apagado.',
                  value: _ssl,
                  onChanged: (v) => setState(() => _ssl = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Credenciales',
              icon: Icons.key,
              children: [
                TextFormField(
                  controller: _usuarioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Usuario / correo de envío',
                    hintText: 'tu-correo@gmail.com',
                    prefixIcon: Icon(Icons.account_circle_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (!_habilitado) return null;
                    if (v == null || v.trim().isEmpty) {
                      return 'Requerido si SMTP está habilitado';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passCtrl,
                  decoration: InputDecoration(
                    labelText: 'Contraseña / token',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
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
                    if (v == null || v.isEmpty) {
                      return 'Requerido si SMTP está habilitado';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Destinatario',
              icon: Icons.send_outlined,
              children: [
                TextFormField(
                  controller: _destinoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo destino',
                    hintText: 'A dónde llegan los recordatorios',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (!_habilitado) return null;
                    if (v == null || v.trim().isEmpty) {
                      return 'Requerido si SMTP está habilitado';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _remitenteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del remitente',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SwitchTile(
                  icon: Icons.toggle_on,
                  title: 'Habilitar envío de correo',
                  subtitle:
                      'Los recordatorios "correo" o "ambos" enviarán email.',
                  value: _habilitado,
                  onChanged: (v) => setState(() => _habilitado = v),
                ),
              ),
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
                  : const Icon(Icons.send),
              label: Text(
                _probando ? 'Enviando prueba...' : 'Enviar correo de prueba',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FormSaveButton(onPressed: _guardar, loading: _guardando),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
