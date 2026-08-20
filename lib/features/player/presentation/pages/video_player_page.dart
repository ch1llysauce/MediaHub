import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/media_item_entity.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/up_next_banner_widget.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';
import '../../../history/presentation/controllers/history_controller.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  final MediaItemEntity item;
  final List<MediaItemEntity>? playlist;

  /// Whether a VideoPlayerPage is currently mounted / visible.
  /// Used by MiniPlayerWidget to avoid pushing duplicate pages.
  static bool isActive = false;

  const VideoPlayerPage({
    super.key,
    required this.item,
    this.playlist,
  });

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  late final Player _player;
  late final VideoController _videoController;

  late MediaItemEntity _currentItem;
  late List<MediaItemEntity> _playlist;
  late int _currentIndex;

  bool _isPlaying = true;
  bool _isMuted = false;
  bool _isFullscreen = false;
  bool _autoPlayNext = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _showControls = true;
  bool _isUpNextDismissed = false;
  bool _wasControlsVisibleOnPointerDown = true;
  bool _showRewindOverlay = false;
  bool _showForwardOverlay = false;
  bool _isSeekingToHistory = false;
  bool _isCompleted = false;
  int _lastKnownValidPosition = 0;
  int _targetSeekPosition = 0;
  int _seekAccumulatedSeconds = 0;
  Timer? _controlsTimer;
  Timer? _seekOverlayTimer;

  static const Duration _autoHideDuration = Duration(seconds: 3, milliseconds: 500);

  @override
  void initState() {
    super.initState();
    VideoPlayerPage.isActive = true;

    _currentItem = widget.item;
    _playlist = widget.playlist ?? [_currentItem];
    _currentIndex = _playlist.indexWhere((e) => e.id == _currentItem.id);
    if (_currentIndex < 0) _currentIndex = 0;

    ref.read(musicPlayerControllerProvider.notifier).pauseAudio();

    _player = Player(
      configuration: const PlayerConfiguration(
        logLevel: MPVLogLevel.debug,
      ),
    );
    _player.stream.log.listen((event) {
      debugPrint("[media_kit] ${event.prefix}: ${event.text}");
    });
    Future.microtask(() async {
      try {
        if (_player.platform is NativePlayer) {
          final nativePlayer = _player.platform as NativePlayer;
          await nativePlayer.setProperty('ao', 'audiotrack,opensles');
        }
      } catch (e) {
        debugPrint("Error setting ao property: $e");
      }
    });
    _videoController = VideoController(_player);

    _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    _player.stream.position.listen((pos) {
      if (!mounted) return;

      // Once the video has completed, ignore all further position events
      // to prevent overwriting the saved position-0 with stale end-values
      if (_isCompleted) return;

      // While seeking to a saved position, block ALL position updates
      // to prevent mpv's zero-flush events from corrupting state
      if (_isSeekingToHistory) return;

      // After seeking, if mpv sends a 0-position event but we have a
      // known valid position, re-seek instead of accepting the zero
      if (_targetSeekPosition > 1 && pos.inSeconds < 2) {
        _player.seek(Duration(seconds: _targetSeekPosition));
        return;
      }

      // Once we get a real position near our target, clear the target lock
      if (_targetSeekPosition > 1 && pos.inSeconds >= _targetSeekPosition - 1) {
        _targetSeekPosition = 0;
      }

      if (pos.inSeconds > 1) {
        _lastKnownValidPosition = pos.inSeconds;
        ref.read(musicPlayerControllerProvider.notifier).updatePosition(pos);
        if (pos.inSeconds % 5 == 0) {
          ref.read(historyControllerProvider).recordPlayback(
            _currentItem.id,
            playbackPosition: pos.inSeconds,
          );
        }
      }
      setState(() => _position = pos);
    });

    _player.stream.duration.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
        if (dur.inSeconds > 0) {
          ref.read(mediaRepositoryProvider).updateMediaDuration(_currentItem.id, dur.inSeconds);
        }
      }
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        _isCompleted = true;
        // Record position 0 so re-opening starts from the beginning
        ref.read(historyControllerProvider).recordPlayback(
          _currentItem.id,
          playbackPosition: 0,
        );
        ref.read(musicPlayerControllerProvider.notifier).updatePosition(Duration.zero);
        if (_autoPlayNext) {
          _skipToNext();
        }
      }
    });

    _playCurrentMedia();
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (_showControls) {
      _controlsTimer = Timer(_autoHideDuration, () {
        if (mounted) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _wasControlsVisibleOnPointerDown = _showControls;
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _resetControlsTimer();
  }

  void _onVideoTap() {
    if (_wasControlsVisibleOnPointerDown) {
      setState(() => _showControls = false);
      _controlsTimer?.cancel();
    }
  }

  Future<void> _playCurrentMedia() async {
    _isCompleted = false;
    _lastKnownValidPosition = 0;
    final historyCtrl = ref.read(historyControllerProvider);
    final dbSavedPos = await historyCtrl.getPlaybackPosition(_currentItem.id);
    final runtimePos = ref.read(musicPlayerControllerProvider).position.inSeconds;

    int savedPos = runtimePos > dbSavedPos ? runtimePos : dbSavedPos;

    // If the saved position is near the end of the video (within 5 seconds),
    // the video was previously completed — start from the beginning instead.
    // Use metadata duration first, but also check actual player duration as
    // fallback since metadata can be inaccurate or missing.
    final mediaDuration = _currentItem.duration ?? 0;
    final playerDuration = _duration.inSeconds;
    final effectiveDuration = mediaDuration > 0 ? mediaDuration : playerDuration;
    if (effectiveDuration > 0 && savedPos > 0 && (effectiveDuration - savedPos) <= 5) {
      savedPos = 0;
      // Clear the stale position from history so future plays also start fresh
      historyCtrl.recordPlayback(_currentItem.id, playbackPosition: 0);
      ref.read(musicPlayerControllerProvider.notifier).updatePosition(Duration.zero);
    }

    if (savedPos > 1 && mounted) {
      _lastKnownValidPosition = savedPos;
      _targetSeekPosition = savedPos;
      _isSeekingToHistory = true;
      setState(() => _position = Duration(seconds: savedPos));
    } else {
      _isSeekingToHistory = false;
      _targetSeekPosition = 0;
    }

    final videoUri = Uri.file(_currentItem.path).toString();
    await _player.open(Media(videoUri));
    await _player.setVolume(100.0);

    if (savedPos > 1 && mounted) {
      // Wait for mpv to report a non-zero duration (video fully loaded)
      try {
        await _player.stream.duration
            .firstWhere((dur) => dur > Duration.zero)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}

      if (mounted) {
        // Seek to the saved position
        await _player.seek(Duration(seconds: savedPos));

        // Wait for mpv to confirm it reached the target position
        try {
          await _player.stream.position
              .firstWhere((pos) => pos.inSeconds >= savedPos - 1)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // If timeout, try seeking one more time
          if (mounted) {
            await _player.seek(Duration(seconds: savedPos));
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
    }

    // Release the gatekeeper - the position listener will now accept events
    // but _targetSeekPosition still guards against late zero-flushes
    _isSeekingToHistory = false;
    historyCtrl.recordPlayback(_currentItem.id, playbackPosition: savedPos > 1 ? savedPos : 0);
  }

  MediaItemEntity? _peekNextItem() {
    return ref.read(musicPlayerControllerProvider.notifier).peekNextItem();
  }

  void _skipToNext() {
    _resetControlsTimer();
    ref.read(musicPlayerControllerProvider.notifier).skipToNext();
  }

  void _skipToPrevious() {
    _resetControlsTimer();
    if (_position.inSeconds > 3) {
      _player.seek(Duration.zero);
      return;
    }
    ref.read(musicPlayerControllerProvider.notifier).skipToPrevious();
  }

  void _toggleMute() {
    _resetControlsTimer();
    setState(() => _isMuted = !_isMuted);
    _player.setVolume(_isMuted ? 0.0 : 100.0);
  }

  void _toggleFullscreen() {
    _resetControlsTimer();
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _seekRelative(int seconds) {
    _resetControlsTimer();
    final maxSec = _duration.inSeconds > 0 ? _duration.inSeconds : 1;
    final newSeconds = (_position.inSeconds + seconds).clamp(0, maxSec);
    _player.seek(Duration(seconds: newSeconds));

    _seekOverlayTimer?.cancel();
    setState(() {
      if (seconds < 0) {
        _showRewindOverlay = true;
        _showForwardOverlay = false;
      } else {
        _showForwardOverlay = true;
        _showRewindOverlay = false;
      }
      if ((_seekAccumulatedSeconds < 0 && seconds < 0) || (_seekAccumulatedSeconds > 0 && seconds > 0)) {
        _seekAccumulatedSeconds += seconds;
      } else {
        _seekAccumulatedSeconds = seconds;
      }
    });

    _seekOverlayTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showRewindOverlay = false;
          _showForwardOverlay = false;
          _seekAccumulatedSeconds = 0;
        });
      }
    });
  }

  Future<void> _onBackPressed() async {
    // If the video completed naturally, save position 0 so it restarts
    // next time instead of getting stuck at the last second.
    if (_isCompleted) {
      await ref.read(historyControllerProvider).recordPlayback(
        _currentItem.id,
        playbackPosition: 0,
      );
      ref.read(musicPlayerControllerProvider.notifier).updatePosition(Duration.zero);
    } else {
      final posToSave = _lastKnownValidPosition > 1
          ? _lastKnownValidPosition
          : (_position.inSeconds > 0 ? _position.inSeconds : _player.state.position.inSeconds);

      if (posToSave > 1) {
        await ref.read(historyControllerProvider).recordPlayback(
          _currentItem.id,
          playbackPosition: posToSave,
        );
        ref.read(musicPlayerControllerProvider.notifier).updatePosition(Duration(seconds: posToSave));
      }
    }

    ref.read(musicPlayerControllerProvider.notifier).pauseAudio();
    try {
      await _player.pause();
      await _player.stop();
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    VideoPlayerPage.isActive = false;
    _controlsTimer?.cancel();
    _seekOverlayTimer?.cancel();

    // If the video completed naturally, ensure position stays at 0
    if (_isCompleted) {
      ref.read(historyControllerProvider).recordPlayback(
        _currentItem.id,
        playbackPosition: 0,
      );
      ref.read(musicPlayerControllerProvider.notifier).updatePosition(Duration.zero);
    } else {
      final posToSave = _lastKnownValidPosition > 1
          ? _lastKnownValidPosition
          : (_position.inSeconds > 0 ? _position.inSeconds : _player.state.position.inSeconds);

      if (posToSave > 1) {
        ref.read(historyControllerProvider).recordPlayback(
          _currentItem.id,
          playbackPosition: posToSave,
        );
        ref.read(musicPlayerControllerProvider.notifier).updatePosition(Duration(seconds: posToSave));
      }
    }

    ref.read(musicPlayerControllerProvider.notifier).pauseAudio();
    _player.pause();
    _player.stop();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _togglePlayPause() {
    _resetControlsTimer();
    _player.playOrPause();
  }

  void _setSpeed(double speed) {
    _resetControlsTimer();
    setState(() => _playbackSpeed = speed);
    _player.setRate(speed);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MusicPlayerState>(musicPlayerControllerProvider, (previous, next) {
      final newItem = next.activeItem;
      if (newItem == null || newItem.mediaType == 'audio') {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else if (newItem.id != _currentItem.id) {
        setState(() {
          _currentItem = newItem;
          _isUpNextDismissed = false;
        });
        _playCurrentMedia();
      }
    });

    final durationSeconds = _duration.inSeconds.toDouble();
    final positionSeconds = _position.inSeconds.toDouble().clamp(
          0.0,
          durationSeconds > 0 ? durationSeconds : 1.0,
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Listener(
          onPointerDown: _onPointerDown,
          child: GestureDetector(
            onTap: _onVideoTap,
            onDoubleTapDown: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              final tapX = details.globalPosition.dx;
              if (tapX < screenWidth * 0.4) {
                _seekRelative(-10);
              } else if (tapX > screenWidth * 0.6) {
                _seekRelative(10);
              }
            },
            onHorizontalDragEnd: (details) {
              _resetControlsTimer();
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -300) {
                _skipToNext();
              } else if (velocity > 300) {
                _skipToPrevious();
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video Viewport
                Center(
                  child: Video(
                    controller: _videoController,
                    controls: NoVideoControls,
                  ),
                ),

                // Double-Tap Rewind Overlay Indicator (-10s)
                if (_showRewindOverlay)
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.12,
                    child: AnimatedOpacity(
                      opacity: _showRewindOverlay ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 40),
                            const SizedBox(height: 4),
                            Text(
                              '${_seekAccumulatedSeconds.abs()} seconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Double-Tap Forward Overlay Indicator (+10s)
                if (_showForwardOverlay)
                  Positioned(
                    right: MediaQuery.of(context).size.width * 0.12,
                    child: AnimatedOpacity(
                      opacity: _showForwardOverlay ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 40),
                            const SizedBox(height: 4),
                            Text(
                              '${_seekAccumulatedSeconds.abs()} seconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Video Controls Overlay with Animated Opacity
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Top Header Bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black87, Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                      onPressed: _onBackPressed,
                                    ),
                                  Expanded(
                                    child: Text(
                                      _currentItem.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final favoriteIdsAsync = ref.watch(favoriteMediaIdsStreamProvider);
                                      final isFavorite = favoriteIdsAsync.value?.contains(_currentItem.id) ?? false;

                                      return IconButton(
                                        icon: Icon(
                                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          color: isFavorite ? Colors.redAccent : Colors.white,
                                        ),
                                        onPressed: () {
                                          ref.read(favoritesControllerProvider).toggleFavorite(_currentItem.id);
                                        },
                                        tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Center Controls Row (Prev | Play/Pause | Next)
                      Center(
                        child: Builder(builder: (context) {
                            final hasPrevious = _currentIndex > 0 || _position.inSeconds > 3;
                            final hasNext = _currentIndex < _playlist.length - 1;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    iconSize: 36,
                                    icon: Icon(
                                      Icons.skip_previous_rounded,
                                      color: hasPrevious ? Colors.white : Colors.white38,
                                    ),
                                    onPressed: hasPrevious ? _skipToPrevious : null,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    iconSize: 52,
                                    icon: Icon(
                                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    iconSize: 36,
                                    icon: Icon(
                                      Icons.skip_next_rounded,
                                      color: hasNext ? Colors.white : Colors.white38,
                                    ),
                                    onPressed: hasNext ? _skipToNext : null,
                                  ),
                                ),
                              ],
                            );
                          }),
                      ),

                      // YouTube-Style Bottom Control Bar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Red YouTube-style Progress Bar
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3.0,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                                    activeTrackColor: Colors.redAccent,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.redAccent,
                                    overlayColor: Colors.redAccent.withValues(alpha: 0.2),
                                  ),
                                  child: Slider(
                                    value: positionSeconds,
                                    max: durationSeconds > 0 ? durationSeconds : 1.0,
                                    onChanged: (value) {
                                      _resetControlsTimer();
                                      _player.seek(Duration(seconds: value.toInt()));
                                    },
                                  ),
                                ),

                                // YouTube Control Buttons Bar
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                                  child: Row(
                                    children: [
                                      // Play / Pause Icon Button
                                      IconButton(
                                        icon: Icon(
                                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                        ),
                                        onPressed: _togglePlayPause,
                                      ),

                                      // Volume / Mute Icon Button
                                      IconButton(
                                        icon: Icon(
                                          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                          color: Colors.white,
                                        ),
                                        onPressed: _toggleMute,
                                      ),

                                      const SizedBox(width: 4),

                                      // YouTube Time Pill (15:10 / 30:08)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      const Spacer(),

                                      // Autoplay Toggle Switch Button
                                      IconButton(
                                        icon: Icon(
                                          _autoPlayNext
                                              ? Icons.autorenew_rounded
                                              : Icons.cancel_outlined,
                                          color: _autoPlayNext ? Colors.redAccent : Colors.white54,
                                          size: 20,
                                        ),
                                        tooltip: 'Autoplay Next',
                                        onPressed: () {
                                          _resetControlsTimer();
                                          setState(() => _autoPlayNext = !_autoPlayNext);
                                        },
                                      ),

                                      // Settings / Speed Popup Menu
                                      PopupMenuButton<double>(
                                        icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                                        tooltip: 'Playback Speed',
                                        onSelected: _setSpeed,
                                        itemBuilder: (context) => [
                                          for (final speed in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                                            PopupMenuItem(
                                              value: speed,
                                              child: Text(
                                                '${speed}x Speed',
                                                style: TextStyle(
                                                  fontWeight: _playbackSpeed == speed
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),

                                      // Fullscreen Toggle Button
                                      IconButton(
                                        icon: Icon(
                                          _isFullscreen
                                              ? Icons.fullscreen_exit_rounded
                                              : Icons.fullscreen_rounded,
                                          color: Colors.white,
                                        ),
                                        tooltip: 'Fullscreen',
                                        onPressed: _toggleFullscreen,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Up Next 10-Second Preview Overlay Banner
              if (!_isUpNextDismissed &&
                  _duration.inSeconds > 2 &&
                  (_duration.inSeconds - _position.inSeconds) <= 10 &&
                  (_duration.inSeconds - _position.inSeconds) > 0 &&
                  _peekNextItem() != null)
                Positioned(
                  bottom: (_showControls ? 110 : 80) + MediaQuery.of(context).padding.bottom,
                  left: 16,
                  right: 16,
                  child: UpNextBannerWidget(
                    item: _peekNextItem()!,
                    remainingSeconds: (_duration.inSeconds - _position.inSeconds).clamp(0, 10),
                    onPlayNow: _skipToNext,
                    onDismiss: () => setState(() => _isUpNextDismissed = true),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
