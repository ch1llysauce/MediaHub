import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart' as audio_service;

import '../../../../core/providers/providers.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/services/mediahub_audio_handler.dart';
import '../../../../domain/entities/media_item_entity.dart';
import '../../../../domain/repositories/history_repository.dart';
import '../../../../domain/repositories/media_repository.dart';
import '../../../../domain/repositories/playlist_repository.dart';
import '../../../history/presentation/controllers/history_controller.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';


enum PlayerRepeatMode { off, all, one }

class MusicPlayerState {
  final MediaItemEntity? activeItem;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final List<MediaItemEntity> queue;
  final int currentIndex;
  final bool isShuffle;
  final List<int> shuffledIndices;
  final PlayerRepeatMode repeatMode;
  final String? activePlaylistId;
  final bool showUpNextPreview;
  final MediaItemEntity? nextUpItem;

  const MusicPlayerState({
    this.activeItem,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.isShuffle = false,
    this.shuffledIndices = const [],
    this.repeatMode = PlayerRepeatMode.off,
    this.activePlaylistId,
    this.showUpNextPreview = false,
    this.nextUpItem,
  });

  bool get hasActiveItem => activeItem != null;

  MusicPlayerState copyWith({
    MediaItemEntity? activeItem,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    List<MediaItemEntity>? queue,
    int? currentIndex,
    bool? isShuffle,
    List<int>? shuffledIndices,
    PlayerRepeatMode? repeatMode,
    String? activePlaylistId,
    bool clearActivePlaylistId = false,
    bool? showUpNextPreview,
    MediaItemEntity? nextUpItem,
    bool clearNextUpItem = false,
  }) {
    return MusicPlayerState(
      activeItem: activeItem ?? this.activeItem,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffle: isShuffle ?? this.isShuffle,
      shuffledIndices: shuffledIndices ?? this.shuffledIndices,
      repeatMode: repeatMode ?? this.repeatMode,
      activePlaylistId: clearActivePlaylistId ? null : (activePlaylistId ?? this.activePlaylistId),
      showUpNextPreview: showUpNextPreview ?? this.showUpNextPreview,
      nextUpItem: clearNextUpItem ? null : (nextUpItem ?? this.nextUpItem),
    );
  }
}

class MusicPlayerController extends StateNotifier<MusicPlayerState> {
  final AudioPlayerService _audioService;
  final MediaHubAudioHandler? _audioHandler;
  final PlaylistRepository? _playlistRepository;
  final HistoryRepository? _historyRepository;
  final MediaRepository? _mediaRepository;
  StreamSubscription<PlayerState>? _playerStateSub;
StreamSubscription<Duration>? _positionSub;
StreamSubscription<Duration?>? _durationSub;
StreamSubscription<List<MediaItemEntity>>? _playlistSub;

  MusicPlayerController(
    this._audioService,
    [
    this._playlistRepository,
    this._historyRepository,
    this._mediaRepository,
    this._audioHandler,
  ]) : super(const MusicPlayerState()) {
    _setupAudioHandler();
    _listenToStreams();
  }

  void _setupAudioHandler() {
    if (_audioHandler != null) {
      _audioHandler.onSkipToNext = skipToNext;
      _audioHandler.onSkipToPrevious = skipToPrevious;
      _audioHandler.onStopPlayer = closePlayer;
    }
  }

  bool _isUpNextDismissed = false;

  void dismissUpNextPreview() {
    _isUpNextDismissed = true;
    state = state.copyWith(
      showUpNextPreview: false,
      clearNextUpItem: true,
    );
  }

  void _listenToStreams() {
    _playerStateSub = _audioService.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      final isBuffering = processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading;

      state = state.copyWith(
        isPlaying: isPlaying,
        isBuffering: isBuffering,
      );

      if (processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    _positionSub = _audioService.positionStream.listen((pos) {
      MediaItemEntity? nextUp;
      bool showPreview = false;

      final total = state.duration;
      if (total.inSeconds > 2 && state.repeatMode != PlayerRepeatMode.one && !_isUpNextDismissed) {
        final remaining = total - pos;
        if (remaining.inSeconds <= 10 && remaining.inSeconds > 0) {
          nextUp = peekNextItem();
          showPreview = nextUp != null;
        }
      }

      state = state.copyWith(
        position: pos,
        showUpNextPreview: showPreview,
        nextUpItem: nextUp,
        clearNextUpItem: !showPreview,
      );
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
        final activeId = state.activeItem?.id;
        if (activeId != null && dur.inSeconds > 0) {
          _mediaRepository?.updateMediaDuration(activeId, dur.inSeconds);
        }
      }
    });
  }

  MediaItemEntity? peekNextItem() {
    if (state.queue.isEmpty) return null;

    int nextIndex;
    List<int> currentShuffled = state.shuffledIndices;

    if (state.isShuffle && state.queue.length > 1) {
      if (currentShuffled.length != state.queue.length) {
        currentShuffled = _generateShuffledIndices(state.queue.length, state.currentIndex);
      }
      final currentPos = currentShuffled.indexOf(state.currentIndex);
      var nextPos = (currentPos >= 0) ? currentPos + 1 : 0;
      if (nextPos >= currentShuffled.length) {
        if (state.repeatMode == PlayerRepeatMode.all) {
          nextPos = 0;
        } else {
          return null;
        }
      }
      nextIndex = currentShuffled[nextPos];
    } else {
      nextIndex = state.currentIndex + 1;
      if (nextIndex >= state.queue.length) {
        if (state.repeatMode == PlayerRepeatMode.all) {
          nextIndex = 0;
        } else {
          return null;
        }
      }
    }

    if (nextIndex >= 0 && nextIndex < state.queue.length) {
      return state.queue[nextIndex];
    }
    return null;
  }

  bool _isNavigatingTrack = false;

  Future<void> _onTrackCompleted() async {
    if (_isNavigatingTrack) return;
    _isNavigatingTrack = true;
    try {
      if (state.repeatMode == PlayerRepeatMode.one) {
        await seek(Duration.zero);
        await _audioService.play();
        return;
      }

      await skipToNext(isAutoNext: true);
    } finally {
      _isNavigatingTrack = false;
    }
  }

  List<int> _generateShuffledIndices(int length, int startIndex) {
    if (length <= 0) return const [];
    final indices = List<int>.generate(length, (i) => i);
    indices.remove(startIndex);
    indices.shuffle(math.Random());
    return [startIndex, ...indices];
  }

  void _subscribeToPlaylist(String playlistId) {
    if (_playlistRepository == null) return;

    _playlistSub?.cancel();
    _playlistSub = _playlistRepository.watchPlaylistItems(playlistId).listen((newItems) {
      if (newItems.isEmpty) return;

      final activeId = state.activeItem?.id;
      final newIndex = activeId != null
          ? newItems.indexWhere((element) => element.id == activeId)
          : -1;
      final targetIndex = newIndex >= 0 ? newIndex : 0;

      List<int> newShuffled = state.shuffledIndices;
      if (state.isShuffle) {
        if (state.shuffledIndices.length != newItems.length || !state.shuffledIndices.contains(targetIndex)) {
          newShuffled = _generateShuffledIndices(newItems.length, targetIndex);
        }
      } else {
        newShuffled = const [];
      }

      state = state.copyWith(
        queue: newItems,
        currentIndex: targetIndex,
        shuffledIndices: newShuffled,
      );
    });
  }

  Future<void> shufflePlay(
    List<MediaItemEntity> items, {
    String? playlistId,
    MediaItemEntity? startItem,
  }) async {
    if (items.isEmpty) return;

    final selectedItem = startItem ?? items[math.Random().nextInt(items.length)];
    await playItem(
      selectedItem,
      queue: items,
      playlistId: playlistId,
      isShuffle: true,
    );
  }

  Future<void> playItem(
    MediaItemEntity item, {
    List<MediaItemEntity>? queue,
    String? playlistId,
    bool? isShuffle,
  }) async {
    final newQueue = queue ?? [item];
    final index = newQueue.indexWhere((element) => element.id == item.id);
    final targetIndex = index >= 0 ? index : 0;

    final shouldShuffle = isShuffle ?? state.isShuffle;

    if (playlistId != null && playlistId != state.activePlaylistId) {
      _subscribeToPlaylist(playlistId);
    } else if (playlistId == null && state.activePlaylistId != null) {
      _playlistSub?.cancel();
      _playlistSub = null;
    }

    List<int> newShuffled = state.shuffledIndices;
    if (shouldShuffle) {
      final queueUnchanged = state.shuffledIndices.length == newQueue.length &&
          state.shuffledIndices.contains(targetIndex);
      if (isShuffle != null || !queueUnchanged) {
        newShuffled = _generateShuffledIndices(newQueue.length, targetIndex);
      }
    } else {
      newShuffled = const [];
    }

    final snapshotIndex = targetIndex;
    final isSameItem = state.activeItem?.id == item.id;
    final runtimePos = isSameItem ? state.position.inSeconds : 0;

    // Update state synchronously to prevent concurrent/race conditions!
    state = state.copyWith(
      activeItem: item,
      queue: newQueue,
      currentIndex: snapshotIndex,
      isShuffle: shouldShuffle,
      shuffledIndices: newShuffled,
      position: Duration(seconds: runtimePos),
      duration: Duration(seconds: item.duration ?? 0),
      activePlaylistId: playlistId,
      clearActivePlaylistId: playlistId == null,
    );

    // Save/check history asynchronously
    final savedPos = await _historyRepository?.getPlaybackPosition(item.id) ?? 0;

    if (state.activeItem?.id != item.id) return; // Guard!

    final effectiveSavedPos = runtimePos > savedPos ? runtimePos : savedPos;
    if (effectiveSavedPos > 0) {
      state = state.copyWith(
        position: Duration(seconds: effectiveSavedPos),
      );
    }

    _historyRepository?.recordPlayback(item.id, playbackPosition: savedPos > 0 ? savedPos : null);

    if (item.mediaType == 'audio') {
      try {
        if (_audioHandler != null) {
          await _audioHandler.setMedia(
            path: item.path,
            item: audio_service.MediaItem(
              id: item.id,
              title: item.title,
              artist: item.artist ?? 'Unknown Artist',
              album: item.album,
              duration: item.duration != null
                  ? Duration(seconds: item.duration!)
                  : null,
              artUri: item.artworkPath != null
                  ? Uri.file(item.artworkPath!)
                  : null,
            ),
          );
        }

        if (state.activeItem?.id != item.id) return; // Guard!

        await _audioService.setFilePath(item.path);

        if (state.activeItem?.id != item.id) return; // Guard!

        await _audioService.player.setVolume(1.0);
        await _audioService.seek(Duration.zero);

        if (state.activeItem?.id != item.id) return; // Guard!

        await _audioService.play();
      } catch (_) {
        if (state.activeItem?.id == item.id) {
          state = state.copyWith(isPlaying: false);
        }
      }
    } else {
      try {
        await _audioService.stop();
        await _audioHandler?.stop();
      } catch (_) {}
    }
  }

  Future<void> pauseAudio() async {
    try {
      await _audioService.stop();
      await _audioHandler?.stop();
    } catch (_) {}
    state = state.copyWith(isPlaying: false);
  }

  Future<void> togglePlayPause() async {
    if (state.activeItem == null) return;

    if (state.activeItem?.mediaType == 'video') {
      return;
    }

    if (state.isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.play();
    }
  }

  Future<void> closePlayer() async {
    final activeId = state.activeItem?.id;
    if (activeId != null) {
      await _historyRepository?.recordPlayback(activeId, playbackPosition: 0);
    }
    await _playlistSub?.cancel();
    _playlistSub = null;
    await _audioService.pause();
    state = const MusicPlayerState();
  }

  void updatePosition(Duration position) {
    state = state.copyWith(position: position);
  }

  Future<void> seek(Duration position) async {
    if (state.activeItem?.mediaType == 'audio') {
      await _audioService.seek(position);
    }
    state = state.copyWith(position: position);
  }

  Future<void> seekRelative(int seconds) async {
    final currentSec = state.position.inSeconds;
    final maxSec = state.duration.inSeconds;
    final targetSec = (currentSec + seconds).clamp(0, maxSec > 0 ? maxSec : 999999);
    await seek(Duration(seconds: targetSec));
  }

  Future<void> skipToNext({bool isAutoNext = false}) async {
    _isUpNextDismissed = false;
    if (state.queue.isEmpty) return;

    int nextIndex;
    List<int> currentShuffled = state.shuffledIndices;

    if (state.isShuffle && state.queue.length > 1) {
      if (currentShuffled.length != state.queue.length) {
        currentShuffled = _generateShuffledIndices(state.queue.length, state.currentIndex);
        state = state.copyWith(shuffledIndices: currentShuffled);
      }

      final currentPos = currentShuffled.indexOf(state.currentIndex);
      var nextPos = (currentPos >= 0) ? currentPos + 1 : 0;

      if (nextPos >= currentShuffled.length) {
        if (state.repeatMode == PlayerRepeatMode.all) {
          currentShuffled = _generateShuffledIndices(state.queue.length, 0);
          state = state.copyWith(shuffledIndices: currentShuffled);
          nextPos = 0;
        } else {
          await _audioService.pause();
          await _audioService.seek(Duration.zero);
          state = state.copyWith(
            isPlaying: false,
            position: Duration.zero,
            showUpNextPreview: false,
            clearNextUpItem: true,
          );
          return;
        }
      }

      nextIndex = currentShuffled[nextPos];
    } else {
      nextIndex = state.currentIndex + 1;
      if (nextIndex >= state.queue.length) {
        if (state.repeatMode == PlayerRepeatMode.all) {
          nextIndex = 0;
        } else {
          await _audioService.pause();
          await _audioService.seek(Duration.zero);
          state = state.copyWith(
            isPlaying: false,
            position: Duration.zero,
            showUpNextPreview: false,
            clearNextUpItem: true,
          );
          return;
        }
      }
    }

    final nextItem = state.queue[nextIndex];
    await playItem(
      nextItem,
      queue: state.queue,
      playlistId: state.activePlaylistId,
    );
  }

  Future<void> skipToPrevious() async {
    if (state.queue.isEmpty) return;

    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int prevIndex;
    if (state.isShuffle && state.queue.length > 1) {
      List<int> currentShuffled = state.shuffledIndices;
      if (currentShuffled.length != state.queue.length) {
        currentShuffled = _generateShuffledIndices(state.queue.length, state.currentIndex);
      }

      final currentPos = currentShuffled.indexOf(state.currentIndex);
      final prevPos = (currentPos > 0) ? currentPos - 1 : currentShuffled.length - 1;
      prevIndex = currentShuffled[prevPos];
    } else {
      prevIndex = state.currentIndex - 1;
      if (prevIndex < 0) {
        prevIndex = state.queue.length - 1;
      }
    }

    final prevItem = state.queue[prevIndex];
    await playItem(
      prevItem,
      queue: state.queue,
      playlistId: state.activePlaylistId,
    );
  }

  void toggleShuffle() {
    final newShuffle = !state.isShuffle;
    List<int> shuffled = const [];
    if (newShuffle && state.queue.isNotEmpty) {
      shuffled = _generateShuffledIndices(state.queue.length, state.currentIndex >= 0 ? state.currentIndex : 0);
    }
    state = state.copyWith(
      isShuffle: newShuffle,
      shuffledIndices: shuffled,
    );
  }

  void toggleRepeat() {
    final nextMode = PlayerRepeatMode.values[
        (state.repeatMode.index + 1) % PlayerRepeatMode.values.length];
    state = state.copyWith(repeatMode: nextMode);
  }

  Future<void> playVideoAsAudio(MediaItemEntity item, {Duration? position}) async {
    try {
      if (_audioHandler != null) {
        await _audioHandler.setMedia(
          path: item.path,
          item: audio_service.MediaItem(
            id: item.id,
            title: item.title,
            artist: item.artist ?? 'Video File',
            album: item.album,
            duration: item.duration != null
                ? Duration(seconds: item.duration!)
                : null,
            artUri: item.artworkPath != null
                ? Uri.file(item.artworkPath!)
                : null,
          ),
        );
      }

      await _audioService.setFilePath(item.path);
      await _audioService.player.setVolume(1.0);
      if (position != null) {
        await _audioService.seek(position);
      } else {
        await _audioService.seek(Duration.zero);
      }
      await _audioService.play();

      state = state.copyWith(
        activeItem: item,
        isPlaying: true,
        position: position ?? Duration.zero,
        duration: Duration(seconds: item.duration ?? 0),
      );
    } catch (_) {
      state = state.copyWith(isPlaying: false);
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playlistSub?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<MusicPlayerController, MusicPlayerState>
    musicPlayerControllerProvider =
    StateNotifierProvider<MusicPlayerController, MusicPlayerState>((ref) {
  final audioService = ref.watch(audioPlayerServiceProvider);
  final audioHandler = ref.watch(audioHandlerProvider);
  final playlistRepo = ref.watch(playlistRepositoryProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);
  final mediaRepo = ref.watch(mediaRepositoryProvider);
  
  final controller = MusicPlayerController(
    audioService,
    playlistRepo,
    historyRepo,
    mediaRepo,
    audioHandler,
  );

  // Set up the favorite toggler callback
  audioHandler.onToggleFavorite = () async {
    final activeItem = controller.state.activeItem;
    if (activeItem != null) {
      await ref.read(favoritesControllerProvider).toggleFavorite(activeItem.id);
    }
  };

  // Sync favorite status of the active item to the audio handler
  ref.listen<AsyncValue<Set<String>>>(favoriteMediaIdsStreamProvider, (prev, next) {
    final activeItem = controller.state.activeItem;
    if (activeItem != null) {
      final isFav = next.value?.contains(activeItem.id) ?? false;
      audioHandler.updateFavoriteStatus(isFav);
    } else {
      audioHandler.updateFavoriteStatus(false);
    }
  });

  // Sync favorite status when the active item itself changes
  final listener = controller.addListener((state) {
    final activeItem = state.activeItem;
    if (activeItem != null) {
      final favoriteIds = ref.read(favoriteMediaIdsStreamProvider).value;
      final isFav = favoriteIds?.contains(activeItem.id) ?? false;
      audioHandler.updateFavoriteStatus(isFav);
    } else {
      audioHandler.updateFavoriteStatus(false);
    }
  });
  ref.onDispose(listener);

  // Initial sync on creation
  final initialFavorites = ref.read(favoriteMediaIdsStreamProvider).value;
  final initialActiveItem = controller.state.activeItem;
  if (initialActiveItem != null && initialFavorites != null) {
    audioHandler.updateFavoriteStatus(initialFavorites.contains(initialActiveItem.id));
  }

  return controller;
});
