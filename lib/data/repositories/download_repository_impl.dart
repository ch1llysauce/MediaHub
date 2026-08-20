import 'package:drift/drift.dart';
import '../../domain/entities/download_task_entity.dart';
import '../../domain/repositories/download_repository.dart';
import '../database/app_database.dart';
import '../database/daos/downloads_dao.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  final DownloadsDao _dao;

  DownloadRepositoryImpl(this._dao);

  DownloadTaskEntity _rowToEntity(DownloadTaskRow row) {
    return DownloadTaskEntity(
      id: row.id,
      url: row.url,
      destinationPath: row.destinationPath,
      status: DownloadStatus.fromString(row.status),
      progress: row.progress,
      bytesDownloaded: row.bytesDownloaded,
      totalBytes: row.totalBytes,
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<List<DownloadTaskEntity>> getAllTasks() async {
    final rows = await _dao.getAllTasks();
    return rows.map(_rowToEntity).toList();
  }

  @override
  Stream<List<DownloadTaskEntity>> watchAllTasks() {
    return _dao.watchAllTasks().map(
          (rows) => rows.map(_rowToEntity).toList(),
        );
  }

  @override
  Future<DownloadTaskEntity?> getTaskById(String id) async {
    final row = await _dao.getTaskById(id);
    return row != null ? _rowToEntity(row) : null;
  }

  @override
  Future<void> saveTask(DownloadTaskEntity task) async {
    final companion = DownloadTasksCompanion(
      id: Value(task.id),
      url: Value(task.url),
      destinationPath: Value(task.destinationPath),
      status: Value(task.status.toDbString()),
      progress: Value(task.progress),
      bytesDownloaded: Value(task.bytesDownloaded),
      totalBytes: Value(task.totalBytes),
      errorMessage: Value(task.errorMessage),
      createdAt: Value(task.createdAt),
    );
    await _dao.upsertTask(companion);
  }

  @override
  Future<void> updateStatus(String id, DownloadStatus status, {String? errorMessage}) async {
    await _dao.updateTaskStatus(id, status.toDbString(), errorMessage: errorMessage);
  }

  @override
  Future<void> updateProgress(String id, double progress, int bytesDownloaded, int totalBytes) async {
    await _dao.updateTaskProgress(id, progress, bytesDownloaded, totalBytes);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _dao.deleteTask(id);
  }

  @override
  Future<void> clearCompletedOrCancelled() async {
    await _dao.clearCompletedOrCancelledTasks();
  }
}
