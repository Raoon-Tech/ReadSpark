// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_dao.dart';

// ignore_for_file: type=lint
mixin _$VoiceDaoMixin on DatabaseAccessor<AppDatabase> {
  $VoicesTable get voices => attachedDatabase.voices;
  VoiceDaoManager get managers => VoiceDaoManager(this);
}

class VoiceDaoManager {
  final _$VoiceDaoMixin _db;
  VoiceDaoManager(this._db);
  $$VoicesTableTableManager get voices =>
      $$VoicesTableTableManager(_db.attachedDatabase, _db.voices);
}
