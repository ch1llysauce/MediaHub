// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_directories_dao.dart';

// ignore_for_file: type=lint
mixin _$ScanDirectoriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScanDirectoriesTable get scanDirectories => attachedDatabase.scanDirectories;
  ScanDirectoriesDaoManager get managers => ScanDirectoriesDaoManager(this);
}

class ScanDirectoriesDaoManager {
  final _$ScanDirectoriesDaoMixin _db;
  ScanDirectoriesDaoManager(this._db);
  $$ScanDirectoriesTableTableManager get scanDirectories =>
      $$ScanDirectoriesTableTableManager(
        _db.attachedDatabase,
        _db.scanDirectories,
      );
}
