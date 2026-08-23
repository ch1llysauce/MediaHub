import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/media_thumbnail.dart';
import '../controllers/music_player_controller.dart';
import '../pages/full_music_player_page.dart';
import '../pages/video_player_page.dart';
import 'up_next_banner_widget.dart';

class MiniPlayerWidget extends ConsumerWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MusicPlayerState>(musicPlayerControllerProvider, (
      previous,
      next,
    ) {
      if (next.activeItem != null &&
          next.activeItem?.mediaType == 'video' &&
          previous?.activeItem?.id != next.activeItem?.id) {
        final videoItem = next.activeItem!;
        final queue = next.queue;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Only push if no VideoPlayerPage is currently active;
          // the existing page handles track changes internally.
          if (context.mounted && !VideoPlayerPage.isActive) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) =>
                    VideoPlayerPage(item: videoItem, playlist: queue),
              ),
            );
          }
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
    final colorScheme = theme.colorScheme;

    final progress = (playerState.duration.inMilliseconds > 0)
        ? (playerState.position.inMilliseconds /
                  playerState.duration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    final remainingSeconds =
        (playerState.duration.inSeconds - playerState.position.inSeconds).clamp(
          0,
          10,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (playerState.showUpNextPreview && playerState.nextUpItem != null)
          UpNextBannerWidget(
            item: playerState.nextUpItem!,
            remainingSeconds: remainingSeconds,
            onPlayNow: () => controller.skipToNext(),
            onDismiss: () => controller.dismissUpNextPreview(),
          ),
        GestureDetector(
          onTap: () {
            if (activeItem.mediaType == 'video') {
              // Only push if no VideoPlayerPage is currently active
              if (!VideoPlayerPage.isActive) {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      item: activeItem,
                      playlist: playerState.queue,
                    ),
                  ),
                );
              }
            } else {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FullMusicPlayerPage(),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      MediaThumbnail(
                        artworkPath: activeItem.artworkPath,
                        mediaType: activeItem.mediaType,
                        size: 44,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeItem.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeItem.artist ??
                                  (activeItem.mediaType == 'video'
                                      ? 'Video File'
                                      : 'Unknown Artist'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        onPressed:
                            (playerState.isShuffle ||
                                playerState.repeatMode !=
                                    PlayerRepeatMode.off ||
                                playerState.currentIndex > 0 ||
                                playerState.position.inSeconds > 3)
                            ? () => controller.skipToPrevious()
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          activeItem.mediaType == 'video'
                              ? Icons.play_circle_fill_rounded
                              : (playerState.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded),
                          size: 32,
                          color: colorScheme.primary,
                        ),
                        onPressed: () {
                          if (activeItem.mediaType == 'video') {
                            // Only push if no VideoPlayerPage is currently active
                            if (!VideoPlayerPage.isActive) {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerPage(
                                    item: activeItem,
                                    playlist: playerState.queue,
                                  ),
                                ),
                              );
                            }
                          } else {
                            controller.togglePlayPause();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed:
                            (playerState.isShuffle ||
                                playerState.repeatMode !=
                                    PlayerRepeatMode.off ||
                                playerState.currentIndex <
                                    playerState.queue.length - 1)
                            ? () => controller.skipToNext()
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => controller.closePlayer(),
                        tooltip: 'Close player',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
