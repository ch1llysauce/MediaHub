import '../../domain/entities/media_item_entity.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../database/app_database.dart';
import '../database/daos/favorites_dao.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesDao favoritesDao;

  FavoritesRepositoryImpl({required this.favoritesDao});

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

  @override
  Stream<List<MediaItemEntity>> watchFavoriteMediaItems() {
    return favoritesDao.watchFavoriteMediaItems().map((rows) {
      return rows.map(_rowToEntity).toList();
    });
  }

  @override
  Stream<Set<String>> watchFavoriteMediaIds() {
    return favoritesDao.watchFavoriteMediaIds();
  }

  @override
  Future<bool> isFavorite(String mediaId) {
    return favoritesDao.isFavorite(mediaId);
  }

  @override
  Future<bool> toggleFavorite(String mediaId) {
    return favoritesDao.toggleFavorite(mediaId);
  }

  @override
  Future<void> addFavorite(String mediaId) {
    return favoritesDao.addFavorite(mediaId);
  }

  @override
  Future<void> removeFavorite(String mediaId) {
    return favoritesDao.removeFavorite(mediaId);
  }
}
