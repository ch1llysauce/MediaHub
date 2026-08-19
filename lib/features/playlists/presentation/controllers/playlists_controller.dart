import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/playlist_entity.dart';
import '../../../../domain/repositories/playlist_repository.dart';

final playlistsControllerProvider =
    AsyncNotifierProvider<PlaylistsController, List<PlaylistEntity>>(() {
  return PlaylistsController();
});

class PlaylistsController extends AsyncNotifier<List<PlaylistEntity>> {
  late final PlaylistRepository _repository;

  @override
  Future<List<PlaylistEntity>> build() async {
    _repository = ref.watch(playlistRepositoryProvider);
    final playlistsStream = _repository.watchAllPlaylists();
    return playlistsStream.first;
  }

  /// Create a new playlist
  Future<PlaylistEntity?> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    state = const AsyncValue.loading();
    try {
      final newPlaylist = await _repository.createPlaylist(trimmed);
      ref.invalidateSelf();
      return newPlaylist;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Rename an existing playlist
  Future<bool> renamePlaylist(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    try {
      await _repository.renamePlaylist(id, trimmed);
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete playlist (does NOT delete media files on disk)
  Future<bool> deletePlaylist(String id) async {
    try {
      await _repository.deletePlaylist(id);
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Add media item to a playlist
  Future<bool> addMediaToPlaylist(String playlistId, String mediaId) async {
    try {
      await _repository.addMediaToPlaylist(playlistId, mediaId);
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
