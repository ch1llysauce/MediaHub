import 'package:drift/drift.dart';

@DataClassName('MediaItemRow')
class MediaItems extends Table {
  TextColumn get id => text()();
  TextColumn get path => text().unique()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get duration => integer().nullable()(); // in seconds
  TextColumn get mediaType => text()(); // 'audio' or 'video'
  TextColumn get artworkPath => text().nullable()();
  IntColumn get fileSize => integer()(); // in bytes
  DateTimeColumn get dateAdded => dateTime()();
  DateTimeColumn get lastPlayed => dateTime().nullable()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ScanDirectoryRow')
class ScanDirectories extends Table {
  TextColumn get id => text()();
  TextColumn get path => text().unique()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dateAdded => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistRow')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistItemRow')
class PlaylistItems extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId => text()();
  TextColumn get mediaId => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FavoriteRow')
class Favorites extends Table {
  TextColumn get id => text()();
  TextColumn get mediaId => text().unique()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HistoryRow')
class History extends Table {
  TextColumn get id => text()();
  TextColumn get mediaId => text()();
  DateTimeColumn get lastPlayed => dateTime()();
  IntColumn get playbackPosition => integer().withDefault(const Constant(0))(); // in seconds

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DownloadTaskRow')
class DownloadTasks extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get destinationPath => text()();
  TextColumn get status => text()(); // queued, resolving, downloading, paused, completed, failed, cancelled
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  IntColumn get bytesDownloaded => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get maxRetries => integer().withDefault(const Constant(3))();

  @override
  Set<Column> get primaryKey => {id};
}
