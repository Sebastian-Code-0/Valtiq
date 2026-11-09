import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:valtiq/db/database.dart';

/// Reconstruye a mano el esquema v10 (montos ya INTEGER, fechas de negocio
/// todavía con hora de día arbitraria — el estado justo antes de esta
/// migración) sobre una base sqlite en memoria, con `PRAGMA user_version =
/// 10`. Al abrirla con la `AppDatabase` real (schemaVersion 11), drift
/// dispara únicamente el bloque `if (from < 11)` de `onUpgrade` — el mismo
/// camino que recorrerá la base de datos real de un usuario que actualice
/// desde una versión anterior.
///
/// Las fechas se insertan con hora de día distinta de medianoche (23:47,
/// construidas en la zona horaria LOCAL del proceso que corre el test) para
/// verificar que la migración recupera el día civil correcto sin importar
/// en qué huso horario corra — el valor "esperado" se calcula con la misma
/// lógica de extracción local, así que el test no asume ningún huso fijo.
sqlite3.Database _crearBaseV10() {
  final raw = sqlite3.sqlite3.openInMemory();
  final ahora = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  raw.execute('''
    CREATE TABLE deudas (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      acreedor_nombre TEXT NOT NULL,
      monto_original INTEGER NOT NULL,
      tasa_interes REAL NOT NULL DEFAULT 0,
      tipo_interes TEXT NOT NULL DEFAULT 'ninguno',
      modalidad_calculo TEXT NOT NULL DEFAULT 'simple',
      fecha_prestamo INTEGER NOT NULL,
      fecha_limite INTEGER,
      cuota_mensual INTEGER,
      notas TEXT NOT NULL DEFAULT '',
      estado TEXT NOT NULL DEFAULT 'activa',
      fecha_pago_real INTEGER,
      creado_en INTEGER NOT NULL,
      actualizado_en INTEGER NOT NULL
    );
  ''');
  raw.execute('''
    CREATE TABLE prestamos (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      deudor_nombre TEXT NOT NULL,
      deudor_contacto TEXT NOT NULL DEFAULT '',
      monto_prestado INTEGER NOT NULL,
      tasa_interes REAL NOT NULL DEFAULT 0,
      tipo_interes TEXT NOT NULL DEFAULT 'ninguno',
      modalidad_calculo TEXT NOT NULL DEFAULT 'simple',
      fecha_prestamo INTEGER NOT NULL,
      fecha_pactada_pago INTEGER,
      estado TEXT NOT NULL DEFAULT 'activo',
      notas TEXT NOT NULL DEFAULT '',
      creado_en INTEGER NOT NULL,
      actualizado_en INTEGER NOT NULL
    );
  ''');
  raw.execute('''
    CREATE TABLE pagos_recibidos (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      prestamo_id INTEGER NOT NULL REFERENCES prestamos(id),
      monto_abonado INTEGER NOT NULL,
      fecha_pago INTEGER NOT NULL,
      notas TEXT NOT NULL DEFAULT '',
      creado_en INTEGER NOT NULL
    );
  ''');
  raw.execute('''
    CREATE TABLE pagos_deuda (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      deuda_id INTEGER NOT NULL REFERENCES deudas(id),
      monto_abonado INTEGER NOT NULL,
      fecha_pago INTEGER NOT NULL,
      notas TEXT NOT NULL DEFAULT '',
      creado_en INTEGER NOT NULL
    );
  ''');
  raw.execute('''
    CREATE TABLE ingresos (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      concepto TEXT NOT NULL,
      monto INTEGER NOT NULL,
      frecuencia TEXT NOT NULL DEFAULT 'mensual',
      fecha INTEGER NOT NULL,
      notas TEXT NOT NULL DEFAULT '',
      activo INTEGER NOT NULL DEFAULT 1,
      creado_en INTEGER NOT NULL,
      actualizado_en INTEGER NOT NULL
    );
  ''');
  raw.execute('''
    CREATE TABLE gastos_fijos (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      concepto TEXT NOT NULL,
      monto INTEGER NOT NULL,
      frecuencia TEXT NOT NULL DEFAULT 'mensual',
      dia_cobro INTEGER,
      notas TEXT NOT NULL DEFAULT '',
      activo INTEGER NOT NULL DEFAULT 1,
      creado_en INTEGER NOT NULL,
      actualizado_en INTEGER NOT NULL
    );
  ''');
  raw.execute('''
    CREATE TABLE recordatorios (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      titulo TEXT NOT NULL,
      referencia_tabla TEXT,
      referencia_id INTEGER,
      fecha_alerta INTEGER NOT NULL,
      dias_anticipacion INTEGER NOT NULL DEFAULT 3,
      tipo_notificacion TEXT NOT NULL DEFAULT 'sistema',
      repetir INTEGER NOT NULL DEFAULT 0,
      activo INTEGER NOT NULL DEFAULT 1,
      creado_en INTEGER NOT NULL,
      frecuencia_aviso TEXT NOT NULL DEFAULT 'unica',
      ultima_notificacion INTEGER,
      ultimo_envio_correo INTEGER,
      hora_aviso INTEGER NOT NULL DEFAULT 12,
      minuto_aviso INTEGER NOT NULL DEFAULT 0
    );
  ''');
  raw.execute('''
    CREATE TABLE config_smtps (
      id INTEGER NOT NULL DEFAULT 1 PRIMARY KEY,
      servidor TEXT NOT NULL DEFAULT '',
      puerto INTEGER NOT NULL DEFAULT 587,
      usuario TEXT NOT NULL DEFAULT '',
      contrasena_encriptada TEXT,
      tiene_contrasena INTEGER NOT NULL DEFAULT 0,
      correo_destino TEXT NOT NULL DEFAULT '',
      nombre_remitente TEXT NOT NULL DEFAULT 'Valtiq',
      ssl INTEGER NOT NULL DEFAULT 0,
      habilitado INTEGER NOT NULL DEFAULT 0,
      actualizado_en INTEGER NOT NULL
    );
  ''');
  raw.execute('''
    CREATE TABLE gastos_variables (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      descripcion TEXT NOT NULL,
      monto INTEGER NOT NULL,
      categoria TEXT NOT NULL,
      fecha INTEGER NOT NULL,
      notas TEXT,
      creado_en INTEGER NOT NULL
    );
  ''');
  raw.execute('''
    CREATE TABLE presupuestos_categorias (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      categoria TEXT NOT NULL UNIQUE,
      limite_mensual INTEGER NOT NULL,
      creado_en INTEGER NOT NULL,
      actualizado_en INTEGER NOT NULL
    );
  ''');

  raw.execute(
    'INSERT INTO config_smtps (id, actualizado_en) VALUES (1, ?)',
    [ahora],
  );

  // Fechas de negocio con hora de día arbitraria (23:47 local) — el estado
  // "sucio" que la migración debe normalizar a medianoche UTC de ese mismo
  // día civil. creadoEn/actualizadoEn quedan como instantes reales (ahora).
  final fechaPrestamoDeuda = DateTime(2025, 6, 15, 23, 47);
  final fechaLimiteDeuda = DateTime(2025, 7, 1, 8, 5);
  final fechaPagoRealDeuda = DateTime(2025, 6, 30, 14, 30);
  final fechaPrestamoPrestamo = DateTime(2025, 3, 10, 6, 15);
  final fechaPactadaPrestamo = DateTime(2025, 4, 10, 23, 59);
  final fechaPagoDeuda = DateTime(2025, 6, 20, 22, 0);
  final fechaPagoRecibido = DateTime(2025, 3, 25, 1, 30);
  final fechaIngreso = DateTime(2025, 1, 5, 23, 15);
  final fechaGastoVariable = DateTime(2025, 2, 14, 0, 10);
  final fechaAlerta = DateTime(2025, 8, 1, 23, 30);

  int epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  raw.execute(
    'INSERT INTO deudas '
    '(acreedor_nombre, monto_original, fecha_prestamo, fecha_limite, '
    'fecha_pago_real, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    [
      'Banco Test',
      2000,
      epoch(fechaPrestamoDeuda),
      epoch(fechaLimiteDeuda),
      epoch(fechaPagoRealDeuda),
      ahora,
      ahora,
    ],
  );
  raw.execute(
    'INSERT INTO prestamos '
    '(deudor_nombre, monto_prestado, fecha_prestamo, fecha_pactada_pago, '
    'creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [
      'Juan',
      2500,
      epoch(fechaPrestamoPrestamo),
      epoch(fechaPactadaPrestamo),
      ahora,
      ahora,
    ],
  );
  raw.execute(
    'INSERT INTO pagos_deuda (deuda_id, monto_abonado, fecha_pago, creado_en) '
    'VALUES (1, ?, ?, ?)',
    [1000, epoch(fechaPagoDeuda), ahora],
  );
  raw.execute(
    'INSERT INTO pagos_recibidos '
    '(prestamo_id, monto_abonado, fecha_pago, creado_en) '
    'VALUES (1, ?, ?, ?)',
    [1201, epoch(fechaPagoRecibido), ahora],
  );
  raw.execute(
    'INSERT INTO ingresos (concepto, monto, fecha, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Salario', 1500000, epoch(fechaIngreso), ahora, ahora],
  );
  raw.execute(
    'INSERT INTO gastos_variables '
    '(descripcion, monto, categoria, fecha, creado_en) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Mercado', 46000, 'alimentacion', epoch(fechaGastoVariable), ahora],
  );
  raw.execute(
    'INSERT INTO recordatorios (titulo, fecha_alerta, creado_en) '
    'VALUES (?, ?, ?)',
    ['Pago tarjeta', epoch(fechaAlerta), ahora],
  );

  raw.execute('PRAGMA user_version = 10');
  return raw;
}

/// El día civil que un DateTime local representa, calculado con la misma
/// extracción que hará la migración real (interpretar el instante en la
/// zona local actual). No asume ningún huso fijo.
DateTime diaCivilEsperado(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day);

/// DateTime.== también compara el flag isUtc, no solo el instante — drift
/// reconstruye las fechas leídas como locales aunque representen medianoche
/// UTC, así que comparar con `expect(a, b)` (que usa ==) da falso negativo
/// aunque sea exactamente el mismo instante. isAtSameMomentAs es la
/// comparación correcta aquí.
void expectMismoInstante(DateTime actual, DateTime esperado) {
  expect(
    actual.isAtSameMomentAs(esperado),
    isTrue,
    reason: 'Esperado el mismo instante que $esperado, pero fue $actual',
  );
}

void main() {
  test(
    'migración v10 → v11: fechas de negocio se normalizan a medianoche UTC '
    'de su día civil; los timestamps de auditoría no se tocan',
    () async {
      final fechaPrestamoDeuda = DateTime(2025, 6, 15, 23, 47);
      final fechaLimiteDeuda = DateTime(2025, 7, 1, 8, 5);
      final fechaPagoRealDeuda = DateTime(2025, 6, 30, 14, 30);
      final fechaPrestamoPrestamo = DateTime(2025, 3, 10, 6, 15);
      final fechaPactadaPrestamo = DateTime(2025, 4, 10, 23, 59);
      final fechaPagoDeuda = DateTime(2025, 6, 20, 22, 0);
      final fechaPagoRecibido = DateTime(2025, 3, 25, 1, 30);
      final fechaIngreso = DateTime(2025, 1, 5, 23, 15);
      final fechaGastoVariable = DateTime(2025, 2, 14, 0, 10);
      final fechaAlerta = DateTime(2025, 8, 1, 23, 30);

      final raw = _crearBaseV10();
      final db = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final creadoEnAntes = DateTime.now();

      final deuda = (await db.deudasDao.getAllDeudas()).single;
      expectMismoInstante(
        deuda.fechaPrestamo,
        diaCivilEsperado(fechaPrestamoDeuda),
      );
      expectMismoInstante(
        deuda.fechaLimite!,
        diaCivilEsperado(fechaLimiteDeuda),
      );
      expectMismoInstante(
        deuda.fechaPagoReal!,
        diaCivilEsperado(fechaPagoRealDeuda),
      );
      // creadoEn/actualizadoEn NO se normalizan: siguen siendo instantes
      // reales (no medianoche), solo verificamos que no quedaron en 00:00.
      expect(deuda.creadoEn.hour == 0 && deuda.creadoEn.minute == 0, isFalse);

      final prestamo = (await db.prestamosDao.getAllPrestamos()).single;
      expectMismoInstante(
        prestamo.fechaPrestamo,
        diaCivilEsperado(fechaPrestamoPrestamo),
      );
      expectMismoInstante(
        prestamo.fechaPactadaPago!,
        diaCivilEsperado(fechaPactadaPrestamo),
      );

      final pagoDeuda = (await db.pagosDeudaDao.getAllPagos()).single;
      expectMismoInstante(
        pagoDeuda.fechaPago,
        diaCivilEsperado(fechaPagoDeuda),
      );

      final pagoRecibido = (await db.prestamosDao.getAllPagosRecibidos())
          .single;
      expectMismoInstante(
        pagoRecibido.fechaPago,
        diaCivilEsperado(fechaPagoRecibido),
      );

      final ingreso = (await db.ingresosDao.getAllIngresos()).single;
      expectMismoInstante(ingreso.fecha, diaCivilEsperado(fechaIngreso));

      final gastoVariable = (await db.gastosVariablesDao
              .getAllGastosVariables())
          .single;
      expectMismoInstante(
        gastoVariable.fecha,
        diaCivilEsperado(fechaGastoVariable),
      );

      final recordatorio = (await db.recordatoriosDao.getAllRecordatorios())
          .single;
      expectMismoInstante(
        recordatorio.fechaAlerta,
        diaCivilEsperado(fechaAlerta),
      );
      // El recordatorio se insertó sin ultimaNotificacion/ultimoEnvioCorreo
      // (quedan NULL) — confirma que la migración no falla ni los inventa.
      expect(recordatorio.ultimaNotificacion, isNull);
      expect(recordatorio.ultimoEnvioCorreo, isNull);

      // El instante de creación no debió alterarse por la migración: sigue
      // siendo (aprox.) el momento real en que se insertó, no medianoche.
      expect(
        deuda.creadoEn.difference(creadoEnAntes).abs() <
            const Duration(minutes: 1),
        isTrue,
      );
    },
  );
}
