import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/media_item_entity.dart';
import '../../../player/presentation/controllers/music_player_controller.dart';
import '../controllers/library_controller.dart';

import '../../../playlists/presentation/widgets/add_to_playlist_dialog.dart';
import '../widgets/media_item_tile.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryControllerProvider.notifier).scanDeviceMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LibraryState>(libraryControllerProvider, (previous, next) {
      if (previous?.isScanning == true && !next.isScanning && next.statusMessage != null) {
        final message = next.statusMessage!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    });


    final libraryState = ref.watch(libraryControllerProvider);
    final controller = ref.read(libraryControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;



    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Media Library',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: libraryState.isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.sync_rounded),
              tooltip: 'Scan Storage',
              onPressed: libraryState.isScanning ? null : () => controller.scanDeviceMedia(),
            ),
          ],
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: 'All'),
              Tab(icon: Icon(Icons.music_note_rounded, size: 18), text: 'Music'),
              Tab(icon: Icon(Icons.movie_rounded, size: 18), text: 'Videos'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (libraryState.isScanning && libraryState.statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        libraryState.statusMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (libraryState.errorMessage != null && !libraryState.permissionGranted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        libraryState.errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => controller.requestStoragePermission(),
                      child: const Text('Grant'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _MediaListView(
                    streamProvider: allMediaStreamProvider,
                    emptyTitle: 'No media items found',
                    emptySubtitle: 'Tap "Scan Device Media" to discover local audio and video files.',
                  ),
                  _MediaListView(
                    streamProvider: musicMediaStreamProvider,
                    emptyTitle: 'No music files found',
                    emptySubtitle: 'Scan your device to find MP3, M4A, FLAC, and audio tracks.',
                  ),
                  _MediaListView(
                    streamProvider: videoMediaStreamProvider,
                    emptyTitle: 'No video files found',
                    emptySubtitle: 'Scan your device to find MP4, MKV, and local videos.',
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: libraryState.isScanning ? null : () => controller.scanDeviceMedia(),
          icon: libraryState.isScanning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.search_rounded),
          label: Text(libraryState.isScanning ? 'Scanning...' : 'Scan Storage'),
        ),
      ),
    );
  }
}

class _MediaListView extends ConsumerWidget {
  final StreamProvider<List<MediaItemEntity>> streamProvider;
  final String emptyTitle;
  final String emptySubtitle;

  const _MediaListView({
    required this.streamProvider,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(streamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return mediaAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_open_rounded,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    emptyTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emptySubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(libraryControllerProvider.notifier).scanDeviceMedia();
                    },
                    icon: const Icon(Icons.manage_search_rounded),
                    label: const Text('Scan Storage Now'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 76),
          itemBuilder: (context, index) {
            final item = items[index];
            return MediaItemTile(
              item: item,
              onTap: () {
                ref.read(musicPlayerControllerProvider.notifier).playItem(item, queue: items);
              },
              onMoreTap: () => AddToPlaylistDialog.show(context, item),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load media items',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
