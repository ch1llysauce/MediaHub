// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloads_dao.dart';

// ignore_for_file: type=lint
mixin _$DownloadsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DownloadTasksTable get downloadTasks => attachedDatabase.downloadTasks;
  DownloadsDaoManager get managers => DownloadsDaoManager(this);
}

class DownloadsDaoManager {
  final _$DownloadsDaoMixin _db;
  DownloadsDaoManager(this._db);
  $$DownloadTasksTableTableManager get downloadTasks =>
      $$DownloadTasksTableTableManager(_db.attachedDatabase, _db.downloadTasks);
}
