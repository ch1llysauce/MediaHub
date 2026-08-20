import 'package:flutter_test/flutter_test.dart';
import 'package:mediahub/domain/entities/media_item_entity.dart';
import 'package:mediahub/features/search/presentation/controllers/search_controller.dart';

void main() {
  late List<MediaItemEntity> mockItems;

  setUp(() {
    mockItems = [
      MediaItemEntity(
        id: '1',
        path: '/music/alpha.mp3',
        title: 'Alpha Song',
        artist: 'Band B',
        album: 'First Album',
        genre: 'Pop',
        duration: 180,
        mediaType: 'audio',
        fileSize: 1000,
        dateAdded: DateTime(2026, 1, 1),
        isAvailable: true,
      ),
      MediaItemEntity(
        id: '2',
        path: '/music/beta.mp3',
        title: 'Beta Track',
        artist: 'Band A',
        album: 'Second Album',
        genre: 'Rock',
        duration: 240,
        mediaType: 'audio',
        fileSize: 2000,
        dateAdded: DateTime(2026, 1, 10),
        isAvailable: true,
      ),
      MediaItemEntity(
        id: '3',
        path: '/video/gamma.mp4',
        title: 'Gamma Clip',
        artist: 'Director C',
        album: 'Video Album',
        genre: 'Movie',
        duration: 60,
        mediaType: 'video',
        fileSize: 5000,
        dateAdded: DateTime(2026, 1, 5),
        isAvailable: true,
      ),
    ];
  });

  test('filterAndSortMediaItems filters by search query matching title or artist', () {
    const state = SearchState(query: 'beta');
    final results = filterAndSortMediaItems(mockItems, state);

    expect(results.length, equals(1));
    expect(results.first.title, equals('Beta Track'));
  });

  test('filterAndSortMediaItems filters by mediaType (audio vs video)', () {
    const state = SearchState(mediaTypeFilter: 'video');
    final results = filterAndSortMediaItems(mockItems, state);

    expect(results.length, equals(1));
    expect(results.first.title, equals('Gamma Clip'));
  });

  test('filterAndSortMediaItems sorts by Title ascending and descending', () {
    const stateAsc = SearchState(
      sortOption: MediaSortOption.title,
      sortAscending: true,
    );
    final ascResults = filterAndSortMediaItems(mockItems, stateAsc);
    expect(ascResults.map((e) => e.title).toList(), equals(['Alpha Song', 'Beta Track', 'Gamma Clip']));

    const stateDesc = SearchState(
      sortOption: MediaSortOption.title,
      sortAscending: false,
    );
    final descResults = filterAndSortMediaItems(mockItems, stateDesc);
    expect(descResults.map((e) => e.title).toList(), equals(['Gamma Clip', 'Beta Track', 'Alpha Song']));
  });

  test('filterAndSortMediaItems sorts by Duration ascending', () {
    const state = SearchState(
      sortOption: MediaSortOption.duration,
      sortAscending: true,
    );
    final results = filterAndSortMediaItems(mockItems, state);

    expect(results.map((e) => e.duration).toList(), equals([60, 180, 240]));
  });

  test('SearchController updates state accurately', () {
    final controller = SearchController();
    expect(controller.state.query, isEmpty);

    controller.setQuery('rock');
    expect(controller.state.query, equals('rock'));

    controller.setSortOption(MediaSortOption.duration);
    expect(controller.state.sortOption, equals(MediaSortOption.duration));
    expect(controller.state.sortAscending, isTrue);

    // Toggling same option flips sortAscending
    controller.setSortOption(MediaSortOption.duration);
    expect(controller.state.sortAscending, isFalse);

    controller.clearQuery();
    expect(controller.state.query, isEmpty);
  });
}
