import '../entities/media_item_entity.dart';
import '../entities/playlist_entity.dart';

abstract class PlaylistRepository {
  /// Watch all playlists with calculated item counts and artwork previews
  Stream<List<PlaylistEntity>> watchAllPlaylists();

  /// Get single playlist by ID
  Future<PlaylistEntity?> getPlaylistById(String id);

  /// Watch media items in a specific playlist, ordered by sortOrder
  Stream<List<MediaItemEntity>> watchPlaylistItems(String playlistId);

  /// Create a new playlist with given name
  Future<PlaylistEntity> createPlaylist(String name);

  /// Rename an existing playlist
  Future<void> renamePlaylist(String id, String newName);

  /// Delete a playlist and its relationships (NEVER deletes files on disk)
  Future<void> deletePlaylist(String playlistId);

  /// Add a media item to a playlist
  Future<void> addMediaToPlaylist(String playlistId, String mediaId);

  /// Remove a media item from a playlist (NEVER deletes file on disk)
  Future<void> removeMediaFromPlaylist(String playlistId, String mediaId);

  /// Reorder items in a playlist
  Future<void> reorderPlaylistItems(String playlistId, List<String> mediaIds);
}
