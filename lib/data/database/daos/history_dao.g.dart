// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_dao.dart';

// ignore_for_file: type=lint
mixin _$HistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $HistoryTable get history => attachedDatabase.history;
  $MediaItemsTable get mediaItems => attachedDatabase.mediaItems;
  HistoryDaoManager get managers => HistoryDaoManager(this);
}

class HistoryDaoManager {
  final _$HistoryDaoMixin _db;
  HistoryDaoManager(this._db);
  $$HistoryTableTableManager get history =>
      $$HistoryTableTableManager(_db.attachedDatabase, _db.history);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db.attachedDatabase, _db.mediaItems);
}
