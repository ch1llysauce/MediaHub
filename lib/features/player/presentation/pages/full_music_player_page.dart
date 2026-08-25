import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/media_thumbnail.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/up_next_banner_widget.dart';
import 'video_player_page.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';

final artworkColorSchemeProvider =
    FutureProvider.family<ColorScheme?, String?>((ref, artworkPath) async {
  if (artworkPath == null || artworkPath.isEmpty) return null;
  final file = File(artworkPath);
  if (!await file.exists()) return null;
  try {
    return await ColorScheme.fromImageProvider(
      provider: FileImage(file),
      brightness: Brightness.dark,
    );
  } catch (_) {
    return null;
  }
});

class FullMusicPlayerPage extends ConsumerStatefulWidget {
  const FullMusicPlayerPage({super.key});

  static bool isActive = false;

  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FullMusicPlayerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  static Future<void> replace(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FullMusicPlayerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<FullMusicPlayerPage> createState() =>
      _FullMusicPlayerPageState();
}

class _FullMusicPlayerPageState extends ConsumerState<FullMusicPlayerPage> {
  @override
  void initState() {
    super.initState();
    FullMusicPlayerPage.isActive = true;
  }

  @override
  void dispose() {
    FullMusicPlayerPage.isActive = false;
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

  @override
  Widget build(BuildContext context) {
    ref.listen<MusicPlayerState>(musicPlayerControllerProvider, (
      previous,
      next,
    ) {
      final newItem = next.activeItem;
      if (newItem == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pop();
        });
        return;
      }
      if (newItem.isVideo &&
          previous?.activeItem?.id != newItem.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VideoPlayerPage(
                item: newItem,
                playlist: next.queue,
              ),
            ),
          );
        });
      }
    });

    final playerState = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final activeItem = playerState.activeItem;

    if (activeItem == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final defaultColorScheme = theme.colorScheme;

    final dynamicColorScheme =
        ref.watch(artworkColorSchemeProvider(activeItem.artworkPath)).value ??
            defaultColorScheme;

    final primaryColor = dynamicColorScheme.primary;
    final surfaceColor = defaultColorScheme.surface;

    // Color-infused deep bottom tint so the entire background has dynamic color
    final bottomColor = Color.alphaBlend(
      primaryColor.withValues(alpha: 0.35),
      surfaceColor,
    );

    final durationSeconds = playerState.duration.inSeconds.toDouble();
    final positionSeconds = playerState.position.inSeconds.toDouble().clamp(
      0.0,
      durationSeconds > 0 ? durationSeconds : 1.0,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withValues(alpha: 0.70),
            primaryColor.withValues(alpha: 0.50),
            bottomColor,
          ],
          stops: const [0.0, 0.50, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Now Playing',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return _buildLandscapeLayout(
                  context,
                  ref,
                  theme,
                  dynamicColorScheme,
                  activeItem,
                  playerState,
                  controller,
                  positionSeconds,
                  durationSeconds,
                );
              }
              return _buildPortraitLayout(
                context,
                ref,
                theme,
                dynamicColorScheme,
                activeItem,
                playerState,
                controller,
                positionSeconds,
                durationSeconds,
              );
            },
          ),
        ),
      ),
    );
  }

  // ==================== PORTRAIT LAYOUT ====================
  Widget _buildPortraitLayout(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic activeItem,
    dynamic playerState,
    dynamic controller,
    double positionSeconds,
    double durationSeconds,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final artworkSize = (availableHeight * 0.38).clamp(160.0, 320.0);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: artworkSize,
                      child: _ArtworkDoubleTapSeekArea(
                        controller: controller,
                        artworkSize: artworkSize,
                        child: Center(
                          child: Container(
                            width: artworkSize,
                            height: artworkSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.0),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: MediaThumbnail(
                              artworkPath: activeItem.artworkPath,
                              mediaType: activeItem.mediaType,
                              size: artworkSize,
                              borderRadius: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildMetadataRow(context, ref, theme, colorScheme, activeItem),
                    const SizedBox(height: 16),
                    _buildSeekBar(
                      context,
                      theme,
                      colorScheme,
                      controller,
                      playerState,
                      positionSeconds,
                      durationSeconds,
                    ),
                    const SizedBox(height: 12),
                    _buildControls(colorScheme, controller, playerState),
                    const Spacer(),
                    _buildUpNextBanner(controller, playerState),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== LANDSCAPE LAYOUT ====================
  Widget _buildLandscapeLayout(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic activeItem,
    dynamic playerState,
    dynamic controller,
    double positionSeconds,
    double durationSeconds,
  ) {
    final artworkSize = MediaQuery.of(context).size.height * 0.55;

    return _ArtworkDoubleTapSeekArea(
      controller: controller,
      artworkSize: artworkSize,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Center(
                child: Container(
                  width: artworkSize,
                  height: artworkSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: MediaThumbnail(
                    artworkPath: activeItem.artworkPath,
                    mediaType: activeItem.mediaType,
                    size: artworkSize,
                    borderRadius: 20,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 24),
          // Kanan: Metadata, seekbar, controls
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMetadataRow(
                    context,
                    ref,
                    theme,
                    colorScheme,
                    activeItem,
                  ),
                  const SizedBox(height: 16),
                  _buildSeekBar(
                    context,
                    theme,
                    colorScheme,
                    controller,
                    playerState,
                    positionSeconds,
                    durationSeconds,
                  ),
                  const SizedBox(height: 8),
                  _buildControls(colorScheme, controller, playerState),
                  const SizedBox(height: 8),
                  _buildUpNextBanner(controller, playerState),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ==================== SHARED WIDGET BUILDERS ====================
  Widget _buildMetadataRow(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic activeItem,
  ) {
    final favoriteIdsAsync = ref.watch(favoriteMediaIdsStreamProvider);
    final isFavorite = favoriteIdsAsync.value?.contains(activeItem.id) ?? false;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeItem.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activeItem.artist ?? 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          iconSize: 28,
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.redAccent : colorScheme.onSurfaceVariant,
          ),
          onPressed: () {
            ref.read(favoritesControllerProvider).toggleFavorite(activeItem.id);
          },
          tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
        ),
      ],
    );
  }

  Widget _buildSeekBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic controller,
    dynamic playerState,
    double positionSeconds,
    double durationSeconds,
  ) {
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.25);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6.0,
            activeTrackColor: activeColor,
            inactiveTrackColor: inactiveColor,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8.0,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: positionSeconds,
            max: durationSeconds > 0 ? durationSeconds : 1.0,
            onChanged: (value) {
              controller.seek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(playerState.position),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatDuration(playerState.duration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(
    ColorScheme colorScheme,
    dynamic controller,
    dynamic playerState,
  ) {
    final hasPrevious =
        playerState.isShuffle ||
        playerState.repeatMode != PlayerRepeatMode.off ||
        playerState.currentIndex > 0 ||
        playerState.position.inSeconds > 3;
    final hasNext =
        playerState.isShuffle ||
        playerState.repeatMode != PlayerRepeatMode.off ||
        playerState.currentIndex < playerState.queue.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: playerState.isShuffle
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          onPressed: () => controller.toggleShuffle(),
        ),
        IconButton(
          iconSize: 40,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: hasPrevious ? () => controller.skipToPrevious() : null,
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 36,
            icon: Icon(
              playerState.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: colorScheme.onPrimary,
            ),
            onPressed: () => controller.togglePlayPause(),
          ),
        ),
        IconButton(
          iconSize: 40,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: hasNext ? () => controller.skipToNext() : null,
        ),
        IconButton(
          iconSize: 28,
          icon: Icon(
            playerState.repeatMode == PlayerRepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: playerState.repeatMode != PlayerRepeatMode.off
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          onPressed: () => controller.toggleRepeat(),
        ),
      ],
    );
  }

  Widget _buildUpNextBanner(dynamic controller, dynamic playerState) {
    final showBanner =
        playerState.showUpNextPreview && playerState.nextUpItem != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: showBanner
          ? UpNextBannerWidget(
              key: ValueKey(playerState.nextUpItem!.id),
              item: playerState.nextUpItem!,
              remainingSeconds:
                  (playerState.duration.inSeconds - playerState.position.inSeconds)
                      .clamp(0, 10),
              onPlayNow: () => controller.skipToNext(),
              onDismiss: () => controller.dismissUpNextPreview(),
            )
          : const SizedBox.shrink(key: ValueKey('empty_music_up_next')),
    );
  }
}

class _ArtworkDoubleTapSeekArea extends StatefulWidget {
  final Widget child;
  final dynamic controller;
  final double artworkSize;

  const _ArtworkDoubleTapSeekArea({
    required this.child,
    required this.controller,
    required this.artworkSize,
  });

  @override
  State<_ArtworkDoubleTapSeekArea> createState() =>
      _ArtworkDoubleTapSeekAreaState();
}

class _ArtworkDoubleTapSeekAreaState extends State<_ArtworkDoubleTapSeekArea> {
  bool _showRewindOverlay = false;
  bool _showForwardOverlay = false;
  double _rewindOpacity = 0.0;
  double _forwardOpacity = 0.0;
  Timer? _hideTimer;
  Timer? _fadeTimer;

  void _triggerRewind() {
    widget.controller.seekRelative(-10);
    _hideTimer?.cancel();
    _fadeTimer?.cancel();

    setState(() {
      _showRewindOverlay = true;
      _showForwardOverlay = false;
      _forwardOpacity = 0.0;
      _rewindOpacity = 0.0;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showRewindOverlay) {
        setState(() {
          _rewindOpacity = 1.0;
        });
      }
    });

    _hideTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() {
          _rewindOpacity = 0.0;
        });
        _fadeTimer = Timer(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() {
              _showRewindOverlay = false;
            });
          }
        });
      }
    });
  }

  void _triggerForward() {
    widget.controller.seekRelative(10);
    _hideTimer?.cancel();
    _fadeTimer?.cancel();

    setState(() {
      _showForwardOverlay = true;
      _showRewindOverlay = false;
      _rewindOpacity = 0.0;
      _forwardOpacity = 0.0;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showForwardOverlay) {
        setState(() {
          _forwardOpacity = 1.0;
        });
      }
    });

    _hideTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() {
          _forwardOpacity = 0.0;
        });
        _fadeTimer = Timer(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() {
              _showForwardOverlay = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,

        // Full-width gesture touch zones across the screen (X-axis)
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: _triggerRewind,
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: _triggerForward,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),

        // Rewind Overlay Pill (-10s)
        if (_showRewindOverlay)
          Positioned(
            left: isLandscape ? screenWidth * 0.12 : 36,
            child: AnimatedOpacity(
              opacity: _rewindOpacity,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.replay_10_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '-10s',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Forward Overlay Pill (+10s)
        if (_showForwardOverlay)
          Positioned(
            right: isLandscape ? screenWidth * 0.12 : 36,
            child: AnimatedOpacity(
              opacity: _forwardOpacity,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '+10s',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.forward_10_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
