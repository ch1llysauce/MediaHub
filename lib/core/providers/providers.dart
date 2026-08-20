import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/downloads_dao.dart';
import '../../data/database/daos/media_dao.dart';
import '../../data/database/daos/playlists_dao.dart';
import '../../data/database/daos/scan_directories_dao.dart';
import '../../data/repositories/download_repository_impl.dart';
import '../../data/repositories/media_repository_impl.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../domain/entities/download_task_entity.dart';
import '../../domain/entities/media_item_entity.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/repositories/media_repository.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../services/audio_player_service.dart';
import '../services/downloader/download_manager.dart';
import '../services/media_scanner_service.dart';

/// Database singleton provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// MediaDao provider
final mediaDaoProvider = Provider<MediaDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.mediaDao;
});

/// PlaylistsDao provider
final playlistsDaoProvider = Provider<PlaylistsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.playlistsDao;
});

/// ScanDirectoriesDao provider
final scanDirectoriesDaoProvider = Provider<ScanDirectoriesDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.scanDirectoriesDao;
});

/// DownloadsDao provider
final downloadsDaoProvider = Provider<DownloadsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.downloadsDao;
});

/// MediaScannerService provider
final mediaScannerServiceProvider = Provider<MediaScannerService>((ref) {
  return MediaScannerService();
});

/// AudioPlayerService provider
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// MediaRepository provider
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final mediaDao = ref.watch(mediaDaoProvider);
  final scanDirectoriesDao = ref.watch(scanDirectoriesDaoProvider);
  final scannerService = ref.watch(mediaScannerServiceProvider);

  return MediaRepositoryImpl(
    mediaDao: mediaDao,
    scanDirectoriesDao: scanDirectoriesDao,
    scannerService: scannerService,
  );
});

/// PlaylistRepository provider
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final playlistsDao = ref.watch(playlistsDaoProvider);
  return PlaylistRepositoryImpl(playlistsDao: playlistsDao);
});

/// DownloadRepository provider
final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  final downloadsDao = ref.watch(downloadsDaoProvider);
  return DownloadRepositoryImpl(downloadsDao);
});

/// DownloadManager provider
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final downloadRepo = ref.watch(downloadRepositoryProvider);
  final mediaRepo = ref.watch(mediaRepositoryProvider);
  return DownloadManager(
    downloadRepository: downloadRepo,
    mediaRepository: mediaRepo,
  );
});

/// Reactive stream of download tasks
final allDownloadsStreamProvider = StreamProvider<List<DownloadTaskEntity>>((ref) {
  final repository = ref.watch(downloadRepositoryProvider);
  return repository.watchAllTasks();
});

/// Reactive stream of all available media items
final allMediaStreamProvider = StreamProvider<List<MediaItemEntity>>((ref) {
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.watchAllMedia();
});

/// Reactive stream of audio tracks
final musicMediaStreamProvider = StreamProvider<List<MediaItemEntity>>((ref) {
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.watchMediaByType('audio');
});

/// Reactive stream of video clips
final videoMediaStreamProvider = StreamProvider<List<MediaItemEntity>>((ref) {
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.watchMediaByType('video');
});

/// Reactive stream of all playlists
final allPlaylistsStreamProvider = StreamProvider((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  return repository.watchAllPlaylists();
});

/// Reactive stream of media items in a specific playlist
final playlistItemsStreamProvider =
    StreamProvider.family<List<MediaItemEntity>, String>((ref, playlistId) {
  final repository = ref.watch(playlistRepositoryProvider);
  return repository.watchPlaylistItems(playlistId);
});
