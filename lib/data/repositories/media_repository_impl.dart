import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:media_kit/media_kit.dart';

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

    // Reset any stuck or previously failed artworks so the new logic can try again.
    await _mediaDao.resetFailedArtworks();

    // Run background duration and artwork extractions sequentially to prevent resource contention
    unawaited(_populateMetadataAndArtworksSequentially());
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
  bool _isPopulating = false;

  Future<void> _populateMetadataAndArtworksSequentially() async {
    if (_isPopulating) return;
    _isPopulating = true;
    try {
      final allMedia = await _mediaDao.getAllMedia();
      
      // OPTIMIZATION: Process audio files first because they are instantly fast (no 500ms delay).
      // This way, thousands of music thumbnails appear instantly instead of queuing behind slow videos.
      final audioMedia = allMedia.where((m) => m.mediaType == 'audio').toList();
      final videoMedia = allMedia.where((m) => m.mediaType == 'video').toList();
      final sortedMedia = [...audioMedia, ...videoMedia];

      for (final media in sortedMedia) {
        final path = media.artworkPath;
        // Treat 'processing' as missing since any leftover 'processing' tags from a previous app session are stuck.
        final isArtworkMissing = path == null || path.isEmpty || path == 'processing' || (path != 'failed' && !(await File(path).exists()));
        final isDurationMissing = media.duration == null || media.duration == 0;

        if (!isArtworkMissing && !isDurationMissing) {
          continue; // Everything is present
        }

        final file = File(media.path);
        if (!await file.exists()) {
          continue;
        }

        // 1. Extract Duration
        if (isDurationMissing) {
          try {
            if (media.mediaType == 'audio') {
              // Pure Dart, incredibly fast for audio
              final metadata = readMetadata(file);
              if (metadata.duration != null && metadata.duration!.inSeconds > 0) {
                await _mediaDao.updateMediaDuration(media.id, metadata.duration!.inSeconds);
              }
            } else if (media.mediaType == 'video') {
              // Use media_kit to extract video duration silently
              final durationSeconds = await _getVideoDuration(file.path);
              if (durationSeconds != null && durationSeconds > 0) {
                await _mediaDao.updateMediaDuration(media.id, durationSeconds);
              } else {
                // Mark as -1 to indicate it failed, so we don't retry forever
                await _mediaDao.updateMediaDuration(media.id, -1);
              }
            }
          } catch (_) {
            // Ignore format errors, but mark as -1 so we don't retry next time
            await _mediaDao.updateMediaDuration(media.id, -1);
          }
        }

        // 2. Extract Artwork (Native plugin, requires throttling)
        if (isArtworkMissing && path != 'failed') {
          try {
            await _mediaDao.updateMediaArtwork(media.id, 'processing');

            final artworkPath = await _artworkService.extractArtwork(
              filePath: media.path,
              mediaId: media.id,
              mediaType: media.mediaType,
            ).timeout(const Duration(seconds: 4), onTimeout: () => null);
            
            if (artworkPath != null) {
              await _mediaDao.updateMediaArtwork(media.id, artworkPath);
            } else {
              await _mediaDao.updateMediaArtwork(media.id, 'failed');
            }

            // Throttling: Protect native file descriptors and UI thread ONLY for videos.
            // Audio thumbnail extraction is pure Dart and very fast.
            if (media.mediaType == 'video') {
              await Future.delayed(const Duration(milliseconds: 500));
            }
          } catch (_) {
            await _mediaDao.updateMediaArtwork(media.id, 'failed');
          }
        }
      }
    } catch (_) {
    } finally {
      _isPopulating = false;
    }
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


  @override
  Future<void> retryMissingArtworks() async {
    // Reset any previously-failed artworks so the extraction loop will try them again.
    await _mediaDao.resetFailedArtworks();
    // Run the full metadata + artwork backfill pass in the background.
    unawaited(_populateMetadataAndArtworksSequentially());
  }

  Future<int?> _getVideoDuration(String path) async {
    // 1. Ultra-fast pure Dart metadata extraction for MP4/M4V/MOV files
    final fastDuration = await _getFastMp4Duration(path);
    if (fastDuration != null && fastDuration > 0) {
      return fastDuration;
    }

    // 2. Fallback to media_kit for MKV, AVI, WebM, etc. (Slow)
    Player? player;
    try {
      player = Player(configuration: const PlayerConfiguration());
      final videoUri = Uri.file(path).toString();
      await player.open(Media(videoUri), play: false);

      final duration = await player.stream.duration
          .firstWhere((d) => d.inSeconds > 0)
          .timeout(const Duration(seconds: 3));

      return duration.inSeconds;
    } catch (_) {
      return null;
    } finally {
      try {
        await player?.dispose();
      } catch (_) {}
    }
  }

  Future<int?> _getFastMp4Duration(String path) async {
    RandomAccessFile? raf;
    try {
      final file = File(path);
      raf = await file.open(mode: FileMode.read);
      final length = await file.length();
      int offset = 0;

      // Only scan first 50MB to avoid hanging on massive non-mp4 files
      final maxScan = length > 50000000 ? 50000000 : length;

      while (offset < maxScan) {
        raf.setPositionSync(offset);
        final header = raf.readSync(8);
        if (header.length < 8) break;

        final byteData = ByteData.view(header.buffer, header.offsetInBytes, header.lengthInBytes);
        int size = byteData.getUint32(0);
        final type = String.fromCharCodes(header.sublist(4, 8));

        int headerSize = 8;
        if (size == 1) {
          final extSize = raf.readSync(8);
          final extData = ByteData.view(extSize.buffer, extSize.offsetInBytes, extSize.lengthInBytes);
          size = extData.getUint64(0);
          headerSize = 16;
        } else if (size == 0) {
          break; // EOF
        }

        if (type == 'moov') {
          offset += headerSize; // Step inside 'moov' box
          continue;
        } else if (type == 'mvhd') {
          final version = raf.readByteSync();
          raf.readSync(3); // skip flags

          int timeScale = 0;
          int duration = 0;

          if (version == 0) {
            final data = raf.readSync(16);
            final bd = ByteData.view(data.buffer, data.offsetInBytes, data.lengthInBytes);
            timeScale = bd.getUint32(8);
            duration = bd.getUint32(12);
          } else if (version == 1) {
            final data = raf.readSync(28);
            final bd = ByteData.view(data.buffer, data.offsetInBytes, data.lengthInBytes);
            timeScale = bd.getUint32(16);
            duration = bd.getUint64(20);
          }

          if (timeScale > 0) {
            return duration ~/ timeScale;
          }
          break;
        } else {
          offset += size; // Skip unknown boxes
        }
      }
    } catch (_) {
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }
    return null;
  }
}
