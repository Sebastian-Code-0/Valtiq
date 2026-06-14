// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gastos_variables_dao.dart';

// ignore_for_file: type=lint
mixin _$GastosVariablesDaoMixin on DatabaseAccessor<AppDatabase> {
  $GastosVariablesTable get gastosVariables => attachedDatabase.gastosVariables;
  GastosVariablesDaoManager get managers => GastosVariablesDaoManager(this);
}

class GastosVariablesDaoManager {
  final _$GastosVariablesDaoMixin _db;
  GastosVariablesDaoManager(this._db);
  $$GastosVariablesTableTableManager get gastosVariables =>
      $$GastosVariablesTableTableManager(
        _db.attachedDatabase,
        _db.gastosVariables,
      );
}
