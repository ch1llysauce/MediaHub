import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'downloads_dao.g.dart';

@DriftAccessor(tables: [DownloadTasks])
class DownloadsDao extends DatabaseAccessor<AppDatabase> with _$DownloadsDaoMixin {
  DownloadsDao(super.db);

  /// Watch all download tasks ordered by creation date (newest first)
  Stream<List<DownloadTaskRow>> watchAllTasks() {
    return (select(downloadTasks)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  /// Get all download tasks
  Future<List<DownloadTaskRow>> getAllTasks() {
    return (select(downloadTasks)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  /// Get single download task by ID
  Future<DownloadTaskRow?> getTaskById(String id) {
    return (select(downloadTasks)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new download task or update if ID exists
  Future<void> upsertTask(DownloadTasksCompanion companion) {
    return into(downloadTasks).insertOnConflictUpdate(companion);
  }

  /// Update task status and optional error message
  Future<void> updateTaskStatus(String id, String status, {String? errorMessage}) {
    return (update(downloadTasks)..where((tbl) => tbl.id.equals(id))).write(
      DownloadTasksCompanion(
        status: Value(status),
        errorMessage: Value(errorMessage),
      ),
    );
  }

  /// Update task progress and byte counters
  Future<void> updateTaskProgress(String id, double progress, int bytesDownloaded, int totalBytes) {
    return (update(downloadTasks)..where((tbl) => tbl.id.equals(id))).write(
      DownloadTasksCompanion(
        progress: Value(progress),
        bytesDownloaded: Value(bytesDownloaded),
        totalBytes: Value(totalBytes),
      ),
    );
  }

  /// Delete a download task record
  Future<int> deleteTask(String id) {
    return (delete(downloadTasks)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Clear all completed or cancelled tasks
  Future<int> clearCompletedOrCancelledTasks() {
    return (delete(downloadTasks)
          ..where((tbl) => tbl.status.isIn(['completed', 'cancelled'])))
        .go();
  }
}
