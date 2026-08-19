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
}
