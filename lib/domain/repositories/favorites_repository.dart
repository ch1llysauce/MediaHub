import '../entities/media_item_entity.dart';

abstract class FavoritesRepository {
  Stream<List<MediaItemEntity>> watchFavoriteMediaItems();
  Stream<Set<String>> watchFavoriteMediaIds();
  Future<bool> isFavorite(String mediaId);
  Future<bool> toggleFavorite(String mediaId);
  Future<void> addFavorite(String mediaId);
  Future<void> removeFavorite(String mediaId);
}
