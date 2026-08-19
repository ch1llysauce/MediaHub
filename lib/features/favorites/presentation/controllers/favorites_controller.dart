import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../data/database/daos/favorites_dao.dart';
import '../../../../data/repositories/favorites_repository_impl.dart';
import '../../../../domain/entities/media_item_entity.dart';
import '../../../../domain/repositories/favorites_repository.dart';

/// FavoritesDao provider
final favoritesDaoProvider = Provider<FavoritesDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.favoritesDao;
});

/// FavoritesRepository provider
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final dao = ref.watch(favoritesDaoProvider);
  return FavoritesRepositoryImpl(favoritesDao: dao);
});

/// Stream of favorited media items
final favoriteMediaItemsStreamProvider = StreamProvider<List<MediaItemEntity>>((ref) {
  final repository = ref.watch(favoritesRepositoryProvider);
  return repository.watchFavoriteMediaItems();
});

/// Stream of `Set<String>` containing favorited media item IDs for fast O(1) checks
final favoriteMediaIdsStreamProvider = StreamProvider<Set<String>>((ref) {
  final repository = ref.watch(favoritesRepositoryProvider);
  return repository.watchFavoriteMediaIds();
});

class FavoritesController {
  final FavoritesRepository _repository;

  FavoritesController(this._repository);

  Future<bool> toggleFavorite(String mediaId) async {
    return await _repository.toggleFavorite(mediaId);
  }

  Future<void> removeFavorite(String mediaId) async {
    await _repository.removeFavorite(mediaId);
  }
}

final favoritesControllerProvider = Provider<FavoritesController>((ref) {
  final repository = ref.watch(favoritesRepositoryProvider);
  return FavoritesController(repository);
});
