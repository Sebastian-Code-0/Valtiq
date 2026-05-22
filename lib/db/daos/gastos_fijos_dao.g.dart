// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gastos_fijos_dao.dart';

// ignore_for_file: type=lint
mixin _$GastosFijosDaoMixin on DatabaseAccessor<AppDatabase> {
  $GastosFijosTable get gastosFijos => attachedDatabase.gastosFijos;
  GastosFijosDaoManager get managers => GastosFijosDaoManager(this);
}

class GastosFijosDaoManager {
  final _$GastosFijosDaoMixin _db;
  GastosFijosDaoManager(this._db);
  $$GastosFijosTableTableManager get gastosFijos =>
      $$GastosFijosTableTableManager(_db.attachedDatabase, _db.gastosFijos);
}
