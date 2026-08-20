import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/downloads_dao.dart';
import 'daos/favorites_dao.dart';
import 'daos/history_dao.dart';
import 'daos/media_dao.dart';
import 'daos/playlists_dao.dart';
import 'daos/scan_directories_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftAccessor()
@DriftDatabase(
  tables: [
    MediaItems,
    ScanDirectories,
    Playlists,
    PlaylistItems,
    Favorites,
    History,
    DownloadTasks,
  ],
  daos: [
    MediaDao,
    ScanDirectoriesDao,
    PlaylistsDao,
    FavoritesDao,
    HistoryDao,
    DownloadsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  /// In-memory database connection for unit testing
  AppDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Schema migrations will be placed here in future versions
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mediahub.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
