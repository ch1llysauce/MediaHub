import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/media_dao.dart';
import '../../data/database/daos/scan_directories_dao.dart';
import '../../data/repositories/media_repository_impl.dart';
import '../../domain/entities/media_item_entity.dart';
import '../../domain/repositories/media_repository.dart';
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

/// ScanDirectoriesDao provider
final scanDirectoriesDaoProvider = Provider<ScanDirectoriesDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.scanDirectoriesDao;
});

/// MediaScannerService provider
final mediaScannerServiceProvider = Provider<MediaScannerService>((ref) {
  return MediaScannerService();
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
