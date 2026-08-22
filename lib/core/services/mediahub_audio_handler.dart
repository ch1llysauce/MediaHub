import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_player_service.dart';

class MediaHubAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayerService audioService;
  final PlayerNotifier playerNotifier;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;

  MediaHubAudioHandler(this.audioService, this.playerNotifier) {
    _init();
  }

@override
  Future<void> skipToNext() async {
    await playerNotifier.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await playerNotifier.skipToPrevious();
  }

  void _init() {
    _playerStateSub =
        audioService.playerStateStream.listen((playerState) {
      final processingState = switch (playerState.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };

      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (playerState.playing)
              MediaControl.pause
            else
              MediaControl.play,
              MediaControl.stop,
            MediaControl.skipToNext,
          ],
          androidCompactActionIndices: const [0, 1, 3],
          processingState: processingState,
          playing: playerState.playing,
          updatePosition: audioService.player.position,
          bufferedPosition: audioService.player.bufferedPosition,
          speed: audioService.player.speed,
        ),
      );
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

  Future<void> setMedia({
    required String path,
    required MediaItem item,
  }) async {
    mediaItem.add(item);

    await audioService.setFilePath(path);
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
  Future<void> stop() async {
    await audioService.stop();
    await super.stop();
  }

  @override
  Future<void> setSpeed(double speed) async {
    await audioService.player.setSpeed(speed);
  }

  @override
  Future<void> onTaskRemoved() async {
    await audioService.stop();
    await super.onTaskRemoved();
  }

  Future<void> disposeHandler() async {
    await _playerStateSub?.cancel();
    await _positionSub?.cancel();
  }
}