// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recordatorios_dao.dart';

// ignore_for_file: type=lint
mixin _$RecordatoriosDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecordatoriosTable get recordatorios => attachedDatabase.recordatorios;
  RecordatoriosDaoManager get managers => RecordatoriosDaoManager(this);
}

class RecordatoriosDaoManager {
  final _$RecordatoriosDaoMixin _db;
  RecordatoriosDaoManager(this._db);
  $$RecordatoriosTableTableManager get recordatorios =>
      $$RecordatoriosTableTableManager(_db.attachedDatabase, _db.recordatorios);
}
