import '../entities/media_item_entity.dart';
import '../entities/scan_directory_entity.dart';

abstract class MediaRepository {
  Future<List<MediaItemEntity>> getAllMedia();
  Stream<List<MediaItemEntity>> watchAllMedia();
  Future<List<MediaItemEntity>> getMediaByType(String mediaType);
  Stream<List<MediaItemEntity>> watchMediaByType(String mediaType);
  Future<MediaItemEntity?> getMediaById(String id);
  Future<MediaItemEntity?> getMediaByPath(String path);
  Future<void> scanDirectories(List<String> directoryPaths);
  Future<void> scanSingleFile(String filePath);
  Future<List<ScanDirectoryEntity>> getScanDirectories();
  Stream<List<ScanDirectoryEntity>> watchScanDirectories();
  Future<void> addScanDirectory(String path);
  Future<void> removeScanDirectory(String id);
  Future<void> updateMediaDuration(String id, int durationInSeconds);
}
