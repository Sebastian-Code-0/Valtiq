import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../db/database.dart';
import '../utils/date_format.dart';
import '../utils/format.dart';
import 'smtp_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static bool get _soportado =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.android);

  static Future<void> init() async {
    if (_initialized || !_soportado) return;

    InitializationSettings settings;
    if (Platform.isLinux) {
      final linux = LinuxInitializationSettings(
        defaultActionName: 'Abrir',
        defaultIcon: AssetsLinuxIcon('assets/logo_icono.png'),
      );
      settings = InitializationSettings(linux: linux);
    } else if (Platform.isAndroid) {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      settings = const InitializationSettings(android: android);
    } else {
      // Windows: AUMID must match the app registered in the Start menu.
      // Without MSIX packaging the toast API still works for basic show().
      const windows = WindowsInitializationSettings(
        appName: 'Valtiq',
        appUserModelId: 'com.valtiq.Valtiq',
        guid: 'a8b4c2d6-1e3f-4a5b-8c9d-0e2f7a6b3c1d',
      );
      settings = const InitializationSettings(windows: windows);
    }

    await _plugin.initialize(settings: settings);

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_soportado) return;
    await init();

    NotificationDetails details;
    if (Platform.isLinux) {
      const linuxDetails = LinuxNotificationDetails(
        defaultActionName: 'Abrir',
        urgency: LinuxNotificationUrgency.normal,
      );
      details = const NotificationDetails(linux: linuxDetails);
    } else if (Platform.isAndroid) {
      const androidDetails = AndroidNotificationDetails(
        'valtiq_recordatorios',
        'Recordatorios',
        channelDescription: 'Notificaciones de recordatorios de pagos',
        importance: Importance.high,
        priority: Priority.high,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );
      details = const NotificationDetails(android: androidDetails);
    } else {
      // Windows: basic toast notification; no extra details needed.
      details = const NotificationDetails(windows: WindowsNotificationDetails());
    }

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static Future<int> revisarRecordatorios(AppDatabase db) async {
    await init();
    final recordatorios = await db.recordatoriosDao.getRecordatoriosActivos();
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    int notificados = 0;
    for (final r in recordatorios) {
      final diaAlerta = DateTime(
        r.fechaAlerta.year,
        r.fechaAlerta.month,
        r.fechaAlerta.day,
      );
      final diasFaltantes = diaAlerta.difference(hoy).inDays;

      final dentroDeVentana =
          diasFaltantes <= r.diasAnticipacion && diasFaltantes >= -7;
      if (!dentroDeVentana) continue;

      final contenido = await _buildContenido(r, db, diasFaltantes);
      final tipo = r.tipoNotificacion;

      if (tipo == 'sistema' || tipo == 'ambos') {
        await showNotification(
          id: r.id,
          title: r.titulo,
          body: contenido.sistema,
        );
        notificados++;
      }
      if (tipo == 'correo' || tipo == 'ambos') {
        await SmtpService.enviarCorreo(
          db: db,
          asunto: 'Recordatorio: ${r.titulo}',
          cuerpo: contenido.email,
        );
      }
    }
    return notificados;
  }

  // Returns both the short OS notification body and the rich email body.
  // A single DB lookup serves both to avoid double queries.
  static Future<({String sistema, String email})> _buildContenido(
    Recordatorio r,
    AppDatabase db,
    int diasFaltantes,
  ) async {
    final estado = _bodyParaRecordatorio(diasFaltantes);

    if (r.referenciaTabla == null || r.referenciaId == null) {
      return (
        sistema: estado,
        email: '📋 Recordatorio: ${r.titulo}\n\n⏰ $estado',
      );
    }

    try {
      return await _buildCuerpoEnriquecido(r, db, diasFaltantes, estado);
    } catch (_) {
      return (
        sistema: estado,
        email: '📋 Recordatorio: ${r.titulo}\n\n⏰ $estado',
      );
    }
  }

  static Future<({String sistema, String email})> _buildCuerpoEnriquecido(
    Recordatorio r,
    AppDatabase db,
    int diasFaltantes,
    String estado,
  ) async {
    final id = r.referenciaId!;

    switch (r.referenciaTabla) {
      case 'deuda':
        final deuda = await db.deudasDao.getDeudaById(id);
        final monto = '${formatCOP(deuda.montoOriginal)} COP';
        final sistema =
            'Pago a ${deuda.acreedorNombre} — $monto — $estado';

        final buf = StringBuffer()
          ..writeln('📋 Recordatorio: ${r.titulo}')
          ..writeln()
          ..writeln('💰 Monto original: $monto');
        if (deuda.fechaLimite != null) {
          buf.writeln('📅 Fecha límite: ${formatFechaLegible(deuda.fechaLimite!)}');
        }
        buf.writeln('⏰ Estado: $estado');
        if (deuda.cuotaMensual != null) {
          buf.write('💳 Cuota mensual: ${formatCOP(deuda.cuotaMensual!)} COP');
        }

        return (sistema: sistema, email: buf.toString().trimRight());

      case 'prestamo':
        final prestamo = await db.prestamosDao.getPrestamoById(id);
        final monto = '${formatCOP(prestamo.montoPrestado)} COP';
        final sistema =
            'Cobro a ${prestamo.deudorNombre} — $monto — $estado';

        final buf = StringBuffer()
          ..writeln('📋 Recordatorio: ${r.titulo}')
          ..writeln()
          ..writeln('💰 Monto prestado: $monto');
        if (prestamo.fechaPactadaPago != null) {
          buf.writeln(
            '📅 Fecha pactada: ${formatFechaLegible(prestamo.fechaPactadaPago!)}',
          );
        }
        buf.writeln('⏰ Estado: $estado');
        if (prestamo.deudorContacto.isNotEmpty) {
          buf.write('📞 Contacto: ${prestamo.deudorContacto}');
        }

        return (sistema: sistema, email: buf.toString().trimRight());

      case 'gasto':
        final gasto = await db.gastosFijosDao.getGastoFijoById(id);
        final monto = '${formatCOP(gasto.monto)} COP';
        final sistema = '${gasto.concepto} — $monto — $estado';

        final buf = StringBuffer()
          ..writeln('📋 Recordatorio: ${r.titulo}')
          ..writeln()
          ..writeln('💰 Monto: $monto')
          ..writeln('🔄 Frecuencia: ${gasto.frecuencia}')
          ..write('⏰ Estado: $estado');

        return (sistema: sistema, email: buf.toString());

      default:
        final estado0 = _bodyParaRecordatorio(diasFaltantes);
        return (
          sistema: estado0,
          email: '📋 Recordatorio: ${r.titulo}\n\n⏰ $estado0',
        );
    }
  }

  static String _bodyParaRecordatorio(int diasFaltantes) {
    if (diasFaltantes == 0) return 'Es hoy';
    if (diasFaltantes < 0) {
      final n = -diasFaltantes;
      return 'Vencido hace $n ${n == 1 ? 'día' : 'días'}';
    }
    if (diasFaltantes == 1) return 'Mañana';
    return 'Vence en $diasFaltantes días';
  }

  static Future<void> cancelar(int id) async {
    await init();
    try {
      // cancel() requires MSIX packaging on Windows; ignore the error otherwise.
      await _plugin.cancel(id: id);
    } catch (_) {}
  }
}
