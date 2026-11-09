import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test(
    'recordatorio nuevo (sin notificación previa) dentro de ventana: se '
    'notifica y queda marcado con la fecha de hoy',
    () async {
      final id = await insertarRecordatorio(db, fechaAlerta: hoy);

      final notificados = await NotificationService.revisarRecordatorios(db);

      expect(notificados, 1);
      final actualizado = await recargar(db, id);
      expect(actualizado.ultimaNotificacion, isNotNull);
    },
  );

  test(
    "frecuencia 'unica' con notificación ya enviada: nunca se repite, "
    'aunque siga dentro de ventana',
    () async {
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
    },
  );

  test(
    "frecuencia 'diaria' con notificación ya enviada HOY: no se repite el "
    'mismo día',
    () async {
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
    },
  );

  test(
    "frecuencia 'diaria' con notificación de AYER: sí se repite hoy, y "
    'queda marcado con la fecha de hoy',
    () async {
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
    },
  );

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
}
