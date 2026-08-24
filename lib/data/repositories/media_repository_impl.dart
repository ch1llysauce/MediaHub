import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../core/services/media_artwork_service.dart';
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
     final companions = await Future.wait(
    scannedFiles.map((file) => _scannerService.toCompanion(file)),
  );


    // Batch upsert discovered media items into SQLite
    await _mediaDao.upsertMediaBatch(companions);

    // Reconcile and mark missing files as unavailable based on physical storage check
    await _mediaDao.reconcileMissingFiles();

    // Run background duration and artwork extractions asynchronously without delaying UI scan completion
    unawaited(_populateAllMissingDurations());
    unawaited(_populateAllMissingArtworks());
  }

  @override
  Future<void> scanSingleFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    try {
      final stat = await file.stat();
      final mediaType = _scannerService.getMediaType(filePath);
      final fallbackTitle = p.basenameWithoutExtension(filePath);

      final scannedFile = ScannedMediaFile(
        path: filePath,
        title: fallbackTitle,
        mediaType: mediaType,
        fileSize: stat.size,
        dateAdded: stat.modified,
      );

      final companion = await _scannerService.toCompanion(scannedFile);
      await _mediaDao.upsertMedia(companion);

      final artworkPath = await _artworkService.extractArtwork(
        filePath: filePath,
        mediaId: companion.id.value,
        mediaType: mediaType,
      );
      if (artworkPath != null) {
        await _mediaDao.updateMediaArtwork(companion.id.value, artworkPath);
      }
    } catch (_) {}
  }

  final MediaArtworkService _artworkService = MediaArtworkService();

  Future<void> _populateAllMissingArtworks() async {
    try {
      final allMedia = await _mediaDao.getAllMedia();
      final missingArtworks = allMedia
          .where((m) => m.artworkPath == null || m.artworkPath!.isEmpty)
          .toList();

      if (missingArtworks.isNotEmpty) {
        for (final media in missingArtworks) {
          try {
            final file = File(media.path);
            if (await file.exists()) {
              final artworkPath = await _artworkService.extractArtwork(
                filePath: media.path,
                mediaId: media.id,
                mediaType: media.mediaType,
              );
              if (artworkPath != null) {
                await _mediaDao.updateMediaArtwork(media.id, artworkPath);
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> _populateAllMissingDurations() async {
    try {
      final allMedia = await _mediaDao.getAllMedia();
      final missingAudio = allMedia.where((m) => m.mediaType == 'audio' && (m.duration == null || m.duration == 0)).toList();

      if (missingAudio.isNotEmpty) {
        for (final media in missingAudio) {
          try {
            final file = File(media.path);
            if (await file.exists()) {
              final metadata = readMetadata(file);
              if (metadata.duration != null && metadata.duration!.inSeconds > 0) {
                await _mediaDao.updateMediaDuration(media.id, metadata.duration!.inSeconds);
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  @override
  Future<List<ScanDirectoryEntity>> getScanDirectories() async {
    final rows = await _scanDirectoriesDao.getAllDirectories();
    return rows.map(_dirRowToEntity).toList();
  }

  @override
  Stream<List<ScanDirectoryEntity>> watchScanDirectories() {
    return _scanDirectoriesDao.watchAllDirectories().map(
          (rows) => rows.map(_dirRowToEntity).toList(),
        );
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

  @override
  Future<void> deleteMediaFile(String id, String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    await _mediaDao.deleteMediaRecord(id);
  }
}
