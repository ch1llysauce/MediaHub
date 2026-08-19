import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'favorites_dao.g.dart';

@DriftAccessor(tables: [Favorites, MediaItems])
class FavoritesDao extends DatabaseAccessor<AppDatabase> with _$FavoritesDaoMixin {
  FavoritesDao(super.db);

  /// Watch all favorited media items ordered by addition date (newest first)
  Stream<List<MediaItemRow>> watchFavoriteMediaItems() {
    final query = select(favorites).join([
      innerJoin(mediaItems, mediaItems.id.equalsExp(favorites.mediaId)),
    ])
      ..orderBy([OrderingTerm.desc(favorites.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(mediaItems)).toList();
    });
  }

  /// Watch set of favorited media IDs for fast O(1) reactive UI checks
  Stream<Set<String>> watchFavoriteMediaIds() {
    final query = select(favorites);
    return query.watch().map((rows) {
      return rows.map((row) => row.mediaId).toSet();
    });
  }

  /// Check if a specific media item is favorited
  Future<bool> isFavorite(String mediaId) async {
    final row = await (select(favorites)..where((tbl) => tbl.mediaId.equals(mediaId))).getSingleOrNull();
    return row != null;
  }

  /// Toggle favorite status: Add if not present, remove if present
  Future<bool> toggleFavorite(String mediaId) async {
    final existing = await (select(favorites)..where((tbl) => tbl.mediaId.equals(mediaId))).getSingleOrNull();
    if (existing != null) {
      await (delete(favorites)..where((tbl) => tbl.mediaId.equals(mediaId))).go();
      return false; // Now unfavorited
    } else {
      await into(favorites).insert(
        FavoritesCompanion.insert(
          id: 'fav_$mediaId',
          mediaId: mediaId,
          createdAt: DateTime.now(),
        ),
      );
      return true; // Now favorited
    }
  }

  /// Add media item to favorites
  Future<void> addFavorite(String mediaId) async {
    final existing = await (select(favorites)..where((tbl) => tbl.mediaId.equals(mediaId))).getSingleOrNull();
    if (existing == null) {
      await into(favorites).insert(
        FavoritesCompanion.insert(
          id: 'fav_$mediaId',
          mediaId: mediaId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Remove media item from favorites (does NOT delete physical media file)
  Future<void> removeFavorite(String mediaId) {
    return (delete(favorites)..where((tbl) => tbl.mediaId.equals(mediaId))).go();
  }
}
