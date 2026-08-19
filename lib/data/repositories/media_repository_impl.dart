import '../../core/services/media_scanner_service.dart';
import '../../domain/entities/media_item_entity.dart';
import '../../domain/entities/scan_directory_entity.dart';
import '../../domain/repositories/media_repository.dart';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';
import '../database/daos/scan_directories_dao.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaDao _mediaDao;
  final ScanDirectoriesDao _scanDirectoriesDao;
  final MediaScannerService _scannerService;

  MediaRepositoryImpl({
    required MediaDao mediaDao,
    required ScanDirectoriesDao scanDirectoriesDao,
    required MediaScannerService scannerService,
  })  : _mediaDao = mediaDao,
        _scanDirectoriesDao = scanDirectoriesDao,
        _scannerService = scannerService;

  MediaItemEntity _rowToEntity(MediaItemRow row) {
    return MediaItemEntity(
      id: row.id,
      path: row.path,
      title: row.title,
      artist: row.artist,
      album: row.album,
      genre: row.genre,
      duration: row.duration,
      mediaType: row.mediaType,
      artworkPath: row.artworkPath,
      fileSize: row.fileSize,
      dateAdded: row.dateAdded,
      lastPlayed: row.lastPlayed,
      isAvailable: row.isAvailable,
    );
  }

  ScanDirectoryEntity _dirRowToEntity(ScanDirectoryRow row) {
    return ScanDirectoryEntity(
      id: row.id,
      path: row.path,
      isDefault: row.isDefault,
      dateAdded: row.dateAdded,
    );
  }

  @override
  Future<List<MediaItemEntity>> getAllMedia() async {
    final rows = await _mediaDao.getAllMedia();
    return rows.map(_rowToEntity).toList();
  }

  @override
  Stream<List<MediaItemEntity>> watchAllMedia() {
    return _mediaDao.watchAllMedia().map(
          (rows) => rows.map(_rowToEntity).toList(),
        );
  }

  @override
  Future<List<MediaItemEntity>> getMediaByType(String mediaType) async {
    final rows = await _mediaDao.getMediaByType(mediaType);
    return rows.map(_rowToEntity).toList();
  }

  @override
  Stream<List<MediaItemEntity>> watchMediaByType(String mediaType) {
    return _mediaDao.watchMediaByType(mediaType).map(
          (rows) => rows.map(_rowToEntity).toList(),
        );
  }

  @override
  Future<MediaItemEntity?> getMediaById(String id) async {
    final row = await _mediaDao.getMediaById(id);
    return row != null ? _rowToEntity(row) : null;
  }

  @override
  Future<MediaItemEntity?> getMediaByPath(String path) async {
    final row = await _mediaDao.getMediaByPath(path);
    return row != null ? _rowToEntity(row) : null;
  }

  @override
  Future<void> scanDirectories(List<String> directoryPaths) async {
    final scannedFiles = await _scannerService.scanDirectories(directoryPaths);
    final companions = scannedFiles.map(_scannerService.toCompanion).toList();

    // Batch upsert discovered media items into SQLite
    await _mediaDao.upsertMediaBatch(companions);

    // Reconcile and mark missing files as unavailable
    final scannedPaths = scannedFiles.map((f) => f.path).toList();
    await _mediaDao.markMissingFiles(scannedPaths);
  }

  @override
  Future<List<ScanDirectoryEntity>> getScanDirectories() async {
    final rows = await _scanDirectoriesDao.getAllDirectories();
    return rows.map(_dirRowToEntity).toList();
  }

  @override
  Future<void> addScanDirectory(String path) async {
    final id = path.hashCode.abs().toString();
    final companion = ScanDirectoriesCompanion.insert(
      id: id,
      path: path,
      dateAdded: DateTime.now(),
    );
    await _scanDirectoriesDao.addDirectory(companion);
  }

  @override
  Future<void> removeScanDirectory(String id) async {
    await _scanDirectoriesDao.removeDirectory(id);
  }

  @override
  Future<void> updateMediaDuration(String id, int durationInSeconds) async {
    await _mediaDao.updateMediaDuration(id, durationInSeconds);
  }
}
