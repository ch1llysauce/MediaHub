import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/media_item_entity.dart';
import '../../../../domain/repositories/media_repository.dart';
import '../../../../domain/repositories/playlist_repository.dart';

final playlistDetailControllerProvider = AsyncNotifierProvider.family<
    PlaylistDetailController, List<MediaItemEntity>, String>(() {
  return PlaylistDetailController();
});

class PlaylistDetailController
    extends FamilyAsyncNotifier<List<MediaItemEntity>, String> {
  PlaylistRepository get _repository => ref.read(playlistRepositoryProvider);
  MediaRepository get _mediaRepository => ref.read(mediaRepositoryProvider);
  StreamSubscription<List<MediaItemEntity>>? _subscription;
  bool _isProbing = false;

  @override
  Future<List<MediaItemEntity>> build(String arg) async {
    final repository = ref.watch(playlistRepositoryProvider);
    final stream = repository.watchPlaylistItems(arg);

    _subscription?.cancel();
    _subscription = stream.listen((items) {
      state = AsyncValue.data(items);
      _probeMissingDurations(items);
    });
    ref.onDispose(() => _subscription?.cancel());

    final initialItems = await stream.first;
    _probeMissingDurations(initialItems);
    return initialItems;
  }

  void _probeMissingDurations(List<MediaItemEntity> items) async {
    if (_isProbing) return;
    final missing = items.where((e) => e.duration == null || e.duration == 0).toList();
    if (missing.isEmpty) return;

    _isProbing = true;
    for (final item in missing) {
      final player = AudioPlayer();
      try {
        final dur = await player.setFilePath(item.path);
        if (dur != null && dur.inSeconds > 0) {
          await _mediaRepository.updateMediaDuration(item.id, dur.inSeconds);
        }
      } catch (_) {
        // Ignore unreadable files safely
      } finally {
        await player.dispose();
      }
    }
    _isProbing = false;
  }

  /// Remove track from playlist (NEVER deletes file on disk)
  Future<bool> removeTrack(String mediaId) async {
    try {
      final currentList = state.value;
      if (currentList != null) {
        state = AsyncValue.data(
          currentList.where((item) => item.id != mediaId).toList(),
        );
      }
      await _repository.removeMediaFromPlaylist(arg, mediaId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Reorder tracks in playlist
  Future<void> reorderTracks(int oldIndex, int newIndex) async {
    final currentList = state.value;
    if (currentList == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final items = List<MediaItemEntity>.from(currentList);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Optimistically update state
    state = AsyncValue.data(items);

    try {
      final mediaIds = items.map((e) => e.id).toList();
      await _repository.reorderPlaylistItems(arg, mediaIds);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
