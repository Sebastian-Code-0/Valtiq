import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../db/database.dart';
import 'email_template.dart';

class SmtpResult {
  const SmtpResult({required this.exito, this.mensaje});

  final bool exito;
  final String? mensaje;
}

class SmtpService {
  static SmtpServer _build(ConfigSmtp config, String password) {
    if (config.servidor == 'smtp.gmail.com') {
      return gmail(config.usuario, password);
    }
    if (config.servidor == 'smtp.office365.com') {
      return SmtpServer(
        'smtp.office365.com',
        port: 587,
        username: config.usuario,
        password: password,
        ssl: false,
        allowInsecure: false,
      );
    }
    return SmtpServer(
      config.servidor,
      port: config.puerto,
      username: config.usuario,
      password: password,
      ssl: config.ssl,
      allowInsecure: false,
    );
  }

  /// Expone la construcción del [SmtpServer] para reusarlo en una
  /// [PersistentConnection] (ej. envío en lote de recordatorios).
  static SmtpServer buildServer(ConfigSmtp config, String password) =>
      _build(config, password);

  static Future<SmtpResult> enviarCorreo({
    required AppDatabase db,
    required String asunto,
    required String cuerpo,
  }) async {
    final config = await db.configSmtpDao.getConfig();
    if (!config.habilitado) {
      return const SmtpResult(
        exito: false,
        mensaje: 'SMTP no está habilitado en la configuración',
      );
    }
    if (config.servidor.isEmpty ||
        config.usuario.isEmpty ||
        config.correoDestino.isEmpty) {
      return const SmtpResult(
        exito: false,
        mensaje: 'Configuración SMTP incompleta',
      );
    }
    final password = await db.configSmtpDao.getPassword() ?? '';
    return _enviarCon(
      config: config,
      password: password,
      asunto: asunto,
      cuerpo: cuerpo,
    );
  }

  static Future<SmtpResult> probarConfiguracion({
    required ConfigSmtp config,
    required String password,
  }) async {
    if (config.servidor.isEmpty ||
        config.usuario.isEmpty ||
        config.correoDestino.isEmpty) {
      return const SmtpResult(
        exito: false,
        mensaje: 'Configuración SMTP incompleta',
      );
    }
    const cuerpo =
        '✅ Configuración exitosa — Tu cuenta de correo está conectada correctamente con Valtiq.\n\n'
        'A partir de ahora recibirás recordatorios de tus deudas, préstamos y pagos en este correo.';
    return _enviarCon(
      config: config,
      password: password,
      asunto: 'Prueba de configuración Valtiq',
      cuerpo: cuerpo,
    );
  }

  /// Envía un correo reusando una [PersistentConnection] ya abierta, para
  /// evitar reconectar por cada recordatorio en una misma corrida por lote.
  /// No usado por [enviarCorreo] ni [probarConfiguracion] (esos siguen
  /// abriendo/cerrando una conexión por envío).
  static Future<SmtpResult> enviarConConexion({
    required PersistentConnection connection,
    required ConfigSmtp config,
    required String asunto,
    required String cuerpo,
  }) async {
    try {
      final remitente = config.nombreRemitente.isEmpty
          ? 'Valtiq'
          : config.nombreRemitente;
      final mensaje = Message()
        ..from = Address(config.usuario, remitente)
        ..recipients.add(config.correoDestino)
        ..subject = asunto
        ..text = cuerpo
        ..html = EmailTemplate.build(asunto, cuerpo);

      await connection.send(mensaje);
      return const SmtpResult(exito: true, mensaje: 'Correo enviado');
    } on MailerException catch (e) {
      final detalle = e.problems.isNotEmpty
          ? e.problems.map((p) => '${p.code}: ${p.msg}').join('; ')
          : e.message;
      return SmtpResult(exito: false, mensaje: _mensajeAmigable(detalle));
    } catch (e) {
      return SmtpResult(exito: false, mensaje: _mensajeAmigable(e.toString()));
    }
  }

  static Future<SmtpResult> _enviarCon({
    required ConfigSmtp config,
    required String password,
    required String asunto,
    required String cuerpo,
  }) async {
    try {
      final server = _build(config, password);
      final remitente = config.nombreRemitente.isEmpty
          ? 'Valtiq'
          : config.nombreRemitente;
      final mensaje = Message()
        ..from = Address(config.usuario, remitente)
        ..recipients.add(config.correoDestino)
        ..subject = asunto
        ..text = cuerpo
        ..html = EmailTemplate.build(asunto, cuerpo);

      await send(mensaje, server);
      return const SmtpResult(exito: true, mensaje: 'Correo enviado');
    } on MailerException catch (e) {
      final detalle = e.problems.isNotEmpty
          ? e.problems.map((p) => '${p.code}: ${p.msg}').join('; ')
          : e.message;
      return SmtpResult(exito: false, mensaje: _mensajeAmigable(detalle));
    } catch (e) {
      return SmtpResult(exito: false, mensaje: _mensajeAmigable(e.toString()));
    }
  }

  static String _mensajeAmigable(String errorTecnico) {
    final e = errorTecnico.toLowerCase();
    if (e.contains('535') ||
        e.contains('authentication') ||
        e.contains('password not accepted') ||
        e.contains('badcredentials')) {
      return 'Credenciales incorrectas. Si usas Gmail, necesitas una Contraseña de Aplicación (no tu contraseña normal). Ve a myaccount.google.com → Seguridad → Verificación en dos pasos → Contraseñas de aplicación.';
    }
    if (e.contains('connection') ||
        e.contains('timeout') ||
        e.contains('connect')) {
      return 'No se pudo conectar al servidor de correo. Verifica tu conexión a internet y los datos del servidor SMTP.';
    }
    if (e.contains('550') || e.contains('recipient')) {
      return 'El correo destino no es válido o fue rechazado por el servidor.';
    }
    if (e.contains('ssl') || e.contains('tls') || e.contains('certificate')) {
      return 'Error de seguridad SSL/TLS. Verifica el puerto y la configuración de seguridad del servidor.';
    }
    return 'Error al enviar: $errorTecnico';
  }
}
