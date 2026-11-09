// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingresos_dao.dart';

// ignore_for_file: type=lint
mixin _$IngresosDaoMixin on DatabaseAccessor<AppDatabase> {
  $IngresosTable get ingresos => attachedDatabase.ingresos;
  IngresosDaoManager get managers => IngresosDaoManager(this);
}

class IngresosDaoManager {
  final _$IngresosDaoMixin _db;
  IngresosDaoManager(this._db);
  $$IngresosTableTableManager get ingresos =>
      $$IngresosTableTableManager(_db.attachedDatabase, _db.ingresos);
}
