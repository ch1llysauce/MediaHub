import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/media_item_entity.dart';

enum MediaSortOption {
  dateAdded,
  title,
  artist,
  duration,
}

extension MediaSortOptionX on MediaSortOption {
  String get label {
    switch (this) {
      case MediaSortOption.dateAdded:
        return 'Date Added';
      case MediaSortOption.title:
        return 'Title';
      case MediaSortOption.artist:
        return 'Artist';
      case MediaSortOption.duration:
        return 'Duration';
    }
  }
}

class SearchState {
  final String query;
  final String mediaTypeFilter; // 'all', 'audio', 'video'
  final MediaSortOption sortOption;
  final bool sortAscending;

  const SearchState({
    this.query = '',
    this.mediaTypeFilter = 'all',
    this.sortOption = MediaSortOption.dateAdded,
    this.sortAscending = false,
  });

  SearchState copyWith({
    String? query,
    String? mediaTypeFilter,
    MediaSortOption? sortOption,
    bool? sortAscending,
  }) {
    return SearchState(
      query: query ?? this.query,
      mediaTypeFilter: mediaTypeFilter ?? this.mediaTypeFilter,
      sortOption: sortOption ?? this.sortOption,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  SearchController() : super(const SearchState());

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void setMediaTypeFilter(String filter) {
    state = state.copyWith(mediaTypeFilter: filter);
  }

  void setSortOption(MediaSortOption option) {
    if (state.sortOption == option) {
      state = state.copyWith(sortAscending: !state.sortAscending);
    } else {
      state = state.copyWith(sortOption: option, sortAscending: true);
    }
  }

  void setSortAscending(bool ascending) {
    state = state.copyWith(sortAscending: ascending);
  }

  void clearQuery() {
    state = state.copyWith(query: '');
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  return SearchController();
});

List<MediaItemEntity> filterAndSortMediaItems(
  List<MediaItemEntity> items,
  SearchState searchState,
) {
  final query = searchState.query.trim().toLowerCase();

  var filtered = items.where((item) {
    if (searchState.mediaTypeFilter == 'audio' && item.mediaType != 'audio') return false;
    if (searchState.mediaTypeFilter == 'video' && item.mediaType != 'video') return false;

    if (query.isEmpty) return true;

    final titleMatch = item.title.toLowerCase().contains(query);
    final artistMatch = item.artist?.toLowerCase().contains(query) ?? false;
    final albumMatch = item.album?.toLowerCase().contains(query) ?? false;
    final genreMatch = item.genre?.toLowerCase().contains(query) ?? false;

    return titleMatch || artistMatch || albumMatch || genreMatch;
  }).toList();

  filtered.sort((a, b) {
    int comparison = 0;
    switch (searchState.sortOption) {
      case MediaSortOption.title:
        comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        break;
      case MediaSortOption.artist:
        final artistA = a.artist ?? '';
        final artistB = b.artist ?? '';
        comparison = artistA.toLowerCase().compareTo(artistB.toLowerCase());
        break;
      case MediaSortOption.duration:
        final durA = a.duration ?? 0;
        final durB = b.duration ?? 0;
        comparison = durA.compareTo(durB);
        break;
      case MediaSortOption.dateAdded:
        comparison = a.dateAdded.compareTo(b.dateAdded);
        break;
    }
    return searchState.sortAscending ? comparison : -comparison;
  });

  return filtered;
}

/// Provider for filtered & sorted search results across all media
final searchResultsProvider = StreamProvider<List<MediaItemEntity>>((ref) {
  final searchState = ref.watch(searchControllerProvider);
  final allMediaAsync = ref.watch(allMediaStreamProvider);

  return allMediaAsync.when(
    data: (items) => Stream.value(filterAndSortMediaItems(items, searchState)),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});
