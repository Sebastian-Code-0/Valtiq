import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/smtp_service.dart';

ConfigSmtp _config({
  String servidor = 'smtp.example.com',
  int puerto = 587,
  String usuario = 'usuario@example.com',
  String correoDestino = 'destino@example.com',
  String nombreRemitente = 'Valtiq',
  bool ssl = false,
  bool habilitado = true,
}) {
  return ConfigSmtp(
    id: 1,
    servidor: servidor,
    puerto: puerto,
    usuario: usuario,
    tieneContrasena: true,
    correoDestino: correoDestino,
    nombreRemitente: nombreRemitente,
    ssl: ssl,
    habilitado: habilitado,
    actualizadoEn: DateTime(2026, 1, 1),
  );
}

void main() {
  group('SmtpService.buildServer construcción de mensajes/servidor', () {
    test('smtp.gmail.com usa el helper gmail() con host y credenciales', () {
      final config = _config(servidor: 'smtp.gmail.com');
      final server = SmtpService.buildServer(config, 'clave-app');

      expect(server.host, 'smtp.gmail.com');
      expect(server.username, config.usuario);
      expect(server.password, 'clave-app');
    });

    test(
      'smtp.office365.com fuerza port 587, ssl false, allowInsecure false',
      () {
        final config = _config(
          servidor: 'smtp.office365.com',
          puerto: 465,
          ssl: true,
        );
        final server = SmtpService.buildServer(config, 'clave');

        expect(server.host, 'smtp.office365.com');
        expect(server.port, 587);
        expect(server.ssl, false);
        expect(server.allowInsecure, false);
        expect(server.username, config.usuario);
        expect(server.password, 'clave');
      },
    );

    test(
      'servidor genérico usa puerto/ssl/usuario tal como vienen en config',
      () {
        final config = _config(
          servidor: 'mail.miempresa.com',
          puerto: 465,
          usuario: 'notificaciones@miempresa.com',
          ssl: true,
        );
        final server = SmtpService.buildServer(config, 'secreta');

        expect(server.host, 'mail.miempresa.com');
        expect(server.port, 465);
        expect(server.ssl, true);
        expect(server.allowInsecure, false);
        expect(server.username, 'notificaciones@miempresa.com');
        expect(server.password, 'secreta');
      },
    );
  });

  group('SmtpService.mensajeAmigable mapeo de errores', () {
    test('535 → credenciales incorrectas', () {
      expect(
        SmtpService.mensajeAmigable('535 Authentication failed'),
        contains('Credenciales incorrectas'),
      );
    });

    test(
      'BadCredentials (sin importar mayúsculas) → credenciales incorrectas',
      () {
        expect(
          SmtpService.mensajeAmigable('BadCredentials'),
          contains('Credenciales incorrectas'),
        );
      },
    );

    test('password not accepted → credenciales incorrectas', () {
      expect(
        SmtpService.mensajeAmigable('Username and Password not accepted'),
        contains('Credenciales incorrectas'),
      );
    });

    test('SocketException de conexión → error de conexión', () {
      expect(
        SmtpService.mensajeAmigable('SocketException: Connection refused'),
        contains('No se pudo conectar al servidor de correo'),
      );
    });

    test('timeout → error de conexión', () {
      expect(
        SmtpService.mensajeAmigable('Connection timed out'),
        contains('No se pudo conectar al servidor de correo'),
      );
    });

    test('host lookup falla → error de conexión', () {
      expect(
        SmtpService.mensajeAmigable('Failed host lookup'),
        contains('No se pudo conectar al servidor de correo'),
      );
    });

    test('550 destinatario rechazado → correo destino inválido', () {
      expect(
        SmtpService.mensajeAmigable('550 5.1.1 Recipient address rejected'),
        contains('El correo destino no es válido'),
      );
    });

    test('recipient sin código 550 → correo destino inválido', () {
      expect(
        SmtpService.mensajeAmigable('Invalid recipient'),
        contains('El correo destino no es válido'),
      );
    });

    test('certificate SSL inválido → error de seguridad SSL/TLS', () {
      expect(
        SmtpService.mensajeAmigable('SSL certificate problem'),
        contains('Error de seguridad SSL/TLS'),
      );
    });

    test('TLS handshake falla → error de seguridad SSL/TLS', () {
      expect(
        SmtpService.mensajeAmigable('TLS handshake failed'),
        contains('Error de seguridad SSL/TLS'),
      );
    });

    test('error desconocido → mensaje genérico', () {
      expect(
        SmtpService.mensajeAmigable('algo totalmente inesperado ocurrió'),
        'No se pudo enviar el correo. Intenta de nuevo.',
      );
    });
  });
}
