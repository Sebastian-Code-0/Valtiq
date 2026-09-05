import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:valtiq/db/database.dart';

/// Reconstruye a mano el esquema v1 (la primera versión publicada, antes de
/// que existieran `ConfigSmtps`, `PagosDeuda`, `GastosVariables` y
/// `PresupuestosCategorias`) sobre una base sqlite en memoria, con `PRAGMA
/// user_version = 1`. Al abrirla con la `AppDatabase` real (schemaVersion
/// 12), drift dispara los 11 bloques `if (from < N)` de `onUpgrade` en
/// cadena — el camino que recorrerá cualquier instalación que nunca se haya
/// actualizado desde el día 1.
///
/// Montos con fracción de peso (para verificar el redondeo de v9→v10) y
/// fechas de negocio con hora de día arbitraria (para verificar la
/// normalización a medianoche UTC de v10→v11), igual que en
/// `migration_v10_test.dart`/`migration_v11_test.dart`.
sqlite3.Database _crearBaseV1() {
  final raw = sqlite3.sqlite3.openInMemory();
  final ahora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  int epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  raw.execute('''
    CREATE TABLE deudas (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      acreedor_nombre TEXT NOT NULL,
      monto_original REAL NOT NULL,
      tasa_interes REAL NOT NULL DEFAULT 0,
      tipo_interes TEXT NOT NULL DEFAULT 'ninguno',
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
  // Prestamos ya tenía `modalidad_calculo` desde el día 1 (asimetría real con
  // Deudas, que la recibió recién en v8) — ver docs/ARCHITECTURE.md.
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
  // Sin frecuencia_aviso/ultima_notificacion/ultimo_envio_correo (v5) ni
  // hora_aviso/minuto_aviso (v6) — ninguna existía todavía en v1.
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
      creado_en INTEGER NOT NULL
    );
  ''');
  // A propósito: sin CREATE TABLE config_smtps/pagos_deuda/gastos_variables/
  // presupuestos_categorias — ninguna de las 4 existía en schemaVersion 1.

  final fechaPrestamoDeuda = DateTime(2023, 3, 10, 22, 40);
  final fechaPrestamoPrestamo = DateTime(2023, 5, 2, 6, 10);
  final fechaPagoRecibido = DateTime(2023, 6, 1, 23, 5);
  final fechaIngreso = DateTime(2023, 4, 1, 0, 5);
  final fechaAlerta = DateTime(2023, 7, 15, 23, 50);

  raw.execute(
    'INSERT INTO deudas '
    '(acreedor_nombre, monto_original, fecha_prestamo, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Banco Viejo', 999.6, epoch(fechaPrestamoDeuda), ahora, ahora],
  );
  raw.execute(
    'INSERT INTO prestamos '
    '(deudor_nombre, monto_prestado, fecha_prestamo, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Pedro', 1200.4, epoch(fechaPrestamoPrestamo), ahora, ahora],
  );
  raw.execute(
    'INSERT INTO pagos_recibidos '
    '(prestamo_id, monto_abonado, fecha_pago, creado_en) '
    'VALUES (1, ?, ?, ?)',
    [300.5, epoch(fechaPagoRecibido), ahora],
  );
  raw.execute(
    'INSERT INTO ingresos (concepto, monto, fecha, creado_en, actualizado_en) '
    'VALUES (?, ?, ?, ?, ?)',
    ['Salario viejo', 850000.2, epoch(fechaIngreso), ahora, ahora],
  );
  raw.execute(
    'INSERT INTO recordatorios (titulo, fecha_alerta, creado_en) '
    'VALUES (?, ?, ?)',
    ['Recordatorio viejo', epoch(fechaAlerta), ahora],
  );

  raw.execute('PRAGMA user_version = 1');
  return raw;
}

/// El día civil que un DateTime local representa, calculado con la misma
/// extracción que hará la migración real (interpretar el instante en la
/// zona local actual). No asume ningún huso fijo.
DateTime diaCivilEsperado(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day);

/// DateTime.== también compara el flag isUtc, no solo el instante — drift
/// reconstruye las fechas leídas como locales aunque representen medianoche
/// UTC, así que isAtSameMomentAs es la comparación correcta acá.
void expectMismoInstante(DateTime actual, DateTime esperado) {
  expect(
    actual.isAtSameMomentAs(esperado),
    isTrue,
    reason: 'Esperado el mismo instante que $esperado, pero fue $actual',
  );
}

void main() {
  test(
    'migración de CADENA COMPLETA v1 → v12 (instalación nunca actualizada '
    'desde el día 1): no crashea al abrir, y arrastra todas las '
    'transformaciones intermedias (montos a INTEGER en v9→v10, fechas a '
    'UTC-civil en v10→v11, tipoAmortizacion en v11→v12) sobre una base que '
    'nunca tuvo ConfigSmtps/PagosDeuda/GastosVariables/PresupuestosCategorias',
    () async {
      final fechaPrestamoDeuda = DateTime(2023, 3, 10, 22, 40);
      final fechaPrestamoPrestamo = DateTime(2023, 5, 2, 6, 10);
      final fechaPagoRecibido = DateTime(2023, 6, 1, 23, 5);
      final fechaIngreso = DateTime(2023, 4, 1, 0, 5);
      final fechaAlerta = DateTime(2023, 7, 15, 23, 50);

      final raw = _crearBaseV1();
      final db = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      final deuda = (await db.deudasDao.getAllDeudas()).single;
      expect(deuda.montoOriginal, 1000); // 999.6 redondeado (v9→v10)
      expect(deuda.modalidadCalculo, 'simple'); // default, columna agregada en v8
      expect(deuda.tipoAmortizacion, 'saldo_original'); // default (v12)
      expectMismoInstante(
        deuda.fechaPrestamo,
        diaCivilEsperado(fechaPrestamoDeuda),
      );

      final prestamo = (await db.prestamosDao.getAllPrestamos()).single;
      expect(prestamo.montoPrestado, 1200); // 1200.4 redondeado
      expect(prestamo.modalidadCalculo, 'simple'); // ya existía desde v1
      expect(prestamo.tipoAmortizacion, 'saldo_original');
      expectMismoInstante(
        prestamo.fechaPrestamo,
        diaCivilEsperado(fechaPrestamoPrestamo),
      );

      final pagoRecibido = (await db.prestamosDao.getAllPagosRecibidos())
          .single;
      expect(pagoRecibido.montoAbonado, 301); // 300.5 redondeado
      expectMismoInstante(
        pagoRecibido.fechaPago,
        diaCivilEsperado(fechaPagoRecibido),
      );

      final ingreso = (await db.ingresosDao.getAllIngresos()).single;
      expect(ingreso.monto, 850000); // 850000.2 redondeado
      expectMismoInstante(ingreso.fecha, diaCivilEsperado(fechaIngreso));

      final recordatorio = (await db.recordatoriosDao.getAllRecordatorios())
          .single;
      expectMismoInstante(
        recordatorio.fechaAlerta,
        diaCivilEsperado(fechaAlerta),
      );
      // Columnas agregadas en v5/v6, nunca existieron en v1 — deben llegar
      // con su default, no fallar ni quedar con basura.
      expect(recordatorio.frecuenciaAviso, 'unica');
      expect(recordatorio.horaAviso, 12);
      expect(recordatorio.minutoAviso, 0);
      expect(recordatorio.ultimaNotificacion, isNull);

      // ConfigSmtps no existía en v1: debe llegar creada limpia (fila id=1,
      // sin contraseña) en vez de crashear con "no such column: contrasena"
      // (bug real encontrado al escribir este test — ver docs/ARCHITECTURE.md,
      // sección Migraciones, y el `if (from >= 2)` en database.dart).
      final config = await db.configSmtpDao.getConfig();
      expect(config.id, 1);
      expect(config.tieneContrasena, isFalse);
      expect(config.contrasenaEncriptada, isNull);

      // Tablas creadas en v3/v7/v9 (no existían en v1): deben quedar vacías
      // y consultables sin error, no ausentes ni corruptas.
      expect(await db.pagosDeudaDao.getAllPagos(), isEmpty);
      expect(await db.gastosVariablesDao.getAllGastosVariables(), isEmpty);
      expect(
        await db.presupuestosCategoriasDao.watchPresupuestos().first,
        isEmpty,
      );
    },
  );
}
