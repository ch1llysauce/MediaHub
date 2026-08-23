import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/media_thumbnail.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/up_next_banner_widget.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';

class FullMusicPlayerPage extends ConsumerWidget {
  const FullMusicPlayerPage({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final activeItem = playerState.activeItem;

    if (activeItem == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final durationSeconds = playerState.duration.inSeconds.toDouble();
    final positionSeconds = playerState.position.inSeconds.toDouble().clamp(
      0.0,
      durationSeconds > 0 ? durationSeconds : 1.0,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                colorScheme,
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
              colorScheme,
              activeItem,
              playerState,
              controller,
              positionSeconds,
              durationSeconds,
            );
          },
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: MediaThumbnail(
                artworkPath: activeItem.artworkPath,
                mediaType: activeItem.mediaType,
                size: MediaQuery.of(context).size.width * 0.75,
                borderRadius: 24,
              ),
            ),
          ),
          const Spacer(),
          _buildMetadataRow(context, ref, theme, colorScheme, activeItem),
          const SizedBox(height: 24),
          _buildSeekBar(
            theme,
            colorScheme,
            controller,
            playerState,
            positionSeconds,
            durationSeconds,
          ),
          const SizedBox(height: 16),
          _buildControls(colorScheme, controller, playerState),
          const Spacer(),
          _buildUpNextBanner(controller, playerState),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.height * 0.55,
                height: MediaQuery.of(context).size.height * 0.55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: MediaThumbnail(
                  artworkPath: activeItem.artworkPath,
                  mediaType: activeItem.mediaType,
                  size: MediaQuery.of(context).size.height * 0.55,
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
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic controller,
    dynamic playerState,
    double positionSeconds,
    double durationSeconds,
  ) {
    return Column(
      children: [
        Slider(
          value: positionSeconds,
          max: durationSeconds > 0 ? durationSeconds : 1.0,
          onChanged: (value) {
            controller.seek(Duration(seconds: value.toInt()));
          },
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
                ),
              ),
              Text(
                _formatDuration(playerState.duration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
    if (!playerState.showUpNextPreview || playerState.nextUpItem == null) {
      return const SizedBox.shrink();
    }
    return UpNextBannerWidget(
      item: playerState.nextUpItem!,
      remainingSeconds:
          (playerState.duration.inSeconds - playerState.position.inSeconds)
              .clamp(0, 10),
      onPlayNow: () => controller.skipToNext(),
      onDismiss: () => controller.dismissUpNextPreview(),
    );
  }
}
