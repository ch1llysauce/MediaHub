import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/providers.dart';
import '../controllers/playlists_controller.dart';

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

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
            hintText: 'Playlist name (e.g., Favorites, Workout)',
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
                await ref
                    .read(playlistsControllerProvider.notifier)
                    .createPlaylist(name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, String id, String currentName) {
    final textController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'New name',
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
                    .renamePlaylist(id, newName);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlaylist(BuildContext context, WidgetRef ref, String id, String name) {
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
                  .deletePlaylist(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(allPlaylistsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlaylistDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Playlist'),
      ),
      body: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            leading: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: 28,
              ),
            ),
            title: const Text(
              'Favorites',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text('Your favorited audio tracks & videos'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.goNamed('favorites'),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                Icons.history_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            title: const Text(
              'Playback History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text('Recently played songs & videos'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.goNamed('history'),
          ),
          const Divider(height: 1),
          Expanded(
            child: playlistsAsync.when(
              data: (playlists) {
          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No playlists yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a playlist to organize your favorite music and videos.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreatePlaylistDialog(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Playlist'),
                  ),
                ],
              ),
            );
          }

          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

          return GridView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isLandscape ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isLandscape ? 1.05 : 0.85,
            ),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final hasArtwork = playlist.artworkPath != null &&
                  File(playlist.artworkPath!).existsSync();

              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                child: InkWell(
                  onTap: () => context.push('/playlists/${playlist.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail Preview
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: hasArtwork
                              ? Image.file(
                                  File(playlist.artworkPath!),
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Icon(
                                    Icons.queue_music_rounded,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                        ),
                      ),
                      // Details Bar
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playlist.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${playlist.itemCount} items',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                              onSelected: (value) {
                                if (value == 'rename') {
                                  _showRenameDialog(context, ref, playlist.id, playlist.name);
                                } else if (value == 'delete') {
                                  _confirmDeletePlaylist(context, ref, playlist.id, playlist.name);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'rename',
                                  child: Text('Rename'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading playlists: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
