// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorias_dao.dart';

// ignore_for_file: type=lint
mixin _$CategoriasDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriasTable get categorias => attachedDatabase.categorias;
  $GastosVariablesTable get gastosVariables => attachedDatabase.gastosVariables;
  $PresupuestosCategoriasTable get presupuestosCategorias =>
      attachedDatabase.presupuestosCategorias;
  CategoriasDaoManager get managers => CategoriasDaoManager(this);
}

class CategoriasDaoManager {
  final _$CategoriasDaoMixin _db;
  CategoriasDaoManager(this._db);
  $$CategoriasTableTableManager get categorias =>
      $$CategoriasTableTableManager(_db.attachedDatabase, _db.categorias);
  $$GastosVariablesTableTableManager get gastosVariables =>
      $$GastosVariablesTableTableManager(
        _db.attachedDatabase,
        _db.gastosVariables,
      );
  $$PresupuestosCategoriasTableTableManager get presupuestosCategorias =>
      $$PresupuestosCategoriasTableTableManager(
        _db.attachedDatabase,
        _db.presupuestosCategorias,
      );
}
