import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mailer/mailer.dart';

import '../db/database.dart';
import '../utils/date_format.dart';
import '../utils/fecha_civil.dart';
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
      const android = AndroidInitializationSettings('@drawable/ic_stat_notif');
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
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      const canal = AndroidNotificationChannel(
        'valtiq_recordatorios',
        'Recordatorios',
        description: 'Notificaciones de recordatorios de pagos',
        importance: Importance.high,
      );
      await androidImpl?.createNotificationChannel(canal);
      await androidImpl?.requestNotificationsPermission();
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
        icon: '@drawable/ic_stat_notif',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );
      details = const NotificationDetails(android: androidDetails);
    } else {
      // Windows: basic toast notification; no extra details needed.
      details = const NotificationDetails(
        windows: WindowsNotificationDetails(),
      );
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
    final lista = await db.recordatoriosDao.getRecordatoriosActivos();
    final ahora = DateTime.now();
    // "hoy" (local) se usa para deduplicar contra ultimaNotificacion/
    // ultimoEnvioCorreo, que son instantes reales — se quedan en su
    // convención local, sin tocar.
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    // "hoyCivil" (UTC-medianoche) se usa para comparar contra fechaAlerta,
    // que se guarda como medianoche UTC (ver lib/utils/fecha_civil.dart) —
    // para que la resta de días dé múltiplos exactos de 24h, ambos lados
    // deben estar en la misma convención.
    final hoyCivil = normalizarFechaCivil(ahora);
    int notificados = 0;

    // Carga en lote las referencias (deuda/préstamo/gasto) en vez de una
    // consulta por recordatorio (evita N+1).
    final deudaIds = <int>[];
    final prestamoIds = <int>[];
    final gastoIds = <int>[];
    for (final r in lista) {
      final id = r.referenciaId;
      if (id == null) continue;
      switch (r.referenciaTabla) {
        case 'deuda':
          deudaIds.add(id);
        case 'prestamo':
          prestamoIds.add(id);
        case 'gasto':
          gastoIds.add(id);
      }
    }
    final deudasPorId = {
      for (final d in await db.deudasDao.getDeudasByIds(deudaIds)) d.id: d,
    };
    final prestamosPorId = {
      for (final p in await db.prestamosDao.getPrestamosByIds(prestamoIds))
        p.id: p,
    };
    final gastosPorId = {
      for (final g in await db.gastosFijosDao.getGastosFijosByIds(gastoIds))
        g.id: g,
    };

    // Resuelve ventana/reprogramación una sola vez; solo los recordatorios
    // "accionables" (dentro de ventana, no reprogramados este ciclo) pueden
    // notificar hoy.
    final accionables = <(Recordatorio, int)>[];
    for (final r in lista) {
      final diaAlerta = fechaCivilGuardada(r.fechaAlerta);
      final diasFaltantes = diaAlerta.difference(hoyCivil).inDays;

      // Si pasó la ventana de gracia y tiene repetir, reprogramar al mes siguiente.
      if (diasFaltantes < -7 && r.repetir) {
        // Avanza mes a mes hasta que la fecha quede en ventana o futuro.
        DateTime nuevaFecha = diaAlerta;
        while (true) {
          nuevaFecha = DateTime.utc(
            nuevaFecha.year,
            nuevaFecha.month + 1,
            nuevaFecha.day,
          );
          final diff = nuevaFecha.difference(hoyCivil).inDays;
          if (diff >= -7) break;
        }
        await db.recordatoriosDao.reprogramarMensual(r.id, nuevaFecha);
        continue;
      }

      final dentroDeVentana =
          diasFaltantes <= r.diasAnticipacion && diasFaltantes >= -7;
      if (!dentroDeVentana) continue;

      accionables.add((r, diasFaltantes));
    }

    // Solo abre conexión SMTP si hay al menos un correo que potencialmente
    // se vaya a enviar en esta corrida.
    final necesitaSmtp = accionables.any((item) {
      final r = item.$1;
      return (r.tipoNotificacion == 'correo' ||
              r.tipoNotificacion == 'ambos') &&
          _debeAvisar(
            frecuencia: r.frecuenciaAviso,
            ultimoAviso: r.ultimoEnvioCorreo,
            hoy: hoy,
          );
    });

    ConfigSmtp? smtpConfig;
    PersistentConnection? conexion;

    if (necesitaSmtp) {
      final config = await db.configSmtpDao.getConfig();
      final configCompleta =
          config.habilitado &&
          config.servidor.isNotEmpty &&
          config.usuario.isNotEmpty &&
          config.correoDestino.isNotEmpty;
      if (configCompleta) {
        final password = await db.configSmtpDao.getPassword() ?? '';
        smtpConfig = config;
        try {
          conexion = PersistentConnection(
            SmtpService.buildServer(config, password),
          );
        } catch (e) {
          debugPrint('NotificationService: no se pudo abrir la conexión SMTP: $e');
          conexion = null;
        }
      }
    }

    try {
      for (final item in accionables) {
        final r = item.$1;
        final diasFaltantes = item.$2;
        final tipo = r.tipoNotificacion;
        final contenido = _buildContenido(
          r,
          deudasPorId,
          prestamosPorId,
          gastosPorId,
          diasFaltantes,
        );

        if (tipo == 'sistema' || tipo == 'ambos') {
          if (_debeAvisar(
            frecuencia: r.frecuenciaAviso,
            ultimoAviso: r.ultimaNotificacion,
            hoy: hoy,
          )) {
            await showNotification(
              id: r.id,
              title: r.titulo,
              body: contenido.sistema,
            );
            await db.recordatoriosDao.marcarNotificado(r.id, ahora);
            notificados++;
          }
        }

        if (tipo == 'correo' || tipo == 'ambos') {
          if (conexion != null &&
              smtpConfig != null &&
              _debeAvisar(
                frecuencia: r.frecuenciaAviso,
                ultimoAviso: r.ultimoEnvioCorreo,
                hoy: hoy,
              )) {
            try {
              final res = await SmtpService.enviarConConexion(
                connection: conexion,
                config: smtpConfig,
                asunto: 'Recordatorio: ${r.titulo}',
                cuerpo: contenido.email,
              );
              if (res.exito) {
                await db.recordatoriosDao.marcarEnvioCorreo(r.id, ahora);
              }
            } catch (e) {
              debugPrint(
                'NotificationService: fallo al enviar el correo del '
                'recordatorio ${r.id}: $e',
              );
              // Un envío fallido no debe impedir que se intenten los siguientes.
            }
          }
        }
      }
    } finally {
      if (conexion != null) {
        try {
          await conexion.close();
        } catch (e) {
          debugPrint('NotificationService: fallo al cerrar la conexión SMTP: $e');
        }
      }
    }

    return notificados;
  }

  /// Nombres (`concepto`) de los ingresos 'unico' que la última corrida de
  /// `revisarIngresosUnicosVencidos` desactivó, para que `ShellScreen` los
  /// avise con un SnackBar al arrancar (no una notificación del sistema —
  /// decisión explícita: esto es un aviso de "algo cambió en tu sesión
  /// actual", no algo que amerite salir de la app). Mismo patrón que
  /// `CryptoService.claveFueRegenerada`: se fija una vez en `main()` antes
  /// de `runApp`, `ShellScreen.initState()` lo lee una sola vez.
  static List<String> ingresosUnicosDesactivados = [];

  /// Revisa ingresos 'unico' cuyo mes ya pasó y los desactiva automáticamente
  /// (dejan de sumarse en `IngresosDao.watchTotalIngresosMes`, pero se
  /// mantienen visibles en el historial — ver `IngresosDao.desactivarVarios`,
  /// nunca se borran). Guarda los nombres en `ingresosUnicosDesactivados`
  /// para que la UI los muestre con un SnackBar, agrupados en un solo aviso.
  static Future<int> revisarIngresosUnicosVencidos(AppDatabase db) async {
    final ahora = DateTime.now();
    final inicioMesActual = DateTime.utc(ahora.year, ahora.month, 1);
    final vencidos = await db.ingresosDao.getUnicosVencidos(inicioMesActual);
    if (vencidos.isEmpty) return 0;

    await db.ingresosDao.desactivarVarios(vencidos.map((i) => i.id).toList());
    ingresosUnicosDesactivados = vencidos.map((i) => i.concepto).toList();

    return vencidos.length;
  }

  static bool _debeAvisar({
    required String frecuencia,
    required DateTime? ultimoAviso,
    required DateTime hoy,
  }) {
    if (ultimoAviso == null) return true;
    if (frecuencia == 'unica') return false;
    // 'diaria': un aviso por día calendario
    final ultimoDia = DateTime(
      ultimoAviso.year,
      ultimoAviso.month,
      ultimoAviso.day,
    );
    return hoy.isAfter(ultimoDia);
  }

  // Returns both the short OS notification body and the rich email body.
  // Las referencias (deuda/préstamo/gasto) ya vienen precargadas en lote en
  // los mapas, así que aquí no se consulta la base de datos.
  static ({String sistema, String email}) _buildContenido(
    Recordatorio r,
    Map<int, Deuda> deudasPorId,
    Map<int, Prestamo> prestamosPorId,
    Map<int, GastosFijo> gastosPorId,
    int diasFaltantes,
  ) {
    final estado = _bodyParaRecordatorio(diasFaltantes);

    if (r.referenciaTabla == null || r.referenciaId == null) {
      return (
        sistema: estado,
        email: '📋 Recordatorio: ${r.titulo}\n\n⏰ $estado',
      );
    }

    try {
      return _buildCuerpoEnriquecido(
        r,
        deudasPorId,
        prestamosPorId,
        gastosPorId,
        diasFaltantes,
        estado,
      );
    } catch (e) {
      debugPrint(
        'NotificationService: fallo al construir el cuerpo enriquecido del '
        'recordatorio ${r.id}, usando el cuerpo simple: $e',
      );
      return (
        sistema: estado,
        email: '📋 Recordatorio: ${r.titulo}\n\n⏰ $estado',
      );
    }
  }

  static ({String sistema, String email}) _buildCuerpoEnriquecido(
    Recordatorio r,
    Map<int, Deuda> deudasPorId,
    Map<int, Prestamo> prestamosPorId,
    Map<int, GastosFijo> gastosPorId,
    int diasFaltantes,
    String estado,
  ) {
    final id = r.referenciaId!;

    switch (r.referenciaTabla) {
      case 'deuda':
        final deuda = deudasPorId[id];
        if (deuda == null) {
          const msg = 'Recordatorio vinculado a una deuda ya eliminada.';
          return (sistema: msg, email: msg);
        }
        final monto = '${formatCOP(deuda.montoOriginal)} COP';
        final sistema = 'Pago a ${deuda.acreedorNombre} — $monto — $estado';

        final buf = StringBuffer()
          ..writeln('📋 Recordatorio: ${r.titulo}')
          ..writeln()
          ..writeln('💰 Monto original: $monto');
        if (deuda.fechaLimite != null) {
          buf.writeln(
            '📅 Fecha límite: '
            '${formatFechaLegible(fechaCivilGuardada(deuda.fechaLimite!))}',
          );
        }
        buf.writeln('⏰ Estado: $estado');
        if (deuda.cuotaMensual != null) {
          buf.write('💳 Cuota mensual: ${formatCOP(deuda.cuotaMensual!)} COP');
        }

        return (sistema: sistema, email: buf.toString().trimRight());

      case 'prestamo':
        final prestamo = prestamosPorId[id];
        if (prestamo == null) {
          const msg = 'Recordatorio vinculado a un préstamo ya eliminado.';
          return (sistema: msg, email: msg);
        }
        final monto = '${formatCOP(prestamo.montoPrestado)} COP';
        final sistema = 'Cobro a ${prestamo.deudorNombre} — $monto — $estado';

        final buf = StringBuffer()
          ..writeln('📋 Recordatorio: ${r.titulo}')
          ..writeln()
          ..writeln('💰 Monto prestado: $monto');
        if (prestamo.fechaPactadaPago != null) {
          buf.writeln(
            '📅 Fecha pactada: '
            '${formatFechaLegible(fechaCivilGuardada(prestamo.fechaPactadaPago!))}',
          );
        }
        buf.writeln('⏰ Estado: $estado');
        if (prestamo.deudorContacto.isNotEmpty) {
          buf.write('📞 Contacto: ${prestamo.deudorContacto}');
        }

        return (sistema: sistema, email: buf.toString().trimRight());

      case 'gasto':
        final gasto = gastosPorId[id];
        if (gasto == null) {
          const msg = 'Recordatorio vinculado a un gasto fijo ya eliminado.';
          return (sistema: msg, email: msg);
        }
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
    } catch (e) {
      debugPrint('NotificationService: fallo al cancelar la notificación $id: $e');
    }
  }
}
