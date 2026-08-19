import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text('Now Playing', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(),
              // Large Album Artwork Container
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.width * 0.75,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 100,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              // Title & Artist Metadata with Favorite Toggle
              Builder(
                builder: (context) {
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
                },
              ),
              const SizedBox(height: 24),
              // Seekbar Slider
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
              const SizedBox(height: 16),
              // Main Control Buttons
              Builder(builder: (context) {
                final hasPrevious = playerState.isShuffle ||
                    playerState.repeatMode != PlayerRepeatMode.off ||
                    playerState.currentIndex > 0 ||
                    playerState.position.inSeconds > 3;
                final hasNext = playerState.isShuffle ||
                    playerState.repeatMode != PlayerRepeatMode.off ||
                    playerState.currentIndex < playerState.queue.length - 1;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: playerState.isShuffle ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => controller.toggleShuffle(),
                    ),
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: hasPrevious ? () => controller.skipToPrevious() : null,
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 40,
                        icon: Icon(
                          playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
              }),
              const Spacer(),
              if (playerState.showUpNextPreview && playerState.nextUpItem != null) ...[
                UpNextBannerWidget(
                  item: playerState.nextUpItem!,
                  remainingSeconds:
                      (playerState.duration.inSeconds - playerState.position.inSeconds).clamp(0, 10),
                  onPlayNow: () => controller.skipToNext(),
                  onDismiss: () => controller.dismissUpNextPreview(),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
