import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/media_item_entity.dart';
import '../controllers/playlists_controller.dart';

class AddToPlaylistDialog extends ConsumerWidget {
  final MediaItemEntity mediaItem;

  const AddToPlaylistDialog({
    super.key,
    required this.mediaItem,
  });

  static Future<void> show(BuildContext context, MediaItemEntity item) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToPlaylistDialog(mediaItem: item),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            prefixIcon: Icon(Icons.playlist_add_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext);
                final newPlaylist = await ref
                    .read(playlistsControllerProvider.notifier)
                    .createPlaylist(name);

                if (newPlaylist != null && context.mounted) {
                  await ref
                      .read(playlistsControllerProvider.notifier)
                      .addMediaToPlaylist(newPlaylist.id, mediaItem.id);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${mediaItem.title}" to "$name"'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(allPlaylistsStreamProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add to Playlist',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            mediaItem.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.add_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text(
              'Create New Playlist',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () => _showCreatePlaylistDialog(context, ref),
          ),
          const SizedBox(height: 8),
          playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No playlists created yet.'),
                  ),
                );
              }
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.queue_music_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.itemCount} items'),
                      onTap: () async {
                        final success = await ref
                            .read(playlistsControllerProvider.notifier)
                            .addMediaToPlaylist(playlist.id, mediaItem.id);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Added "${mediaItem.title}" to "${playlist.name}"'
                                    : 'Already in "${playlist.name}"',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Text('Error loading playlists: $err'),
            ),
          ),
        ],
      ),
    );
  }
}
