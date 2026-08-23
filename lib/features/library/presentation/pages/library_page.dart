import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/media_item_entity.dart';
import '../../../player/presentation/controllers/music_player_controller.dart';
import '../../../search/presentation/controllers/search_controller.dart';
import '../controllers/library_controller.dart';
import '../widgets/sort_filter_sheet.dart';

import '../../../playlists/presentation/widgets/add_to_playlist_dialog.dart';
import '../widgets/media_item_tile.dart';

import 'package:path/path.dart' as p;

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
      if (previous?.isScanning == true &&
          !next.isScanning &&
          next.statusMessage != null) {
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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Media Library',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search Library',
              onPressed: () => context.pushNamed('search'),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Sort & Filter',
              onPressed: () => SortFilterSheet.show(context),
            ),
            IconButton(
              icon: libraryState.isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.sync_rounded),
              tooltip: 'Scan Storage',
              onPressed: libraryState.isScanning
                  ? null
                  : () => controller.scanDeviceMedia(),
            ),
          ],
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: 'All'),
              Tab(
                icon: Icon(Icons.music_note_rounded, size: 18),
                text: 'Music',
              ),
              Tab(icon: Icon(Icons.movie_rounded, size: 18), text: 'Videos'),
              Tab(icon: Icon(Icons.folder_outlined, size: 18), text: 'Folders'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (libraryState.isScanning && libraryState.statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
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
            if (libraryState.errorMessage != null &&
                !libraryState.permissionGranted)
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
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.onErrorContainer,
                    ),
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
                    emptySubtitle:
                        'Tap "Scan Device Media" to discover local audio and video files.',
                  ),
                  _MediaListView(
                    streamProvider: musicMediaStreamProvider,
                    emptyTitle: 'No music files found',
                    emptySubtitle:
                        'Scan your device to find MP3, M4A, FLAC, and audio tracks.',
                  ),
                  _MediaListView(
                    streamProvider: videoMediaStreamProvider,
                    emptyTitle: 'No video files found',
                    emptySubtitle:
                        'Scan your device to find MP4, MKV, and local videos.',
                  ),
                  const _FolderListView(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: libraryState.isScanning
              ? null
              : () => controller.scanDeviceMedia(),
          icon: libraryState.isScanning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
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
      data: (rawItems) {
        final searchState = ref.watch(searchControllerProvider);
        final items = filterAndSortMediaItems(rawItems, searchState);
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
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
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
                      ref
                          .read(libraryControllerProvider.notifier)
                          .scanDeviceMedia();
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
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 76),
          itemBuilder: (context, index) {
            final item = items[index];
            return MediaItemTile(
              item: item,
              onTap: () {
                ref
                    .read(musicPlayerControllerProvider.notifier)
                    .playItem(item, queue: items);
              },
              onMoreTap: () => AddToPlaylistDialog.show(context, item),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load media items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderListView extends ConsumerStatefulWidget {
  const _FolderListView();

  @override
  ConsumerState<_FolderListView> createState() => _FolderListViewState();
}

class _FolderListViewState extends ConsumerState<_FolderListView> {
  String? _activeFolderPath;

  // BAGO: centralized setter na nag-sync sa shared back-intercept provider
  void _setActiveFolder(String? path) {
    setState(() {
      _activeFolderPath = path;
    });
    ref.read(libraryFolderBackInterceptProvider.notifier).state =
        path != null ? () => _setActiveFolder(null) : null;
  }

  @override
  void dispose() {
    // I-clear ang intercept kapag umalis sa Folders tab (hal. lumipat ng branch)
    // para hindi "mag-stick" ang back interception sa ibang tabs
    Future.microtask(() {
      final notifier = ref.read(libraryFolderBackInterceptProvider.notifier);
      if (notifier.state != null) {
        notifier.state = null;
      }
    });
    super.dispose();
  }

  String _cleanFolderName(String dirPath) {
    if (dirPath.contains('/storage/emulated/0/')) {
      final relative = dirPath.replaceFirst('/storage/emulated/0/', '');
      return relative.isEmpty ? 'Internal Storage' : relative;
    }
    return p.basename(dirPath).isEmpty ? dirPath : p.basename(dirPath);
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(allMediaStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return mediaAsync.when(
      data: (rawItems) {
        final searchState = ref.watch(searchControllerProvider);
        final items = filterAndSortMediaItems(rawItems, searchState);

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
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_off_rounded,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No folders found',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan your device storage to discover folders containing media.',
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

        // Group media items by parent directory
        final Map<String, List<MediaItemEntity>> grouped = {};
        for (final item in items) {
          final parentDir = p.dirname(item.path);
          grouped.putIfAbsent(parentDir, () => []).add(item);
        }

        final sortedFolders = grouped.keys.toList()
          ..sort(
            (a, b) => _cleanFolderName(
              a,
            ).toLowerCase().compareTo(_cleanFolderName(b).toLowerCase()),
          );

        // Check if an active folder is selected
        if (_activeFolderPath != null &&
            grouped.containsKey(_activeFolderPath)) {
          final folderItems = grouped[_activeFolderPath]!;
          final folderName = _cleanFolderName(_activeFolderPath!);

          return Column(
            children: [
              // Header bar for active folder
              Container(
                color: colorScheme.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 6.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back to folders',
                      onPressed: () => _setActiveFolder(null),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folderName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${folderItems.length} ${folderItems.length == 1 ? 'item' : 'items'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ref
                            .read(musicPlayerControllerProvider.notifier)
                            .playItem(folderItems.first, queue: folderItems);
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play All'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Virtualized ListView for folder items (0% lag!)
              Expanded(
                child: ListView.separated(
                  itemCount: folderItems.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 76),
                  itemBuilder: (context, index) {
                    final item = folderItems[index];
                    return MediaItemTile(
                      item: item,
                      onTap: () {
                        ref
                            .read(musicPlayerControllerProvider.notifier)
                            .playItem(item, queue: folderItems);
                      },
                      onMoreTap: () =>
                          AddToPlaylistDialog.show(context, item),
                    );
                  },
                ),
              ),
            ],
          );
        }

        // Folder List View
        return ListView.separated(
          itemCount: sortedFolders.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
          itemBuilder: (context, index) {
            final folderPath = sortedFolders[index];
            final folderItems = grouped[folderPath]!;
            final folderName = _cleanFolderName(folderPath);

            final audioCount = folderItems
                .where((i) => i.mediaType == 'audio')
                .length;
            final videoCount = folderItems
                .where((i) => i.mediaType == 'video')
                .length;

            final subtitleParts = <String>[];
            if (audioCount > 0)
              subtitleParts.add(
                '$audioCount ${audioCount == 1 ? 'song' : 'songs'}',
              );
            if (videoCount > 0)
              subtitleParts.add(
                '$videoCount ${videoCount == 1 ? 'video' : 'videos'}',
              );

            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 26,
                ),
              ),
              title: Text(
                folderName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                subtitleParts.join(' • '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () => _setActiveFolder(folderPath),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Error loading folders: $err')),
    );
  }
}