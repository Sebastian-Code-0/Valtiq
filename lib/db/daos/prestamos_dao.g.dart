// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prestamos_dao.dart';

// ignore_for_file: type=lint
mixin _$PrestamosDaoMixin on DatabaseAccessor<AppDatabase> {
  $PrestamosTable get prestamos => attachedDatabase.prestamos;
  $PagosRecibidosTable get pagosRecibidos => attachedDatabase.pagosRecibidos;
  PrestamosDaoManager get managers => PrestamosDaoManager(this);
}

class PrestamosDaoManager {
  final _$PrestamosDaoMixin _db;
  PrestamosDaoManager(this._db);
  $$PrestamosTableTableManager get prestamos =>
      $$PrestamosTableTableManager(_db.attachedDatabase, _db.prestamos);
  $$PagosRecibidosTableTableManager get pagosRecibidos =>
      $$PagosRecibidosTableTableManager(
        _db.attachedDatabase,
        _db.pagosRecibidos,
      );
}
