import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:valtiq/db/database.dart';

/// Reconstruye a mano el esquema v11 (el que tiene la app publicada
/// actualmente: montos INTEGER, fechas de negocio ya normalizadas, sin
/// `tipo_amortizacion`) sobre una base sqlite en memoria, con `PRAGMA
/// user_version = 11`. Al abrirla con la `AppDatabase` real (schemaVersion
/// 12), drift dispara únicamente el bloque `if (from < 12)` de `onUpgrade`
/// — el camino que recorrerá cualquier usuario real actualizando desde la
/// versión publicada hoy.
sqlite3.Database _crearBaseV11() {
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

  // Fechas de negocio ya normalizadas a medianoche UTC (estado real de v11).
  final fechaPrestamo = DateTime.utc(2025, 6, 15).millisecondsSinceEpoch ~/
      1000;

  raw.execute(
    'INSERT INTO deudas '
    '(acreedor_nombre, monto_original, tasa_interes, tipo_interes, '
    'modalidad_calculo, fecha_prestamo, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    ['Banco Test', 2000000, 2.5, 'mensual', 'compuesto', fechaPrestamo, ahora, ahora],
  );
  raw.execute(
    'INSERT INTO prestamos '
    '(deudor_nombre, monto_prestado, tasa_interes, tipo_interes, '
    'modalidad_calculo, fecha_prestamo, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    ['Juan', 500000, 0, 'ninguno', 'simple', fechaPrestamo, ahora, ahora],
  );

  raw.execute('PRAGMA user_version = 11');
  return raw;
}

/// Reconstruye a mano el esquema v9 (montos monetarios como REAL, fechas de
/// negocio sin normalizar) — el caso de un usuario que saltea VARIAS
/// versiones de golpe (v9 → v12 directo, sin abrir la app en el medio).
/// Ejercita el camino donde `if (from >= 11)` de `database.dart` debe dar
/// `false`: la columna `tipoAmortizacion` tiene que llegar sola, gratis, por
/// el rebuild de `TableMigration` en los bloques `from < 10`/`from < 11` —
/// si `addColumn` se llamara también acá, tiraría "duplicate column name".
sqlite3.Database _crearBaseV9() {
  final raw = sqlite3.sqlite3.openInMemory();
  final ahora = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  raw.execute('''
    CREATE TABLE deudas (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      acreedor_nombre TEXT NOT NULL,
      monto_original REAL NOT NULL,
      tasa_interes REAL NOT NULL DEFAULT 0,
      tipo_interes TEXT NOT NULL DEFAULT 'ninguno',
      modalidad_calculo TEXT NOT NULL DEFAULT 'simple',
      fecha_prestamo INTEGER NOT NULL,
      fecha_limite INTEGER,
      cuota_mensual REAL,
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
      monto_prestado REAL NOT NULL,
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
      monto_abonado REAL NOT NULL,
      fecha_pago INTEGER NOT NULL,
      notas TEXT NOT NULL DEFAULT '',
      creado_en INTEGER NOT NULL
    );
  ''');
  raw.execute('''
    CREATE TABLE pagos_deuda (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      deuda_id INTEGER NOT NULL REFERENCES deudas(id),
      monto_abonado REAL NOT NULL,
      fecha_pago INTEGER NOT NULL,
      notas TEXT NOT NULL DEFAULT '',
      creado_en INTEGER NOT NULL
    );
  ''');
  raw.execute('''
    CREATE TABLE ingresos (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      concepto TEXT NOT NULL,
      monto REAL NOT NULL,
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
      monto REAL NOT NULL,
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
      monto REAL NOT NULL,
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
      limite_mensual REAL NOT NULL,
      creado_en INTEGER NOT NULL,
      actualizado_en INTEGER NOT NULL
    );
  ''');

  raw.execute(
    'INSERT INTO config_smtps (id, actualizado_en) VALUES (1, ?)',
    [ahora],
  );

  // Fecha de negocio SIN normalizar (hora arbitraria) — así era antes de v11.
  final fechaPrestamo = DateTime(2024, 5, 20, 17, 30).millisecondsSinceEpoch ~/
      1000;

  raw.execute(
    'INSERT INTO deudas '
    '(acreedor_nombre, monto_original, modalidad_calculo, fecha_prestamo, '
    'creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    ['Banco Test', 1999.6, 'compuesto', fechaPrestamo, ahora, ahora],
  );
  raw.execute(
    'INSERT INTO prestamos '
    '(deudor_nombre, monto_prestado, fecha_prestamo, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Juan', 2500.4, fechaPrestamo, ahora, ahora],
  );

  raw.execute('PRAGMA user_version = 9');
  return raw;
}

/// Reconstruye a mano el esquema v10 (montos ya INTEGER, fechas de negocio
/// todavía sin normalizar) — el otro caso de salto múltiple mencionado: v10
/// → v12 directo. Ejercita el mismo mecanismo que `_crearBaseV9` pero a
/// través del bloque `from < 11` en vez de `from < 10`.
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

  // Fecha de negocio SIN normalizar (hora arbitraria) — así era antes de v11.
  final fechaPrestamo = DateTime(2024, 8, 3, 9, 15).millisecondsSinceEpoch ~/
      1000;

  raw.execute(
    'INSERT INTO deudas '
    '(acreedor_nombre, monto_original, modalidad_calculo, fecha_prestamo, '
    'creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    ['Banco Test', 3000000, 'simple', fechaPrestamo, ahora, ahora],
  );
  raw.execute(
    'INSERT INTO prestamos '
    '(deudor_nombre, monto_prestado, fecha_prestamo, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Ana', 750000, fechaPrestamo, ahora, ahora],
  );

  raw.execute('PRAGMA user_version = 10');
  return raw;
}

void main() {
  test(
    'migración v11 → v12: deudas y préstamos existentes quedan en '
    "tipoAmortizacion='saldo_original' (el comportamiento que ya tenían "
    'antes de que existiera esta opción), sin duplicar la columna',
    () async {
      final raw = _crearBaseV11();
      final db = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final deuda = (await db.deudasDao.getAllDeudas()).single;
      expect(deuda.tipoAmortizacion, 'saldo_original');
      // Los demás campos no debieron alterarse por esta migración.
      expect(deuda.montoOriginal, 2000000);
      expect(deuda.modalidadCalculo, 'compuesto');

      final prestamo = (await db.prestamosDao.getAllPrestamos()).single;
      expect(prestamo.tipoAmortizacion, 'saldo_original');
      expect(prestamo.montoPrestado, 500000);
    },
  );

  test(
    'migración de SALTO MÚLTIPLE v9 → v12 (sin pasar por v10/v11 por '
    'separado): no lanza "duplicate column name" — tipoAmortizacion llega '
    'gratis por el rebuild de TableMigration en from<10/from<11, así que '
    "el addColumn explícito de from<12 (guardado tras `if (from >= 11)`) "
    'debe SALTARSE, no duplicar la columna',
    () async {
      final raw = _crearBaseV9();
      final db = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final deuda = (await db.deudasDao.getAllDeudas()).single;
      expect(deuda.tipoAmortizacion, 'saldo_original');
      // Confirma que las migraciones intermedias (v9→v10 montos a INTEGER,
      // v10→v11 fechas a UTC-civil) también corrieron completas dentro de
      // este mismo salto, no solo la última.
      expect(deuda.montoOriginal, 2000); // 1999.6 → redondeado (v9→v10)
      expect(deuda.modalidadCalculo, 'compuesto');

      final prestamo = (await db.prestamosDao.getAllPrestamos()).single;
      expect(prestamo.tipoAmortizacion, 'saldo_original');
      expect(prestamo.montoPrestado, 2500); // 2500.4 → redondeado (v9→v10)
    },
  );

  test(
    'migración de SALTO MÚLTIPLE v10 → v12: mismo mecanismo que v9→v12 pero '
    'a través del bloque from<11 en vez de from<10',
    () async {
      final raw = _crearBaseV10();
      final db = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final deuda = (await db.deudasDao.getAllDeudas()).single;
      expect(deuda.tipoAmortizacion, 'saldo_original');
      expect(deuda.montoOriginal, 3000000);
      expect(deuda.modalidadCalculo, 'simple');

      final prestamo = (await db.prestamosDao.getAllPrestamos()).single;
      expect(prestamo.tipoAmortizacion, 'saldo_original');
      expect(prestamo.montoPrestado, 750000);
    },
  );
}
