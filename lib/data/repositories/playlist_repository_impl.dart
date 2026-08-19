import '../../domain/entities/media_item_entity.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../database/app_database.dart';
import '../database/daos/playlists_dao.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistsDao _playlistsDao;

  PlaylistRepositoryImpl({
    required PlaylistsDao playlistsDao,
  }) : _playlistsDao = playlistsDao;

  MediaItemEntity _mediaRowToEntity(MediaItemRow row) {
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

  PlaylistEntity _infoToEntity(PlaylistWithItemsInfo info) {
    return PlaylistEntity(
      id: info.playlist.id,
      name: info.playlist.name,
      createdAt: info.playlist.createdAt,
      itemCount: info.itemCount,
      artworkPath: info.artworkPath,
    );
  }

  @override
  Stream<List<PlaylistEntity>> watchAllPlaylists() {
    return _playlistsDao.watchAllPlaylists().map(
          (list) => list.map(_infoToEntity).toList(),
        );
  }

  @override
  Future<PlaylistEntity?> getPlaylistById(String id) async {
    final row = await _playlistsDao.getPlaylistById(id);
    if (row == null) return null;
    return PlaylistEntity(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
      itemCount: 0,
    );
  }

  @override
  Stream<List<MediaItemEntity>> watchPlaylistItems(String playlistId) {
    return _playlistsDao.watchPlaylistItems(playlistId).map(
          (rows) => rows.map(_mediaRowToEntity).toList(),
        );
  }

  @override
  Future<PlaylistEntity> createPlaylist(String name) async {
    final id = 'playlist_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final companion = PlaylistsCompanion.insert(
      id: id,
      name: name,
      createdAt: now,
    );
    await _playlistsDao.createPlaylist(companion);
    return PlaylistEntity(
      id: id,
      name: name,
      createdAt: now,
      itemCount: 0,
    );
  }

  @override
  Future<void> renamePlaylist(String id, String newName) {
    return _playlistsDao.renamePlaylist(id, newName);
  }

  @override
  Future<void> deletePlaylist(String playlistId) {
    return _playlistsDao.deletePlaylist(playlistId);
  }

  @override
  Future<void> addMediaToPlaylist(String playlistId, String mediaId) {
    return _playlistsDao.addMediaToPlaylist(playlistId, mediaId);
  }

  @override
  Future<void> removeMediaFromPlaylist(String playlistId, String mediaId) {
    return _playlistsDao.removeMediaFromPlaylist(playlistId, mediaId);
  }

  @override
  Future<void> reorderPlaylistItems(String playlistId, List<String> mediaIds) {
    return _playlistsDao.reorderPlaylistItems(playlistId, mediaIds);
  }
}
