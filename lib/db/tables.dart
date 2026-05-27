import 'package:drift/drift.dart';

class Deudas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get acreedorNombre => text()();
  RealColumn get montoOriginal => real()();
  RealColumn get tasaInteres => real().withDefault(const Constant(0))();
  TextColumn get tipoInteres => text().withDefault(const Constant('ninguno'))();
  DateTimeColumn get fechaPrestamo => dateTime()();
  DateTimeColumn get fechaLimite => dateTime().nullable()();
  RealColumn get cuotaMensual => real().nullable()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  TextColumn get estado => text().withDefault(const Constant('activa'))();
  DateTimeColumn get fechaPagoReal => dateTime().nullable()();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn => dateTime().withDefault(currentDateAndTime)();
}

class Prestamos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deudorNombre => text()();
  TextColumn get deudorContacto => text().withDefault(const Constant(''))();
  RealColumn get montoPrestado => real()();
  RealColumn get tasaInteres => real().withDefault(const Constant(0))();
  TextColumn get tipoInteres => text().withDefault(const Constant('ninguno'))();
  TextColumn get modalidadCalculo => text().withDefault(const Constant('simple'))();
  DateTimeColumn get fechaPrestamo => dateTime()();
  DateTimeColumn get fechaPactadaPago => dateTime().nullable()();
  TextColumn get estado => text().withDefault(const Constant('activo'))();
  TextColumn get notas => text().withDefault(const Constant(''))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn => dateTime().withDefault(currentDateAndTime)();
}

class PagosRecibidos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prestamoId => integer().references(Prestamos, #id)();
  RealColumn get montoAbonado => real()();
  DateTimeColumn get fechaPago => dateTime()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class PagosDeuda extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deudaId => integer().references(Deudas, #id)();
  RealColumn get montoAbonado => real()();
  DateTimeColumn get fechaPago => dateTime()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class Ingresos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get concepto => text()();
  RealColumn get monto => real()();
  TextColumn get frecuencia => text().withDefault(const Constant('mensual'))();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn => dateTime().withDefault(currentDateAndTime)();
}

class GastosFijos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get concepto => text()();
  RealColumn get monto => real()();
  TextColumn get frecuencia => text().withDefault(const Constant('mensual'))();
  IntColumn get diaCobro => integer().nullable()();
  TextColumn get notas => text().withDefault(const Constant(''))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn => dateTime().withDefault(currentDateAndTime)();
}

class Recordatorios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text()();
  TextColumn get referenciaTabla => text().nullable()();
  IntColumn get referenciaId => integer().nullable()();
  DateTimeColumn get fechaAlerta => dateTime()();
  IntColumn get diasAnticipacion => integer().withDefault(const Constant(3))();
  TextColumn get tipoNotificacion => text().withDefault(const Constant('sistema'))();
  BoolColumn get repetir => boolean().withDefault(const Constant(false))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

class ConfigSmtps extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get servidor => text().withDefault(const Constant(''))();
  IntColumn get puerto => integer().withDefault(const Constant(587))();
  TextColumn get usuario => text().withDefault(const Constant(''))();
  TextColumn get contrasenaEncriptada => text().nullable()();
  BoolColumn get tieneContrasena => boolean().withDefault(const Constant(false))();
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
