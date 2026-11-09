// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagos_deuda_dao.dart';

// ignore_for_file: type=lint
mixin _$PagosDeudaDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeudasTable get deudas => attachedDatabase.deudas;
  $PagosDeudaTable get pagosDeuda => attachedDatabase.pagosDeuda;
  PagosDeudaDaoManager get managers => PagosDeudaDaoManager(this);
}

class PagosDeudaDaoManager {
  final _$PagosDeudaDaoMixin _db;
  PagosDeudaDaoManager(this._db);
  $$DeudasTableTableManager get deudas =>
      $$DeudasTableTableManager(_db.attachedDatabase, _db.deudas);
  $$PagosDeudaTableTableManager get pagosDeuda =>
      $$PagosDeudaTableTableManager(_db.attachedDatabase, _db.pagosDeuda);
}
