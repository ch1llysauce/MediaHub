import 'dart:io';
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'media_dao.g.dart';

@DriftAccessor(tables: [MediaItems])
class MediaDao extends DatabaseAccessor<AppDatabase> with _$MediaDaoMixin {
  MediaDao(super.db);

  /// Fetch all available media items
  Future<List<MediaItemRow>> getAllMedia() {
    return (select(mediaItems)..where((tbl) => tbl.isAvailable.equals(true))).get();
  }

  /// Reactive stream watching all available media items
  Stream<List<MediaItemRow>> watchAllMedia() {
    return (select(mediaItems)..where((tbl) => tbl.isAvailable.equals(true))).watch();
  }

  /// Fetch available media filtered by type ('audio' or 'video')
  Future<List<MediaItemRow>> getMediaByType(String mediaType) {
    return (select(mediaItems)
          ..where((tbl) => tbl.mediaType.equals(mediaType) & tbl.isAvailable.equals(true)))
        .get();
  }

  /// Reactive stream watching media by type
  Stream<List<MediaItemRow>> watchMediaByType(String mediaType) {
    return (select(mediaItems)
          ..where((tbl) => tbl.mediaType.equals(mediaType) & tbl.isAvailable.equals(true)))
        .watch();
  }

  /// Get single media item by ID
  Future<MediaItemRow?> getMediaById(String id) {
    return (select(mediaItems)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get single media item by file path
  Future<MediaItemRow?> getMediaByPath(String path) {
    return (select(mediaItems)..where((tbl) => tbl.path.equals(path))).getSingleOrNull();
  }

  /// Insert or update single media item
  Future<void> upsertMedia(MediaItemsCompanion entity) {
    return into(mediaItems).insertOnConflictUpdate(entity);
  }

  /// Batch upsert multiple media items efficiently
  Future<void> upsertMediaBatch(List<MediaItemsCompanion> entities) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(mediaItems, entities);
    });
  }

  /// Safely reconcile physical existence of files on storage, marking missing files as unavailable
  Future<void> reconcileMissingFiles() async {
    final allMedia = await (select(mediaItems)).get();
    for (final item in allMedia) {
      final exists = File(item.path).existsSync();
      if (item.isAvailable != exists) {
        await (update(mediaItems)..where((tbl) => tbl.id.equals(item.id)))
            .write(MediaItemsCompanion(isAvailable: Value(exists)));
      }
    }
  }

  /// Mark media files not in the scanned list as unavailable (file missing on disk)
  Future<void> markMissingFiles(List<String> scannedPaths) async {
    await (update(mediaItems)..where((tbl) => tbl.path.isNotIn(scannedPaths)))
        .write(const MediaItemsCompanion(isAvailable: Value(false)));
  }

  /// Mark specific file path unavailable
  Future<void> markFileUnavailable(String path) async {
    await (update(mediaItems)..where((tbl) => tbl.path.equals(path)))
        .write(const MediaItemsCompanion(isAvailable: Value(false)));
  }

  /// Permanently delete media record from database (does not delete file on disk)
  Future<int> deleteMediaRecord(String id) {
    return (delete(mediaItems)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Update duration for a specific media item
  Future<void> updateMediaDuration(String id, int durationInSeconds) {
    return (update(mediaItems)..where((tbl) => tbl.id.equals(id)))
        .write(MediaItemsCompanion(duration: Value(durationInSeconds)));
  }

  /// Update artwork path for a specific media item
  Future<void> updateMediaArtwork(String id, String artworkPath) {
    return (update(mediaItems)..where((tbl) => tbl.id.equals(id)))
        .write(MediaItemsCompanion(artworkPath: Value(artworkPath)));
  }

  /// Reset all 'failed' artwork statuses so they can be retried on the next scan
  Future<void> resetFailedArtworks() async {
    await (update(mediaItems)..where((tbl) => tbl.artworkPath.equals('failed')))
        .write(const MediaItemsCompanion(artworkPath: Value(null)));
  }
}
