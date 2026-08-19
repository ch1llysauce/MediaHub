import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'scan_directories_dao.g.dart';

@DriftAccessor(tables: [ScanDirectories])
class ScanDirectoriesDao extends DatabaseAccessor<AppDatabase> with _$ScanDirectoriesDaoMixin {
  ScanDirectoriesDao(super.db);

  Future<List<ScanDirectoryRow>> getAllDirectories() {
    return select(scanDirectories).get();
  }

  Stream<List<ScanDirectoryRow>> watchAllDirectories() {
    return select(scanDirectories).watch();
  }

  Future<void> addDirectory(ScanDirectoriesCompanion directory) {
    return into(scanDirectories).insertOnConflictUpdate(directory);
  }

  Future<int> removeDirectory(String id) {
    return (delete(scanDirectories)..where((tbl) => tbl.id.equals(id))).go();
  }
}
