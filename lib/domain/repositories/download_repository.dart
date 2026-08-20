import '../entities/download_task_entity.dart';

abstract class DownloadRepository {
  Future<List<DownloadTaskEntity>> getAllTasks();
  Stream<List<DownloadTaskEntity>> watchAllTasks();
  Future<DownloadTaskEntity?> getTaskById(String id);
  Future<void> saveTask(DownloadTaskEntity task);
  Future<void> updateStatus(String id, DownloadStatus status, {String? errorMessage});
  Future<void> updateProgress(String id, double progress, int bytesDownloaded, int totalBytes);
  Future<void> deleteTask(String id);
  Future<void> clearCompletedOrCancelled();
}
