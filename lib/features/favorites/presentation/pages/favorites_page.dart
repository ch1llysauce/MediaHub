import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/presentation/widgets/media_item_tile.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_dialog.dart';
import '../../../player/presentation/controllers/music_player_controller.dart';
import '../controllers/favorites_controller.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  String _selectedFilter = 'all'; // 'all', 'audio', 'video'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final favoritesAsync = ref.watch(favoriteMediaItemsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search Favorites',
            onPressed: () {
              // Navigation to search will be hooked in Phase 9
            },
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (items) {
          final filteredItems = items.where((item) {
            if (_selectedFilter == 'audio') return item.mediaType == 'audio';
            if (_selectedFilter == 'video') return item.mediaType == 'video';
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
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 64,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No favorites yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the heart icon on any song or video to add it to your favorites collection.',
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

          final playerState = ref.watch(musicPlayerControllerProvider);
          final isShuffleActive = playerState.activePlaylistId == 'favorites' && playerState.isShuffle;

          return Column(
            children: [
              // Filter Choice Chips & Play Header Bar
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
                              selected: _selectedFilter == 'all',
                              label: Text('All (${items.length})'),
                              onSelected: (_) => setState(() => _selectedFilter = 'all'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              selected: _selectedFilter == 'audio',
                              label: Text('Music (${items.where((i) => i.mediaType == 'audio').length})'),
                              onSelected: (_) => setState(() => _selectedFilter = 'audio'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              selected: _selectedFilter == 'video',
                              label: Text('Videos (${items.where((i) => i.mediaType == 'video').length})'),
                              onSelected: (_) => setState(() => _selectedFilter = 'video'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.play_arrow_rounded),
                      tooltip: 'Play All Favorites',
                      onPressed: filteredItems.isEmpty
                          ? null
                          : () {
                              ref.read(musicPlayerControllerProvider.notifier).playItem(
                                    filteredItems.first,
                                    queue: filteredItems,
                                    playlistId: 'favorites',
                                    isShuffle: false,
                                  );
                            },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: isShuffleActive
                          ? IconButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                            )
                          : IconButton.styleFrom(
                              side: BorderSide(color: colorScheme.outline),
                            ),
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: isShuffleActive ? colorScheme.primary : null,
                      ),
                      tooltip: isShuffleActive ? 'Turn Off Shuffle' : 'Shuffle Play Favorites',
                      onPressed: filteredItems.isEmpty
                          ? null
                          : () {
                              if (playerState.activePlaylistId == 'favorites') {
                                ref.read(musicPlayerControllerProvider.notifier).toggleShuffle();
                              } else {
                                ref.read(musicPlayerControllerProvider.notifier).shufflePlay(
                                      filteredItems,
                                      playlistId: 'favorites',
                                    );
                              }
                            },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Favorites List View
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_selectedFilter == 'audio' ? 'music' : 'video'} favorites found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredItems.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 76),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return MediaItemTile(
                            item: item,
                            onTap: () {
                              ref.read(musicPlayerControllerProvider.notifier).playItem(
                                    item,
                                    queue: filteredItems,
                                    playlistId: 'favorites',
                                  );
                            },
                            onMoreTap: () => AddToPlaylistDialog.show(context, item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading favorites: $error'),
        ),
      ),
    );
  }
}
