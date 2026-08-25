import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_player_service.dart';

class MediaHubAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayerService audioService;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;

  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;
  Future<void> Function()? onStopPlayer;
  Future<void> Function()? onToggleFavorite;

  bool _isCurrentFavorite = false;

  MediaHubAudioHandler(this.audioService) {
    _init();
  }

  void updateFavoriteStatus(bool isFavorite) {
    if (_isCurrentFavorite != isFavorite) {
      _isCurrentFavorite = isFavorite;
      _updatePlaybackState();
    }
  }

  void _init() {
    _playerStateSub =
        audioService.playerStateStream.listen((playerState) {
      _updatePlaybackState();
    });

    _positionSub =
        audioService.positionStream.listen((position) {
      final currentState = playbackState.value;

      playbackState.add(
        currentState.copyWith(
          updatePosition: position,
        ),
      );
    });
  }

  void _updatePlaybackState() {
    final playerState = audioService.player.playerState;
    final processingState = switch (playerState.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    final favoriteControl = MediaControl.custom(
      androidIcon: _isCurrentFavorite
          ? 'drawable/ic_action_favorite'
          : 'drawable/ic_action_favorite_border',
      label: 'Favorite',
      name: 'toggleFavorite',
    );

    final closeControl = MediaControl.custom(
      androidIcon: 'drawable/ic_action_close',
      label: 'Close',
      name: 'closePlayer',
    );

    playbackState.add(
      PlaybackState(
        controls: [
          favoriteControl,
          MediaControl.skipToPrevious,
          if (playerState.playing)
            MediaControl.pause
          else
            MediaControl.play,
          MediaControl.skipToNext,
          closeControl,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        processingState: processingState,
        playing: playerState.playing,
        updatePosition: audioService.player.position,
        bufferedPosition: audioService.player.bufferedPosition,
        speed: audioService.player.speed,
      ),
    );
  }

  Future<void> setMedia({
    required String path,
    required MediaItem item,
  }) async {
    mediaItem.add(item);
  }

  @override
  Future<void> play() async {
    await audioService.play();
  }

  @override
  Future<void> pause() async {
    await audioService.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await audioService.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await onSkipToNext?.call();
    await super.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await onSkipToPrevious?.call();
    await super.skipToPrevious();
  }

  @override
  Future<void> stop() async {
    await audioService.stop();
    await onStopPlayer?.call();
    await super.stop();
  }

  @override
  Future<void> setSpeed(double speed) async {
    await audioService.player.setSpeed(speed);
  }

  @override
  Future<void> onTaskRemoved() async {
    await audioService.stop();
    await onStopPlayer?.call();
    await super.onTaskRemoved();
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'toggleFavorite') {
      await onToggleFavorite?.call();
    } else if (name == 'closePlayer') {
      await stop();
    }
    return await super.customAction(name, extras);
  }

  Future<void> disposeHandler() async {
    await _playerStateSub?.cancel();
    await _positionSub?.cancel();
  }
}