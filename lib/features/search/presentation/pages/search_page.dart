import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/presentation/widgets/media_item_tile.dart';
import '../../../library/presentation/widgets/sort_filter_sheet.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_dialog.dart';
import '../../../player/presentation/controllers/music_player_controller.dart';
import '../controllers/search_controller.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchControllerProvider).query;
    _textController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searchState = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _textController,
          autofocus: true,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search songs, artists, albums, genres...',
            border: InputBorder.none,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          onChanged: (val) {
            controller.setQuery(val);
          },
        ),
        actions: [
          if (searchState.query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              tooltip: 'Clear search',
              onPressed: () {
                _textController.clear();
                controller.clearQuery();
              },
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Sort & Filter',
            onPressed: () => SortFilterSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
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
                          label: const Text('All'),
                          selected: searchState.mediaTypeFilter == 'all',
                          onSelected: (_) => controller.setMediaTypeFilter('all'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Music'),
                          selected: searchState.mediaTypeFilter == 'audio',
                          onSelected: (_) => controller.setMediaTypeFilter('audio'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Videos'),
                          selected: searchState.mediaTypeFilter == 'video',
                          onSelected: (_) => controller.setMediaTypeFilter('video'),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => SortFilterSheet.show(context),
                  icon: Icon(
                    searchState.sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                  ),
                  label: Text(searchState.sortOption.label),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Results list
          Expanded(
            child: searchResultsAsync.when(
              data: (items) {
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
                              Icons.search_off_rounded,
                              size: 56,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            searchState.query.isEmpty
                                ? 'Type to search your media library'
                                : 'No results found for "${searchState.query}"',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchState.query.isEmpty
                                ? 'Search by title, artist name, album, or genre.'
                                : 'Try checking for typos or searching with different keywords.',
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

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return MediaItemTile(
                      item: item,
                      onTap: () {
                        ref.read(musicPlayerControllerProvider.notifier).playItem(
                              item,
                              queue: items,
                            );
                      },
                      onMoreTap: () => AddToPlaylistDialog.show(context, item),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error performing search: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
