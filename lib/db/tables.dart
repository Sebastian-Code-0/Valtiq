import 'package:drift/drift.dart';

class Deudas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get acreedorNombre => text()();
  // Segunda línea de la tarjeta ("BBVA tarjeta de crédito"). `acreedorNombre`
  // es el nombre principal ("Tarjeta Nu"). Agregada en schemaVersion 14.
  TextColumn get descripcion => text().withDefault(const Constant(''))();
  // 'persona' | 'tarjeta' | 'banco' | 'tienda' | 'otro' — decide la imagen
  // de la tarjeta (ver lib/utils/tipo_deuda.dart). schemaVersion 14.
  TextColumn get tipo => text().withDefault(const Constant('otro'))();
  // Día del mes (1–31) en que toca pagar; null = sin día fijo. De aquí sale
  // "Próximo pago". schemaVersion 14.
  IntColumn get diaPago => integer().nullable()();
  IntColumn get montoOriginal => integer()();
  RealColumn get tasaInteres => real().withDefault(const Constant(0))();
  TextColumn get tipoInteres => text().withDefault(const Constant('ninguno'))();
  TextColumn get modalidadCalculo =>
      text().withDefault(const Constant('simple'))();
  // 'saldo_original': el interés se acumula siempre sobre montoOriginal
  // completo (comportamiento histórico, pensado para deuda informal donde no
  // se sabe si habrá abonos periódicos). 'saldo_insoluto': cada abono se
  // aplica primero al interés causado y luego a capital, y el interés
  // siguiente se calcula sobre el capital restante — igual que un crédito
  // bancario real. Ver lib/services/interes_calculator.dart.
  TextColumn get tipoAmortizacion =>
      text().withDefault(const Constant('saldo_original'))();
  DateTimeColumn get fechaPrestamo => dateTime()();
  DateTimeColumn get fechaLimite => dateTime().nullable()();
  IntColumn get cuotaMensual => integer().nullable()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  TextColumn get estado => text().withDefault(const Constant('activa'))();
  DateTimeColumn get fechaPagoReal => dateTime().nullable()();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn =>
      dateTime().withDefault(currentDateAndTime)();
}

class Prestamos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deudorNombre => text()();
  TextColumn get deudorContacto => text().withDefault(const Constant(''))();
  IntColumn get montoPrestado => integer()();
  RealColumn get tasaInteres => real().withDefault(const Constant(0))();
  TextColumn get tipoInteres => text().withDefault(const Constant('ninguno'))();
  TextColumn get modalidadCalculo =>
      text().withDefault(const Constant('simple'))();
  TextColumn get tipoAmortizacion =>
      text().withDefault(const Constant('saldo_original'))();
  DateTimeColumn get fechaPrestamo => dateTime()();
  DateTimeColumn get fechaPactadaPago => dateTime().nullable()();
  TextColumn get estado => text().withDefault(const Constant('activo'))();
  DateTimeColumn get fechaPagoReal => dateTime().nullable()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn =>
      dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'idx_pagos_recibidos_prestamo_id', columns: {#prestamoId})
class PagosRecibidos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prestamoId => integer().references(Prestamos, #id)();
  IntColumn get montoAbonado => integer()();
  DateTimeColumn get fechaPago => dateTime()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'idx_pagos_deuda_deuda_id', columns: {#deudaId})
class PagosDeuda extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deudaId => integer().references(Deudas, #id)();
  IntColumn get montoAbonado => integer()();
  DateTimeColumn get fechaPago => dateTime()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class Ingresos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get concepto => text()();
  IntColumn get monto => integer()();
  TextColumn get frecuencia => text().withDefault(const Constant('mensual'))();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn =>
      dateTime().withDefault(currentDateAndTime)();
}

class GastosFijos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get concepto => text()();
  IntColumn get monto => integer()();
  TextColumn get frecuencia => text().withDefault(const Constant('mensual'))();
  IntColumn get diaCobro => integer().nullable()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn =>
      dateTime().withDefault(currentDateAndTime)();
}

class Recordatorios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text()();
  TextColumn get referenciaTabla => text().nullable()();
  IntColumn get referenciaId => integer().nullable()();
  DateTimeColumn get fechaAlerta => dateTime()();
  IntColumn get diasAnticipacion => integer().withDefault(const Constant(3))();
  TextColumn get tipoNotificacion =>
      text().withDefault(const Constant('sistema'))();
  BoolColumn get repetir => boolean().withDefault(const Constant(false))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  // 'unica': avisa una sola vez al entrar en ventana | 'diaria': re-avisa una vez al día
  TextColumn get frecuenciaAviso =>
      text().withDefault(const Constant('unica'))();
  DateTimeColumn get ultimaNotificacion => dateTime().nullable()();
  DateTimeColumn get ultimoEnvioCorreo => dateTime().nullable()();
  IntColumn get horaAviso => integer().withDefault(const Constant(12))();
  IntColumn get minutoAviso => integer().withDefault(const Constant(0))();
  // Día del mes que el usuario eligió para un recordatorio que se repite
  // (1–31). Al pasar por un mes corto la fecha baja a su último día (31 →
  // 28 de febrero); con esto el mes siguiente vuelve al 31 en vez de
  // quedarse en 28 para siempre. null = recordatorio guardado antes de
  // schemaVersion 15 (se usa el día de `fechaAlerta`).
  IntColumn get diaOriginal => integer().nullable()();
}

class ConfigSmtps extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get servidor => text().withDefault(const Constant(''))();
  IntColumn get puerto => integer().withDefault(const Constant(587))();
  TextColumn get usuario => text().withDefault(const Constant(''))();
  TextColumn get contrasenaEncriptada => text().nullable()();
  BoolColumn get tieneContrasena =>
      boolean().withDefault(const Constant(false))();
  TextColumn get correoDestino => text().withDefault(const Constant(''))();
  TextColumn get nombreRemitente =>
      text().withDefault(const Constant('Valtiq'))();
  BoolColumn get ssl => boolean().withDefault(const Constant(false))();
  BoolColumn get habilitado => boolean().withDefault(const Constant(false))();
  DateTimeColumn get actualizadoEn =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class GastosVariables extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get descripcion => text()();
  IntColumn get monto => integer()();
  TextColumn get categoria => text()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get notas => text().nullable()();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class PresupuestosCategorias extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get categoria => text()();
  IntColumn get limiteMensual => integer()();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {categoria},
  ];
}

/// Categorías de los gastos del día a día, editables por el usuario desde
/// schemaVersion 15 (antes eran fijas en `CategoriaGasto`).
///
/// Los gastos y los presupuestos siguen guardando el NOMBRE de su categoría
/// (texto), no este id: así los respaldos viejos se leen sin conversión y
/// renombrar una categoría es un solo UPDATE sobre los gastos que la usan
/// (ver `CategoriasDao.actualizar`).
class Categorias extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  // Clave del catálogo fijo de `lib/utils/iconos_categoria.dart` (no el
  // código del ícono: Flutter descarta en el APK los íconos que no se usan
  // por nombre en el código).
  TextColumn get icono => text().withDefault(const Constant('otros'))();
  // Color ARGB (0xFFRRGGBB), uno de la paleta de `iconos_categoria.dart`.
  IntColumn get color => integer()();
  IntColumn get orden => integer().withDefault(const Constant(0))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {nombre},
  ];
}
