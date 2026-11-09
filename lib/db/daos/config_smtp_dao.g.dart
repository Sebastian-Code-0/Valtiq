// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_smtp_dao.dart';

// ignore_for_file: type=lint
mixin _$ConfigSmtpDaoMixin on DatabaseAccessor<AppDatabase> {
  $ConfigSmtpsTable get configSmtps => attachedDatabase.configSmtps;
  ConfigSmtpDaoManager get managers => ConfigSmtpDaoManager(this);
}

class ConfigSmtpDaoManager {
  final _$ConfigSmtpDaoMixin _db;
  ConfigSmtpDaoManager(this._db);
  $$ConfigSmtpsTableTableManager get configSmtps =>
      $$ConfigSmtpsTableTableManager(_db.attachedDatabase, _db.configSmtps);
}
