import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/media_item_entity.dart';
import '../../../player/presentation/controllers/music_player_controller.dart';
import '../../../player/presentation/pages/full_music_player_page.dart';
import '../controllers/playlist_detail_controller.dart';
import '../controllers/playlists_controller.dart';
import '../../../../shared/media_thumbnail.dart';

class PlaylistDetailPage extends ConsumerWidget {
  final String playlistId;
  final String? playlistName;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    this.playlistName,
  });

  void _showRenameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final textController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'New playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(dialogContext);
                await ref
                    .read(playlistsControllerProvider.notifier)
                    .renamePlaylist(playlistId, newName);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlaylist(BuildContext context, WidgetRef ref, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: Text(
          'Are you sure you want to delete "$name"? Your audio and video files will NOT be deleted from storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(playlistsControllerProvider.notifier)
                  .deletePlaylist(playlistId);
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveTrack(BuildContext context, WidgetRef ref, String trackTitle, String trackId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from Playlist'),
        content: Text(
          'Remove "$trackTitle" from this playlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(playlistDetailControllerProvider(playlistId).notifier)
                  .removeTrack(trackId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _playMediaItem(
    BuildContext context,
    WidgetRef ref,
    MediaItemEntity item,
    List<MediaItemEntity> items, {
    bool? isShuffle,
  }) {
    if (item.isVideo) {
      context.pushNamed(
        'videoPlayer',
        extra: {'item': item, 'playlist': items},
      );
    } else {
      ref.read(musicPlayerControllerProvider.notifier).playItem(
            item,
            queue: items,
            playlistId: playlistId,
            isShuffle: isShuffle,
          );
      FullMusicPlayerPage.open(context);
    }
  }

  String _formatTotalDuration(List<MediaItemEntity> items) {
    final totalSeconds = items.fold<int>(0, (sum, e) => sum + (e.duration ?? 0));
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return minutes > 0 ? '$hours hr $minutes min' : '$hours hr';
    } else if (minutes > 0) {
      return seconds > 0 ? '$minutes min $seconds sec' : '$minutes min';
    } else if (totalSeconds > 0) {
      return '$seconds sec';
    }
    return '0 sec';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(allPlaylistsStreamProvider);
    final playlistItemsAsync = ref.watch(playlistDetailControllerProvider(playlistId));

    final currentPlaylist = playlistsAsync.value?.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => playlistsAsync.value?.isNotEmpty == true
          ? playlistsAsync.value!.first
          : const Stream.empty() as dynamic,
    );

    final title = currentPlaylist?.name ?? playlistName ?? 'Playlist';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') {
                _showRenameDialog(context, ref, title);
              } else if (value == 'delete') {
                _confirmDeletePlaylist(context, ref, title);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Rename Playlist'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Playlist',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: playlistItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Playlist is empty',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add tracks or videos from your library.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header Summary Banner
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.queue_music_rounded,
                        size: 32,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${items.length} items • ${_formatTotalDuration(items)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final playerState = ref.watch(musicPlayerControllerProvider);
                        final isShuffleActive = playerState.activePlaylistId == playlistId && playerState.isShuffle;

                        return Row(
                          children: [
                            IconButton.filled(
                              icon: const Icon(Icons.play_arrow_rounded),
                              tooltip: 'Play All',
                              onPressed: () {
                                _playMediaItem(context, ref, items.first, items, isShuffle: false);
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              style: isShuffleActive
                                  ? IconButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                    )
                                  : IconButton.styleFrom(
                                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                                    ),
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: isShuffleActive ? Theme.of(context).colorScheme.primary : null,
                              ),
                              tooltip: isShuffleActive ? 'Turn Off Shuffle' : 'Shuffle Play',
                              onPressed: () {
                                if (playerState.activePlaylistId == playlistId) {
                                  ref.read(musicPlayerControllerProvider.notifier).toggleShuffle();
                                } else {
                                  ref.read(musicPlayerControllerProvider.notifier).shufflePlay(
                                        items,
                                        playlistId: playlistId,
                                      );
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Reorderable Track List
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: items.length,
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(playlistDetailControllerProvider(playlistId).notifier)
                        .reorderTracks(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      key: ValueKey(item.id),
                      leading: MediaThumbnail(
                        artworkPath: item.artworkPath,
                        mediaType: item.mediaType,
                        size: 48,
                        borderRadius: 6,
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        item.artist ?? (item.mediaType == 'video' ? 'Video' : 'Unknown Artist'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                            tooltip: 'Remove from playlist',
                            onPressed: () => _confirmRemoveTrack(context, ref, item.title, item.id),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.drag_handle_rounded, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _playMediaItem(context, ref, item, items),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading playlist: $err')),
      ),
    );
  }
}
