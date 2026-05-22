// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deudas_dao.dart';

// ignore_for_file: type=lint
mixin _$DeudasDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeudasTable get deudas => attachedDatabase.deudas;
  DeudasDaoManager get managers => DeudasDaoManager(this);
}

class DeudasDaoManager {
  final _$DeudasDaoMixin _db;
  DeudasDaoManager(this._db);
  $$DeudasTableTableManager get deudas =>
      $$DeudasTableTableManager(_db.attachedDatabase, _db.deudas);
}
