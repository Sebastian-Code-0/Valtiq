import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/notification_service.dart';
import 'package:valtiq/utils/fecha_civil.dart';

/// `NotificationService.init()` intenta resolver una implementación
/// específica de plataforma (`LinuxFlutterLocalNotificationsPlugin` en este
/// entorno) para `FlutterLocalNotificationsPlatform.instance`. En un
/// `flutter test` puro no hay ningún plugin real registrado (eso solo pasa
/// en la app de verdad, vía el registrant generado) — sin fijar `instance` a
/// algo, la primera llamada tira `LateInitializationError`. Este fake
/// satisface el requisito sin implementar ningún método real: como no es
/// una instancia de `LinuxFlutterLocalNotificationsPlugin`,
/// `resolvePlatformSpecificImplementation` devuelve `null` y el plugin
/// principal simplemente no hace nada (`?.initialize(...)`/`?.show(...)` se
/// saltan solos) — exactamente el comportamiento que se quiere en un test de
/// la lógica de deduplicación, que no debe disparar ninguna notificación
/// real.
class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Alinea `defaultTargetPlatform` (que usa el plugin internamente) con el
  // host real (Linux) — sin esto, `flutter test` por defecto reporta
  // `TargetPlatform.android`, y `NotificationService.init()` termina
  // construyendo `LinuxInitializationSettings` (por `Platform.isLinux` de
  // `dart:io`, que sí ve el host real) mientras el plugin exige
  // `AndroidInitializationSettings` (por `defaultTargetPlatform`) — un
  // desajuste que solo existe en este entorno de test, no en la app real.
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();

  Future<int> insertarRecordatorio(
    AppDatabase db, {
    required DateTime fechaAlerta,
    String frecuenciaAviso = 'unica',
    DateTime? ultimaNotificacion,
    int diasAnticipacion = 3,
  }) {
    return db.recordatoriosDao.insertRecordatorio(
      RecordatoriosCompanion.insert(
        titulo: 'Pago tarjeta',
        fechaAlerta: fechaAlerta,
        diasAnticipacion: Value(diasAnticipacion),
        tipoNotificacion: const Value('sistema'),
        frecuenciaAviso: Value(frecuenciaAviso),
        ultimaNotificacion: Value(ultimaNotificacion),
      ),
    );
  }

  Future<Recordatorio> recargar(AppDatabase db, int id) async {
    final lista = await db.recordatoriosDao.getRecordatoriosActivos();
    return lista.singleWhere((r) => r.id == id);
  }

  late AppDatabase db;
  late DateTime hoy;
  late DateTime ayer;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final ahora = DateTime.now();
    hoy = normalizarFechaCivil(ahora);
    ayer = hoy.subtract(const Duration(days: 1));
  });

  tearDown(() => db.close());

  test('recordatorio nuevo (sin notificación previa) dentro de ventana: se '
      'notifica y queda marcado con la fecha de hoy', () async {
    final id = await insertarRecordatorio(db, fechaAlerta: hoy);

    final notificados = await NotificationService.revisarRecordatorios(db);

    expect(notificados, 1);
    final actualizado = await recargar(db, id);
    expect(actualizado.ultimaNotificacion, isNotNull);
  });

  test("frecuencia 'unica' con notificación ya enviada: nunca se repite, "
      'aunque siga dentro de ventana', () async {
    final id = await insertarRecordatorio(
      db,
      fechaAlerta: hoy,
      frecuenciaAviso: 'unica',
      ultimaNotificacion: ayer,
    );

    final notificados = await NotificationService.revisarRecordatorios(db);

    expect(notificados, 0);
    final actualizado = await recargar(db, id);
    expect(
      actualizado.ultimaNotificacion!.isAtSameMomentAs(ayer),
      isTrue,
      reason: 'No debió tocarse: unica ya se avisó una vez',
    );
  });

  test("frecuencia 'diaria' con notificación ya enviada HOY: no se repite el "
      'mismo día', () async {
    // Truncado a segundos: las columnas DateTime de drift se guardan como
    // epoch en segundos, así que comparar con isAtSameMomentAs contra un
    // DateTime.now() con milisegundos daría un falso negativo tras el
    // round-trip por la base, aunque la deduplicación en sí sea correcta.
    final avisadoHoyMasTarde = DateTime.fromMillisecondsSinceEpoch(
      (DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000,
    );
    final id = await insertarRecordatorio(
      db,
      fechaAlerta: hoy,
      frecuenciaAviso: 'diaria',
      ultimaNotificacion: avisadoHoyMasTarde,
    );

    final notificados = await NotificationService.revisarRecordatorios(db);

    expect(notificados, 0);
    final actualizado = await recargar(db, id);
    expect(
      actualizado.ultimaNotificacion!.isAtSameMomentAs(avisadoHoyMasTarde),
      isTrue,
    );
  });

  test("frecuencia 'diaria' con notificación de AYER: sí se repite hoy, y "
      'queda marcado con la fecha de hoy', () async {
    final id = await insertarRecordatorio(
      db,
      fechaAlerta: hoy,
      frecuenciaAviso: 'diaria',
      ultimaNotificacion: ayer,
    );

    final notificados = await NotificationService.revisarRecordatorios(db);

    expect(notificados, 1);
    final actualizado = await recargar(db, id);
    expect(
      actualizado.ultimaNotificacion!.isAtSameMomentAs(ayer),
      isFalse,
      reason: 'Debió actualizarse a hoy, no seguir en ayer',
    );
  });

  test(
    'recordatorio fuera de ventana (fechaAlerta muy en el futuro): no se '
    'notifica sin importar la frecuencia ni si nunca se avisó antes',
    () async {
      final lejos = hoy.add(const Duration(days: 30));
      final id = await insertarRecordatorio(
        db,
        fechaAlerta: lejos,
        diasAnticipacion: 3,
      );

      final notificados = await NotificationService.revisarRecordatorios(db);

      expect(notificados, 0);
      final actualizado = await recargar(db, id);
      expect(actualizado.ultimaNotificacion, isNull);
    },
  );

  test('recordatorio mensual de día 31 ya vencido: se reprograma al ÚLTIMO día '
      'de un mes (31, 30 o 28/29), nunca se desborda al mes siguiente — antes '
      '31 ene + 1 mes daba 3 mar y se quedaba en día 3 para siempre', () async {
    // El 31 de enero más reciente que ya esté fuera de la ventana de
    // gracia de 7 días.
    var original = DateTime.utc(hoy.year, 1, 31);
    if (hoy.difference(original).inDays <= 7) {
      original = DateTime.utc(hoy.year - 1, 1, 31);
    }
    final id = await db.recordatoriosDao.insertRecordatorio(
      RecordatoriosCompanion.insert(
        titulo: 'Arriendo',
        fechaAlerta: original,
        repetir: const Value(true),
      ),
    );

    await NotificationService.revisarRecordatorios(db);

    final nueva = fechaCivilGuardada((await recargar(db, id)).fechaAlerta);
    final ultimoDiaDelMes = DateTime.utc(nueva.year, nueva.month + 1, 0).day;
    expect(nueva.day, ultimoDiaDelMes);
    expect(nueva.difference(hoy).inDays, greaterThanOrEqualTo(-7));
    expect(nueva.difference(hoy).inDays, lessThan(31));
  });

  test('recordatorio mensual que el usuario puso el 31 y quedó en un día 28 '
      '(pasó por febrero): con diaOriginal vuelve al 31 (o al último día del '
      'mes) en vez de quedarse en 28 para siempre', () async {
    // Un 28 de febrero ya fuera de la ventana de gracia.
    var guardada = DateTime.utc(hoy.year, 2, 28);
    if (hoy.difference(guardada).inDays <= 7) {
      guardada = DateTime.utc(hoy.year - 1, 2, 28);
    }
    final id = await db.recordatoriosDao.insertRecordatorio(
      RecordatoriosCompanion.insert(
        titulo: 'Arriendo',
        fechaAlerta: guardada,
        repetir: const Value(true),
        diaOriginal: const Value(31),
      ),
    );

    await NotificationService.revisarRecordatorios(db);

    final nueva = fechaCivilGuardada((await recargar(db, id)).fechaAlerta);
    final ultimoDiaDelMes = DateTime.utc(nueva.year, nueva.month + 1, 0).day;
    expect(nueva.day, ultimoDiaDelMes);
    expect(nueva.difference(hoy).inDays, greaterThanOrEqualTo(-7));
  });

  test('sumarMesesConDia: usa el día pedido o el último del mes', () {
    final feb = DateTime.utc(2027, 2, 28);
    expect(sumarMesesConDia(feb, 1, 31), DateTime.utc(2027, 3, 31));
    expect(sumarMesesConDia(feb, 2, 31), DateTime.utc(2027, 4, 30));
    expect(sumarMesesConDia(feb, 1, 15), DateTime.utc(2027, 3, 15));
    expect(
      sumarMesesConDia(DateTime.utc(2027, 12, 31), 2, 31),
      DateTime.utc(2028, 2, 29),
    );
  });

  group('avisos programados (Android)', () {
    setUp(() => NotificationService.programacionSoportadaOverride = true);
    tearDown(() => NotificationService.programacionSoportadaOverride = null);

    test('un aviso programado que ya sonó con la app cerrada se anota como '
        'avisado, y al abrir la app NO se repite', () async {
      final id = await insertarRecordatorio(db, fechaAlerta: hoy);
      final hace1h = DateTime.now().subtract(const Duration(hours: 1));
      final en1h = DateTime.now().add(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        'valtiq_avisos_programados': [
          '${hace1h.millisecondsSinceEpoch}|$id',
          '${en1h.millisecondsSinceEpoch}|$id',
        ],
      });

      await NotificationService.conciliarProgramados(db);

      expect((await recargar(db, id)).ultimaNotificacion, isNotNull);
      // El que aún no suena sigue en la lista de pendientes.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('valtiq_avisos_programados'), [
        '${en1h.millisecondsSinceEpoch}|$id',
      ]);
      expect(await NotificationService.revisarRecordatorios(db), 0);
    });

    test(
      'un aviso programado de un recordatorio que ya se borró no rompe nada',
      () async {
        SharedPreferences.setMockInitialValues({
          'valtiq_avisos_programados': ['1000|9999', 'basura'],
        });

        await NotificationService.conciliarProgramados(db);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList('valtiq_avisos_programados'), isEmpty);
      },
    );

    test(
      'al abrir la app ANTES de la hora elegida no se avisa por adelantado '
      '(ese aviso ya está programado para su hora)',
      () async {
        final id = await db.recordatoriosDao.insertRecordatorio(
          RecordatoriosCompanion.insert(
            titulo: 'Pago tarjeta',
            fechaAlerta: hoy,
            horaAviso: const Value(23),
            minutoAviso: const Value(59),
          ),
        );

        final notificados = await NotificationService.revisarRecordatorios(db);

        expect(notificados, 0);
        expect((await recargar(db, id)).ultimaNotificacion, isNull);
      },
      // A las 23:59 exactas la hora ya está cumplida y el aviso sí sale.
      skip: DateTime.now().hour == 23 && DateTime.now().minute == 59,
    );

    test('al abrir la app DESPUÉS de la hora, lo que no sonó se avisa de '
        'inmediato', () async {
      final id = await db.recordatoriosDao.insertRecordatorio(
        RecordatoriosCompanion.insert(
          titulo: 'Pago tarjeta',
          fechaAlerta: hoy,
          horaAviso: const Value(0),
          minutoAviso: const Value(0),
        ),
      );

      expect(await NotificationService.revisarRecordatorios(db), 1);
      expect((await recargar(db, id)).ultimaNotificacion, isNotNull);
    });
  });
}
