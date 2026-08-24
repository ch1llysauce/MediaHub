import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final int selectedTabIndex; // 0: All, 1: Music, 2: Videos, 3: Folders

  const SearchState({
    this.query = '',
    this.mediaTypeFilter = 'all',
    this.sortOption = MediaSortOption.dateAdded,
    this.sortAscending = false,
    this.selectedTabIndex = 0,
  });

  SearchState copyWith({
    String? query,
    String? mediaTypeFilter,
    MediaSortOption? sortOption,
    bool? sortAscending,
    int? selectedTabIndex,
  }) {
    return SearchState(
      query: query ?? this.query,
      mediaTypeFilter: mediaTypeFilter ?? this.mediaTypeFilter,
      sortOption: sortOption ?? this.sortOption,
      sortAscending: sortAscending ?? this.sortAscending,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  static const _selectedTabKey = 'library.selectedTab';
  static const _sortOptionKey = 'library.sortOption';
  static const _sortAscendingKey = 'library.sortAscending';
  static const _mediaTypeFilterKey = 'library.mediaTypeFilter';

  SearchController() : super(const SearchState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTab = prefs.getInt(_selectedTabKey) ?? 0;
    final savedFilter = prefs.getString(_mediaTypeFilterKey) ?? 'all';
    final savedSortIndex = prefs.getInt(_sortOptionKey);
    final savedAscending = prefs.getBool(_sortAscendingKey) ?? false;

    MediaSortOption sortOpt = MediaSortOption.dateAdded;
    if (savedSortIndex != null &&
        savedSortIndex >= 0 &&
        savedSortIndex < MediaSortOption.values.length) {
      sortOpt = MediaSortOption.values[savedSortIndex];
    }

    state = state.copyWith(
      selectedTabIndex: savedTab.clamp(0, 3),
      mediaTypeFilter: savedFilter,
      sortOption: sortOpt,
      sortAscending: savedAscending,
    );
  }

  Future<void> setTabIndex(int index) async {
    state = state.copyWith(selectedTabIndex: index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedTabKey, index);
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  Future<void> setMediaTypeFilter(String filter) async {
    state = state.copyWith(mediaTypeFilter: filter);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mediaTypeFilterKey, filter);
  }

  Future<void> setSortOption(MediaSortOption option) async {
    final newAscending =
        state.sortOption == option ? !state.sortAscending : true;
    state = state.copyWith(sortOption: option, sortAscending: newAscending);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortOptionKey, option.index);
    await prefs.setBool(_sortAscendingKey, newAscending);
  }

  Future<void> setSortAscending(bool ascending) async {
    state = state.copyWith(sortAscending: ascending);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sortAscendingKey, ascending);
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
  SearchState searchState, {
  bool applyQueryFilter = true,
  bool applyMediaTypeFilter = true,
}) {
  final query = applyQueryFilter ? searchState.query.trim().toLowerCase() : '';

  var filtered = items.where((item) {
    if (applyMediaTypeFilter) {
      if (searchState.mediaTypeFilter == 'audio' && item.mediaType != 'audio') return false;
      if (searchState.mediaTypeFilter == 'video' && item.mediaType != 'video') return false;
    }

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
