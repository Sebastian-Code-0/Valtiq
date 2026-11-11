import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:valtiq/db/database.dart';

/// Reconstruye a mano el esquema v13 (el de la versión 1.8.0 publicada:
/// `deudas` todavía sin `descripcion`, `tipo` ni `dia_pago`) con `PRAGMA
/// user_version = 13`. Al abrirla con la `AppDatabase` real (schemaVersion
/// 14) drift dispara únicamente el bloque `if (from < 14)` de `onUpgrade`:
/// el camino de cualquier usuario real que actualice desde la 1.8.0.
sqlite3.Database _crearBaseV13() {
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
      tipo_amortizacion TEXT NOT NULL DEFAULT 'saldo_original',
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
      tipo_amortizacion TEXT NOT NULL DEFAULT 'saldo_original',
      fecha_prestamo INTEGER NOT NULL,
      fecha_pactada_pago INTEGER,
      estado TEXT NOT NULL DEFAULT 'activo',
      fecha_pago_real INTEGER,
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

  raw.execute('INSERT INTO config_smtps (id, actualizado_en) VALUES (1, ?)', [
    ahora,
  ]);

  final fechaPrestamo = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;

  raw.execute(
    'INSERT INTO deudas '
    '(acreedor_nombre, monto_original, modalidad_calculo, fecha_prestamo, '
    'creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    ['Banco Test', 3000000, 'simple', fechaPrestamo, ahora, ahora],
  );
  // Un préstamo YA marcado pagado bajo el schema viejo (sin fecha_pago_real
  // — ese caso, el único que puede existir en datos reales, es justamente el
  // que antes hacía que el interés mostrado siguiera creciendo para
  // siempre).
  raw.execute(
    'INSERT INTO prestamos '
    "(deudor_nombre, monto_prestado, estado, fecha_prestamo, creado_en, "
    'actualizado_en) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    ['Ana', 750000, 'pagado', fechaPrestamo, ahora, ahora],
  );

  raw.execute('PRAGMA user_version = 13');
  return raw;
}

void main() {
  test('migración v13 → v14: deudas gana descripcion (vacía), tipo ("otro") y '
      'diaPago (null) sin tocar las columnas que ya tenía', () async {
    final raw = _crearBaseV13();
    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final deuda = (await db.deudasDao.getAllDeudas()).single;
    expect(deuda.acreedorNombre, 'Banco Test');
    expect(deuda.montoOriginal, 3000000);
    expect(deuda.descripcion, '');
    expect(deuda.tipo, 'otro');
    expect(deuda.diaPago, isNull);
    expect(deuda.estado, 'activa');
    expect(deuda.fechaPrestamo.toUtc(), DateTime.utc(2026, 1, 1));

    // Los préstamos no se tocan en esta migración.
    final prestamo = (await db.prestamosDao.getAllPrestamos()).single;
    expect(prestamo.deudorNombre, 'Ana');
    expect(prestamo.montoPrestado, 750000);
  });

  test(
    'tras migrar a v14 se puede guardar una deuda con los campos nuevos',
    () async {
      final raw = _crearBaseV13();
      final db = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final id = await db.deudasDao.insertDeuda(
        DeudasCompanion.insert(
          acreedorNombre: 'Tarjeta Nu',
          montoOriginal: 1200000,
          fechaPrestamo: DateTime.utc(2026, 10, 1),
          descripcion: const Value('Nu tarjeta de crédito'),
          tipo: const Value('tarjeta'),
          diaPago: const Value(12),
          // La tabla hecha a mano de este test no declara el DEFAULT de estas
          // dos columnas (drift sí lo hace en una base real).
          creadoEn: Value(DateTime.now()),
          actualizadoEn: Value(DateTime.now()),
        ),
      );
      final deuda = await db.deudasDao.getDeudaById(id);
      expect(deuda!.descripcion, 'Nu tarjeta de crédito');
      expect(deuda.tipo, 'tarjeta');
      expect(deuda.diaPago, 12);
    },
  );
}
