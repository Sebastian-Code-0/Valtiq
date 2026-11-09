import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:valtiq/db/database.dart';

/// Reconstruye a mano el esquema v9 (montos monetarios como REAL) sobre una
/// base sqlite en memoria, con `PRAGMA user_version = 9`. Al abrirla con la
/// `AppDatabase` real (schemaVersion 10), drift dispara únicamente el bloque
/// `if (from < 10)` de `onUpgrade` — el mismo camino que recorrerá la base de
/// datos real de un usuario que actualice desde una versión anterior.
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

  raw.execute(
    'INSERT INTO deudas '
    '(acreedor_nombre, monto_original, cuota_mensual, fecha_prestamo, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    ['Banco Test', 1999.6, 250.4, ahora, ahora, ahora],
  );
  raw.execute(
    'INSERT INTO prestamos '
    '(deudor_nombre, monto_prestado, fecha_prestamo, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Juan', 2500.4, ahora, ahora, ahora],
  );
  raw.execute(
    'INSERT INTO pagos_deuda (deuda_id, monto_abonado, fecha_pago, creado_en) '
    'VALUES (1, ?, ?, ?)',
    [999.5, ahora, ahora],
  );
  raw.execute(
    'INSERT INTO pagos_recibidos (prestamo_id, monto_abonado, fecha_pago, creado_en) '
    'VALUES (1, ?, ?, ?)',
    [1200.5, ahora, ahora],
  );
  raw.execute(
    'INSERT INTO ingresos (concepto, monto, fecha, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Salario', 1500000.5, ahora, ahora, ahora],
  );
  raw.execute(
    'INSERT INTO gastos_fijos (concepto, monto, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?)',
    ['Arriendo', 800000.4, ahora, ahora],
  );
  raw.execute(
    'INSERT INTO gastos_variables (descripcion, monto, categoria, fecha, creado_en) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Mercado', 45999.6, 'alimentacion', ahora, ahora],
  );
  raw.execute(
    'INSERT INTO presupuestos_categorias (categoria, limite_mensual, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?)',
    ['alimentacion', 300000.4, ahora, ahora],
  );

  raw.execute('PRAGMA user_version = 9');
  return raw;
}

void main() {
  test(
    'migración v9 → v10: montos REAL existentes se redondean a INTEGER',
    () async {
      final raw = _crearBaseV9();
      final db = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final deuda = (await db.deudasDao.getAllDeudas()).single;
      expect(deuda.montoOriginal, 2000); // 1999.6 → redondeado
      expect(deuda.cuotaMensual, 250); // 250.4 → redondeado

      final prestamo = (await db.prestamosDao.getAllPrestamos()).single;
      expect(prestamo.montoPrestado, 2500); // 2500.4 → redondeado

      final pagoDeuda = (await db.pagosDeudaDao.getAllPagos()).single;
      expect(pagoDeuda.montoAbonado, 1000); // 999.5 → redondeado (round half up)

      final pagoRecibido = (await db.prestamosDao
              .getAllPagosRecibidos())
          .single;
      expect(pagoRecibido.montoAbonado, 1201); // 1200.5 → redondeado

      final ingreso = (await db.ingresosDao.getAllIngresos()).single;
      expect(ingreso.monto, 1500001); // 1500000.5 → redondeado

      final gastoFijo = (await db.gastosFijosDao.getAllGastosFijos()).single;
      expect(gastoFijo.monto, 800000); // 800000.4 → redondeado

      final gastoVariable = (await db.gastosVariablesDao
              .getAllGastosVariables())
          .single;
      expect(gastoVariable.monto, 46000); // 45999.6 → redondeado

      final presupuesto = (await db.presupuestosCategoriasDao
              .getAllPresupuestos())
          .single;
      expect(presupuesto.limiteMensual, 300000); // 300000.4 → redondeado
    },
  );
}
