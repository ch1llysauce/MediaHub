import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../domain/entities/media_item_entity.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/up_next_banner_widget.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  final MediaItemEntity item;
  final List<MediaItemEntity>? playlist;

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
  int _seekAccumulatedSeconds = 0;
  Timer? _controlsTimer;
  Timer? _seekOverlayTimer;

  static const Duration _autoHideDuration = Duration(seconds: 3, milliseconds: 500);

  @override
  void initState() {
    super.initState();

    _currentItem = widget.item;
    _playlist = widget.playlist ?? [_currentItem];
    _currentIndex = _playlist.indexWhere((e) => e.id == _currentItem.id);
    if (_currentIndex < 0) _currentIndex = 0;

    // Pause any active music audio playback without wiping player state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(musicPlayerControllerProvider.notifier).pauseAudio();
    });

    _player = Player();
    _videoController = VideoController(_player);

    _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    _player.stream.position.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _player.stream.duration.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
      }
    });

    _player.stream.completed.listen((completed) {
      if (completed && _autoPlayNext) {
        _skipToNext();
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

  void _playCurrentMedia() {
    final videoUri = Uri.file(_currentItem.path).toString();
    _player.open(Media(videoUri));
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

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _seekOverlayTimer?.cancel();
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

    return Scaffold(
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
                                    onPressed: () => Navigator.of(context).pop(),
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
    );
  }
}
