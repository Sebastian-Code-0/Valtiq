import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mailer/mailer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:drift/drift.dart' show TableUpdateQuery;

import '../db/database.dart';
import '../utils/date_format.dart';
import '../utils/fecha_civil.dart';
import '../utils/format.dart';
import 'notification_planner.dart';
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
        defaultIcon: AssetsLinuxIcon('assets/logo_app.png'),
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
    }

    _initialized = true;
  }

  /// Pide el permiso de notificaciones en Android (13+ pide diálogo nativo
  /// al usuario). Separado de `init()` a propósito: `init()` corre antes de
  /// `runApp()` en `main()`, y esperar la respuesta real del diálogo ahí
  /// bloquearía el primer frame de la app hasta que el usuario decida —
  /// llamar esto DESPUÉS de `runApp()` (sin esperar el resultado) deja que
  /// la app se muestre de inmediato, con el diálogo apareciendo encima.
  static Future<void> solicitarPermisoNotificaciones() async {
    if (!_soportado || !Platform.isAndroid) return;
    await init();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
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
      details = NotificationDetails(android: _detallesAndroidPara(body));
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

  static bool _revisando = false;

  /// Se llama al arrancar la app y cada vez que vuelve a primer plano (ver
  /// `ShellScreen`). Si ya hay una revisión corriendo, la nueva se descarta:
  /// dos a la vez podrían avisar dos veces el mismo recordatorio.
  static Future<int> revisarRecordatorios(AppDatabase db) async {
    if (_revisando) return 0;
    _revisando = true;
    try {
      return await _revisarRecordatorios(db);
    } finally {
      _revisando = false;
    }
  }

  static Future<int> _revisarRecordatorios(AppDatabase db) async {
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

    final refs = await _cargarReferencias(db, lista);
    final deudasPorId = refs.deudas;
    final prestamosPorId = refs.prestamos;
    final gastosPorId = refs.gastos;

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
        // Siempre se suma desde la fecha ORIGINAL (no desde el paso
        // anterior) para que un día 31 que pasó por febrero vuelva a caer
        // en 31 y no se quede en 28.
        // `diaOriginal` (schemaVersion 15) recuerda el día que eligió el
        // usuario: sin él, un 31 que cayó en 28 de febrero se quedaba en 28
        // todos los meses siguientes.
        final dia = r.diaOriginal ?? diaAlerta.day;
        DateTime nuevaFecha = diaAlerta;
        for (var meses = 1; ; meses++) {
          nuevaFecha = sumarMesesConDia(diaAlerta, meses, dia);
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
          debugPrint(
            'NotificationService: no se pudo abrir la conexión SMTP: $e',
          );
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

        // Donde hay avisos programados (Android), el aviso de HOY ya está
        // agendado para su hora: mostrarlo ahora, antes de tiempo, lo
        // duplicaría. Aquí solo se atiende lo que ya debió sonar y no sonó
        // (recordatorio creado tarde, permiso recién concedido…). En PC no
        // hay nada programado, así que se avisa al abrir, como siempre.
        final horaAviso = DateTime(
          ahora.year,
          ahora.month,
          ahora.day,
          r.horaAviso,
          r.minutoAviso,
        );
        final horaCumplida =
            !programacionSoportada || !ahora.isBefore(horaAviso);

        if ((tipo == 'sistema' || tipo == 'ambos') && horaCumplida) {
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
          debugPrint(
            'NotificationService: fallo al cerrar la conexión SMTP: $e',
          );
        }
      }
    }

    return notificados;
  }

  // ───────────────────────── Avisos programados ─────────────────────────
  //
  // En Android los avisos se le dejan PROGRAMADOS al sistema operativo
  // (`zonedSchedule`): suenan a su hora aunque Valtiq esté cerrado, y el
  // receptor de arranque del plugin (ver AndroidManifest.xml) los vuelve a
  // programar solo después de reiniciar o encender el celular. Todo local:
  // sin servidor ni internet.
  //
  // Linux no permite programar avisos y Windows solo con empaquetado MSIX,
  // así que en PC se mantiene el aviso al abrir / volver a la app.

  /// Sobreescribible en tests (el host de `flutter test` nunca es Android).
  @visibleForTesting
  static bool? programacionSoportadaOverride;

  static bool get programacionSoportada =>
      programacionSoportadaOverride ?? (!kIsWeb && Platform.isAndroid);

  static const _kProgramados = 'valtiq_avisos_programados';
  static const _kExactos = 'valtiq_avisos_exactos';
  static const _kDiario = 'valtiq_recordatorio_diario';
  static const _kDiarioMinutos = 'valtiq_recordatorio_diario_minutos';

  /// Los avisos programados usan ids desde aquí hacia arriba, para no
  /// chocar con los avisos inmediatos (que usan el id del recordatorio).
  static const _idBaseProgramados = 1000000;
  static const _idRecordatorioDiario = 999999;

  /// 8:00 p. m., en minutos desde medianoche.
  static const recordatorioDiarioPorDefecto = 20 * 60;

  /// Cómo se ve un aviso en Android: el ícono pequeño (silueta blanca del
  /// logo, Android no permite colores ahí) teñido del vino de la marca, el
  /// ícono de la app a la derecha y el texto completo al desplegarlo (sin
  /// esto, un texto largo se corta con "…").
  static AndroidNotificationDetails _detallesAndroidPara(String cuerpo) =>
      AndroidNotificationDetails(
        'valtiq_recordatorios',
        'Recordatorios',
        channelDescription: 'Notificaciones de recordatorios de pagos',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        icon: '@drawable/ic_stat_notif',
        largeIcon: const DrawableResourceAndroidBitmap(
          '@drawable/ic_notif_grande',
        ),
        color: _colorMarca,
        styleInformation: BigTextStyleInformation(cuerpo),
      );

  /// Vino de la marca; se lee sobre la cortina clara y la oscura.
  static const _colorMarca = Color(0xFFB8304C);

  static AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Punto único de entrada: al arrancar y cada vez que la app vuelve a
  /// primer plano. 1) anota como "ya avisados" los avisos programados que
  /// sonaron con la app cerrada, 2) revisa lo pendiente (y envía correos),
  /// 3) deja programados los próximos avisos.
  static Future<void> sincronizar(AppDatabase db) async {
    await conciliarProgramados(db);
    await revisarRecordatorios(db);
    await replanificar(db);
  }

  /// Un aviso programado suena sin que la app se entere. Aquí se revisa la
  /// lista guardada de lo que se programó: todo lo que ya pasó de hora se
  /// da por avisado, para que la revisión al abrir no lo repita.
  @visibleForTesting
  static Future<void> conciliarProgramados(
    AppDatabase db, {
    DateTime? ahora,
  }) async {
    if (!programacionSoportada) return;
    final prefs = await SharedPreferences.getInstance();
    final guardados = prefs.getStringList(_kProgramados) ?? const [];
    if (guardados.isEmpty) return;
    final ahoraMs = (ahora ?? DateTime.now()).millisecondsSinceEpoch;

    final pendientes = <String>[];
    final ultimoPorRecordatorio = <int, int>{};
    for (final linea in guardados) {
      final partes = linea.split('|');
      final cuandoMs = partes.length == 2 ? int.tryParse(partes[0]) : null;
      final recordatorioId = partes.length == 2
          ? int.tryParse(partes[1])
          : null;
      if (cuandoMs == null || recordatorioId == null) continue;
      if (cuandoMs > ahoraMs) {
        pendientes.add(linea);
      } else if (cuandoMs > (ultimoPorRecordatorio[recordatorioId] ?? 0)) {
        ultimoPorRecordatorio[recordatorioId] = cuandoMs;
      }
    }

    for (final e in ultimoPorRecordatorio.entries) {
      final r = await db.recordatoriosDao.getRecordatorioById(e.key);
      if (r == null) continue;
      final cuando = DateTime.fromMillisecondsSinceEpoch(e.value);
      final previa = r.ultimaNotificacion;
      if (previa == null || previa.isBefore(cuando)) {
        await db.recordatoriosDao.marcarNotificado(r.id, cuando);
      }
    }
    await prefs.setStringList(_kProgramados, pendientes);
  }

  static bool _replanificando = false;
  static bool _replanPendiente = false;

  /// Borra lo que estaba programado y lo vuelve a programar desde cero según
  /// el estado actual de los recordatorios. Se llama al abrir/volver a la
  /// app y cada vez que cambia la tabla de recordatorios (ver
  /// [observarCambios]).
  static Future<void> replanificar(AppDatabase db) async {
    if (!programacionSoportada) return;
    if (_replanificando) {
      // Llegó un cambio mientras se planeaba: se repite una vez al terminar
      // para no quedar con un plan viejo.
      _replanPendiente = true;
      return;
    }
    _replanificando = true;
    try {
      do {
        _replanPendiente = false;
        await _replanificar(db);
      } while (_replanPendiente);
    } catch (e) {
      debugPrint('NotificationService: fallo al programar avisos: $e');
    } finally {
      _replanificando = false;
    }
  }

  static Future<void> _replanificar(AppDatabase db) async {
    await init();
    final prefs = await SharedPreferences.getInstance();

    final pendientes = await _plugin.pendingNotificationRequests();
    for (final p in pendientes) {
      if (p.id >= _idRecordatorioDiario) await _plugin.cancel(id: p.id);
    }

    final lista = await db.recordatoriosDao.getRecordatoriosActivos();
    final refs = await _cargarReferencias(db, lista);
    final plan = NotificationPlanner.planear(
      recordatorios: lista,
      ahora: DateTime.now(),
      cuerpo: (r, dias) => _buildContenido(
        r,
        refs.deudas,
        refs.prestamos,
        refs.gastos,
        dias,
      ).sistema,
    );

    final modo = await _modoProgramacion(prefs);
    final guardados = <String>[];
    for (var i = 0; i < plan.length; i++) {
      final aviso = plan[i];
      final programado = await _programar(
        id: _idBaseProgramados + i,
        cuando: aviso.cuando,
        titulo: aviso.titulo,
        cuerpo: aviso.cuerpo,
        detalles: NotificationDetails(
          android: _detallesAndroidPara(aviso.cuerpo),
        ),
        modo: modo,
      );
      if (programado) {
        guardados.add(
          '${aviso.cuando.millisecondsSinceEpoch}|${aviso.recordatorioId}',
        );
      }
    }
    await prefs.setStringList(_kProgramados, guardados);

    if (prefs.getBool(_kDiario) ?? false) {
      final minutos =
          prefs.getInt(_kDiarioMinutos) ?? recordatorioDiarioPorDefecto;
      final ahora = DateTime.now();
      var cuando = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        minutos ~/ 60,
        minutos % 60,
      );
      if (!cuando.isAfter(ahora)) cuando = cuando.add(const Duration(days: 1));
      await _programar(
        id: _idRecordatorioDiario,
        cuando: cuando,
        titulo: '¿Ya anotaste tus gastos de hoy?',
        cuerpo: _cuerpoDiario,
        detalles: NotificationDetails(
          android: _detallesAndroidPara(_cuerpoDiario),
        ),
        modo: modo,
        repetirCadaDia: true,
      );
    }
  }

  /// La hora se le entrega a Android como instante absoluto (UTC): así no
  /// hace falta la base de datos de husos horarios ni otra dependencia. El
  /// plan se rehace cada vez que se abre la app, lo que corrige cualquier
  /// cambio de huso u horario de verano.
  static const _cuerpoDiario =
      'Te toma menos de un minuto registrarlos en Valtiq.';

  static Future<bool> _programar({
    required int id,
    required DateTime cuando,
    required String titulo,
    required String cuerpo,
    required NotificationDetails detalles,
    required AndroidScheduleMode modo,
    bool repetirCadaDia = false,
  }) async {
    Future<void> intentar(AndroidScheduleMode m) => _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(cuando, tz.UTC),
      notificationDetails: detalles,
      androidScheduleMode: m,
      title: titulo,
      body: cuerpo,
      matchDateTimeComponents: repetirCadaDia ? DateTimeComponents.time : null,
    );
    try {
      await intentar(modo);
      return true;
    } catch (e) {
      // Lo más común: el usuario retiró el permiso de alarmas exactas
      // después de activarlo. Se reintenta en modo aproximado, que no
      // necesita ningún permiso especial.
      if (modo == AndroidScheduleMode.inexactAllowWhileIdle) {
        debugPrint(
          'NotificationService: no se pudo programar el aviso $id: $e',
        );
        return false;
      }
      try {
        await intentar(AndroidScheduleMode.inexactAllowWhileIdle);
        return true;
      } catch (e2) {
        debugPrint(
          'NotificationService: no se pudo programar el aviso $id: $e2',
        );
        return false;
      }
    }
  }

  static Future<AndroidScheduleMode> _modoProgramacion(
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool(_kExactos) ?? false) {
      if (await _android?.canScheduleExactNotifications() ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static StreamSubscription<void>? _subCambios;
  static Timer? _debounceCambios;

  /// Vuelve a planear cada vez que cambia la tabla de recordatorios (crear,
  /// editar, borrar, o que una deuda pagada desactive los suyos). Un solo
  /// punto de enganche en vez de acordarse de llamar a [replanificar] desde
  /// cada pantalla.
  static void observarCambios(AppDatabase db) {
    if (!programacionSoportada || _subCambios != null) return;
    _subCambios = db
        .tableUpdates(TableUpdateQuery.onTable(db.recordatorios))
        .listen((_) {
          _debounceCambios?.cancel();
          _debounceCambios = Timer(
            const Duration(milliseconds: 600),
            () => unawaited(replanificar(db)),
          );
        });
  }

  static Future<void> dejarDeObservarCambios() async {
    _debounceCambios?.cancel();
    _debounceCambios = null;
    await _subCambios?.cancel();
    _subCambios = null;
  }

  // ── Ajustes (pantalla Configuración → Notificaciones) ──

  /// `null` si la plataforma no permite saberlo.
  static Future<bool?> notificacionesPermitidas() async {
    if (!programacionSoportada) return null;
    await init();
    return _android?.areNotificationsEnabled();
  }

  static Future<bool> avisosExactosActivados() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kExactos) ?? false)) return false;
    if (!programacionSoportada) return false;
    await init();
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  /// Activa/desactiva los avisos a la hora exacta. Al activar, Android 12+
  /// abre su pantalla "Alarmas y recordatorios" para que el usuario dé el
  /// permiso. Devuelve si quedaron activados de verdad.
  static Future<bool> setAvisosExactos(AppDatabase db, bool activar) async {
    final prefs = await SharedPreferences.getInstance();
    var concedido = false;
    if (activar && programacionSoportada) {
      await init();
      concedido = await _android?.canScheduleExactNotifications() ?? false;
      if (!concedido) {
        await _android?.requestExactAlarmsPermission();
        concedido = await _android?.canScheduleExactNotifications() ?? false;
      }
    }
    await prefs.setBool(_kExactos, activar && concedido);
    await replanificar(db);
    return activar && concedido;
  }

  static Future<({bool activo, int minutos})> recordatorioDiario() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      activo: prefs.getBool(_kDiario) ?? false,
      minutos: prefs.getInt(_kDiarioMinutos) ?? recordatorioDiarioPorDefecto,
    );
  }

  static Future<void> setRecordatorioDiario(
    AppDatabase db, {
    required bool activo,
    required int minutos,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDiario, activo);
    await prefs.setInt(_kDiarioMinutos, minutos);
    await replanificar(db);
  }

  /// Carga en lote las referencias (deuda/préstamo/gasto) de una lista de
  /// recordatorios, en vez de una consulta por recordatorio (evita N+1).
  static Future<
    ({
      Map<int, Deuda> deudas,
      Map<int, Prestamo> prestamos,
      Map<int, GastosFijo> gastos,
    })
  >
  _cargarReferencias(AppDatabase db, List<Recordatorio> lista) async {
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
    return (
      deudas: {
        for (final d in await db.deudasDao.getDeudasByIds(deudaIds)) d.id: d,
      },
      prestamos: {
        for (final p in await db.prestamosDao.getPrestamosByIds(prestamoIds))
          p.id: p,
      },
      gastos: {
        for (final g in await db.gastosFijosDao.getGastosFijosByIds(gastoIds))
          g.id: g,
      },
    );
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
        email: 'Recordatorio: ${r.titulo}\n\nEstado: $estado',
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
        email: 'Recordatorio: ${r.titulo}\n\nEstado: $estado',
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
        final sistema =
            '$estado · Pago a ${deuda.acreedorNombre} · '
            '${formatCOP(deuda.montoOriginal)}';

        final buf = StringBuffer()
          ..writeln('Recordatorio: ${r.titulo}')
          ..writeln()
          ..writeln('Monto original: $monto');
        if (deuda.fechaLimite != null) {
          buf.writeln(
            'Fecha límite: '
            '${formatFechaLegible(fechaCivilGuardada(deuda.fechaLimite!))}',
          );
        }
        buf.writeln('Estado: $estado');
        if (deuda.cuotaMensual != null) {
          buf.write('Cuota mensual: ${formatCOP(deuda.cuotaMensual!)} COP');
        }

        return (sistema: sistema, email: buf.toString().trimRight());

      case 'prestamo':
        final prestamo = prestamosPorId[id];
        if (prestamo == null) {
          const msg = 'Recordatorio vinculado a un préstamo ya eliminado.';
          return (sistema: msg, email: msg);
        }
        final monto = '${formatCOP(prestamo.montoPrestado)} COP';
        final sistema =
            '$estado · Cobro a ${prestamo.deudorNombre} · '
            '${formatCOP(prestamo.montoPrestado)}';

        final buf = StringBuffer()
          ..writeln('Recordatorio: ${r.titulo}')
          ..writeln()
          ..writeln('Monto prestado: $monto');
        if (prestamo.fechaPactadaPago != null) {
          buf.writeln(
            'Fecha pactada: '
            '${formatFechaLegible(fechaCivilGuardada(prestamo.fechaPactadaPago!))}',
          );
        }
        buf.writeln('Estado: $estado');
        if (prestamo.deudorContacto.isNotEmpty) {
          buf.write('Contacto: ${prestamo.deudorContacto}');
        }

        return (sistema: sistema, email: buf.toString().trimRight());

      case 'gasto':
        final gasto = gastosPorId[id];
        if (gasto == null) {
          const msg = 'Recordatorio vinculado a un gasto fijo ya eliminado.';
          return (sistema: msg, email: msg);
        }
        final monto = '${formatCOP(gasto.monto)} COP';
        final sistema =
            '$estado · ${gasto.concepto} · ${formatCOP(gasto.monto)}';

        final buf = StringBuffer()
          ..writeln('Recordatorio: ${r.titulo}')
          ..writeln()
          ..writeln('Monto: $monto')
          ..writeln('Frecuencia: ${gasto.frecuencia}')
          ..write('Estado: $estado');

        return (sistema: sistema, email: buf.toString());

      default:
        final estado0 = _bodyParaRecordatorio(diasFaltantes);
        return (
          sistema: estado0,
          email: 'Recordatorio: ${r.titulo}\n\nEstado: $estado0',
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
      debugPrint(
        'NotificationService: fallo al cancelar la notificación $id: $e',
      );
    }
  }
}
