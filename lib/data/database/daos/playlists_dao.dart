import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'playlists_dao.g.dart';

class PlaylistWithItemsInfo {
  final PlaylistRow playlist;
  final int itemCount;
  final String? artworkPath;

  PlaylistWithItemsInfo({
    required this.playlist,
    required this.itemCount,
    this.artworkPath,
  });
}

@DriftAccessor(tables: [Playlists, PlaylistItems, MediaItems])
class PlaylistsDao extends DatabaseAccessor<AppDatabase> with _$PlaylistsDaoMixin {
  PlaylistsDao(super.db);

  /// Watch all playlists with calculated item counts and artwork previews
  Stream<List<PlaylistWithItemsInfo>> watchAllPlaylists() {
    final query = select(playlists).join([
      leftOuterJoin(playlistItems, playlistItems.playlistId.equalsExp(playlists.id)),
      leftOuterJoin(mediaItems, mediaItems.id.equalsExp(playlistItems.mediaId)),
    ])
      ..orderBy([OrderingTerm.desc(playlists.createdAt)]);

    return query.watch().map((rows) {
      final map = <String, PlaylistWithItemsInfo>{};
      for (final row in rows) {
        final playlist = row.readTable(playlists);
        final media = row.readTableOrNull(mediaItems);
        final item = row.readTableOrNull(playlistItems);

        if (!map.containsKey(playlist.id)) {
          map[playlist.id] = PlaylistWithItemsInfo(
            playlist: playlist,
            itemCount: item != null ? 1 : 0,
            artworkPath: media?.artworkPath,
          );
        } else {
          final existing = map[playlist.id]!;
          map[playlist.id] = PlaylistWithItemsInfo(
            playlist: playlist,
            itemCount: existing.itemCount + (item != null ? 1 : 0),
            artworkPath: existing.artworkPath ?? media?.artworkPath,
          );
        }
      }
      return map.values.toList();
    });
  }

  /// Get single playlist by ID
  Future<PlaylistRow?> getPlaylistById(String id) {
    return (select(playlists)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Watch media items in a specific playlist, sorted by sortOrder
  Stream<List<MediaItemRow>> watchPlaylistItems(String playlistId) {
    final query = select(playlistItems).join([
      innerJoin(mediaItems, mediaItems.id.equalsExp(playlistItems.mediaId)),
    ])
      ..where(playlistItems.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(playlistItems.sortOrder)]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(mediaItems)).toList();
    });
  }

  /// Create a new playlist
  Future<void> createPlaylist(PlaylistsCompanion playlist) {
    return into(playlists).insert(playlist);
  }

  /// Rename playlist
  Future<void> renamePlaylist(String id, String newName) {
    return (update(playlists)..where((tbl) => tbl.id.equals(id)))
        .write(PlaylistsCompanion(name: Value(newName)));
  }

  /// Delete playlist and its items (does NOT touch actual media files)
  Future<void> deletePlaylist(String playlistId) {
    return transaction(() async {
      await (delete(playlistItems)..where((tbl) => tbl.playlistId.equals(playlistId))).go();
      await (delete(playlists)..where((tbl) => tbl.id.equals(playlistId))).go();
    });
  }

  /// Add media to playlist with automatic sort order calculation
  Future<void> addMediaToPlaylist(String playlistId, String mediaId) async {
    // Check if item already exists in playlist to avoid duplicates
    final existing = await (select(playlistItems)
          ..where((tbl) => tbl.playlistId.equals(playlistId) & tbl.mediaId.equals(mediaId)))
        .getSingleOrNull();

    if (existing != null) return;

    // Get max sort order
    final maxSortOrderQuery = selectOnly(playlistItems)
      ..addColumns([playlistItems.sortOrder.max()])
      ..where(playlistItems.playlistId.equals(playlistId));
    final maxSortOrder =
        await maxSortOrderQuery.map((row) => row.read(playlistItems.sortOrder.max())).getSingleOrNull() ?? 0;

    await into(playlistItems).insert(
      PlaylistItemsCompanion.insert(
        id: '${playlistId}_$mediaId',
        playlistId: playlistId,
        mediaId: mediaId,
        sortOrder: maxSortOrder + 1,
      ),
    );
  }

  /// Remove media item from playlist (does NOT touch actual media file)
  Future<void> removeMediaFromPlaylist(String playlistId, String mediaId) {
    return (delete(playlistItems)
          ..where((tbl) => tbl.playlistId.equals(playlistId) & tbl.mediaId.equals(mediaId)))
        .go();
  }

  /// Reorder items in playlist by updating sortOrder
  Future<void> reorderPlaylistItems(String playlistId, List<String> mediaIds) async {
    await transaction(() async {
      for (int i = 0; i < mediaIds.length; i++) {
        await (update(playlistItems)
              ..where((tbl) => tbl.playlistId.equals(playlistId) & tbl.mediaId.equals(mediaIds[i])))
            .write(PlaylistItemsCompanion(sortOrder: Value(i)));
      }
    });
  }
}
