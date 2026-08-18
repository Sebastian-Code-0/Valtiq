// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presupuestos_categorias_dao.dart';

// ignore_for_file: type=lint
mixin _$PresupuestosCategoriasDaoMixin on DatabaseAccessor<AppDatabase> {
  $PresupuestosCategoriasTable get presupuestosCategorias =>
      attachedDatabase.presupuestosCategorias;
  PresupuestosCategoriasDaoManager get managers =>
      PresupuestosCategoriasDaoManager(this);
}

class PresupuestosCategoriasDaoManager {
  final _$PresupuestosCategoriasDaoMixin _db;
  PresupuestosCategoriasDaoManager(this._db);
  $$PresupuestosCategoriasTableTableManager get presupuestosCategorias =>
      $$PresupuestosCategoriasTableTableManager(
        _db.attachedDatabase,
        _db.presupuestosCategorias,
      );
}
