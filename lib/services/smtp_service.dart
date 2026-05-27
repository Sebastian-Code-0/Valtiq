import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../db/database.dart';

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
    return _enviarCon(
      config: config,
      password: password,
      asunto: 'Prueba de configuración Valtiq',
      cuerpo:
          'Si recibes este correo, la configuración SMTP de Valtiq funciona correctamente.',
    );
  }

  static Future<SmtpResult> _enviarCon({
    required ConfigSmtp config,
    required String password,
    required String asunto,
    required String cuerpo,
  }) async {
    try {
      final server = _build(config, password);
      final remitente =
          config.nombreRemitente.isEmpty ? 'Valtiq' : config.nombreRemitente;
      final mensaje = Message()
        ..from = Address(config.usuario, remitente)
        ..recipients.add(config.correoDestino)
        ..subject = asunto
        ..text = cuerpo;

      await send(mensaje, server);
      return const SmtpResult(exito: true, mensaje: 'Correo enviado');
    } on MailerException catch (e) {
      final detalle = e.problems.isNotEmpty
          ? e.problems.map((p) => '${p.code}: ${p.msg}').join('; ')
          : e.message;
      return SmtpResult(
        exito: false,
        mensaje: 'Error al enviar: $detalle',
      );
    } catch (e) {
      return SmtpResult(exito: false, mensaje: 'Error inesperado: $e');
    }
  }
}
