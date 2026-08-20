import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/presentation/widgets/media_item_tile.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_dialog.dart';
import '../../../player/presentation/controllers/music_player_controller.dart';
import '../controllers/history_controller.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _selectedFilter = 'all'; // 'all', 'audio', 'video'

  String _formatLastPlayed(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatPosition(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _confirmClearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Playback History?'),
        content: const Text(
          'This will remove all entries from your history list. Physical media files on your device will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(historyControllerProvider).clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playback history cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final historyAsync = ref.watch(historyMediaItemsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Playback History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          historyAsync.maybeWhen(
            data: (items) => items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded),
                    tooltip: 'Clear History',
                    onPressed: _confirmClearHistory,
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (items) {
          final filteredItems = items.where((item) {
            if (_selectedFilter == 'audio') return item.mediaItem.mediaType == 'audio';
            if (_selectedFilter == 'video') return item.mediaItem.mediaType == 'video';
            return true;
          }).toList();

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No playback history yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Songs and videos you play will appear here so you can easily resume where you left off.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final audioCount = items.where((e) => e.mediaItem.mediaType == 'audio').length;
          final videoCount = items.where((e) => e.mediaItem.mediaType == 'video').length;

          return Column(
            children: [
              // Filter chips bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: Text('All (${items.length})'),
                              selected: _selectedFilter == 'all',
                              onSelected: (_) => setState(() => _selectedFilter = 'all'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text('Music ($audioCount)'),
                              selected: _selectedFilter == 'audio',
                              onSelected: (_) => setState(() => _selectedFilter = 'audio'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text('Videos ($videoCount)'),
                              selected: _selectedFilter == 'video',
                              onSelected: (_) => setState(() => _selectedFilter = 'video'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.shuffle_rounded),
                      tooltip: 'Shuffle History',
                      onPressed: () {
                        final mediaList = filteredItems.map((e) => e.mediaItem).toList();
                        if (mediaList.isNotEmpty) {
                          ref.read(musicPlayerControllerProvider.notifier).shufflePlay(mediaList);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // History Items list
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No history matching filter',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final historyEntry = filteredItems[index];
                          final item = historyEntry.mediaItem;
                          final allMediaList = filteredItems.map((e) => e.mediaItem).toList();

                          final subtitleDetails = <String>[];
                          subtitleDetails.add(_formatLastPlayed(historyEntry.lastPlayed));
                          if (item.mediaType == 'video' && historyEntry.playbackPosition > 0) {
                            subtitleDetails.add('Resume at ${_formatPosition(historyEntry.playbackPosition)}');
                          }

                          return Dismissible(
                            key: Key('hist_${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: colorScheme.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              ref.read(historyControllerProvider).removeHistoryItem(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed "${item.title}" from history')),
                              );
                            },
                            child: MediaItemTile(
                              item: item,
                              customSubtitle: subtitleDetails.join(' • '),
                              onTap: () {
                                ref.read(musicPlayerControllerProvider.notifier).playItem(
                                      item,
                                      queue: allMediaList,
                                    );
                              },
                              onMoreTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.playlist_add_rounded),
                                        title: const Text('Add to Playlist'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (_) => AddToPlaylistDialog(mediaItem: item),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete_outline_rounded),
                                        title: const Text('Remove from History'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          ref.read(historyControllerProvider).removeHistoryItem(item.id);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading history: $err'),
        ),
      ),
    );
  }
}
