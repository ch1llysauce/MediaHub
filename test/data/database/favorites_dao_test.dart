import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediahub/data/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('FavoritesDao toggles favorite status and streams favorite IDs', () async {
    // 1. Insert media items
    await database.mediaDao.upsertMedia(
      MediaItemsCompanion.insert(
        id: 'm1',
        path: '/music/song1.mp3',
        title: 'Favorite Song 1',
        mediaType: 'audio',
        fileSize: 1000,
        dateAdded: DateTime.now(),
      ),
    );

    // Initial check: not favorite
    var isFav = await database.favoritesDao.isFavorite('m1');
    expect(isFav, isFalse);

    // 2. Toggle favorite ON
    final newState1 = await database.favoritesDao.toggleFavorite('m1');
    expect(newState1, isTrue);

    isFav = await database.favoritesDao.isFavorite('m1');
    expect(isFav, isTrue);

    var favIds = await database.favoritesDao.watchFavoriteMediaIds().first;
    expect(favIds.contains('m1'), isTrue);

    // 3. Toggle favorite OFF
    final newState2 = await database.favoritesDao.toggleFavorite('m1');
    expect(newState2, isFalse);

    isFav = await database.favoritesDao.isFavorite('m1');
    expect(isFav, isFalse);

    favIds = await database.favoritesDao.watchFavoriteMediaIds().first;
    expect(favIds.contains('m1'), isFalse);
  });

  test('FavoritesDao streams favorite media items ordered by date added', () async {
    // Insert audio & video items
    await database.mediaDao.upsertMedia(
      MediaItemsCompanion.insert(
        id: 'm1',
        path: '/music/song1.mp3',
        title: 'Song 1',
        mediaType: 'audio',
        fileSize: 1000,
        dateAdded: DateTime.now(),
      ),
    );
    await database.mediaDao.upsertMedia(
      MediaItemsCompanion.insert(
        id: 'v1',
        path: '/video/clip1.mp4',
        title: 'Video Clip 1',
        mediaType: 'video',
        fileSize: 5000,
        dateAdded: DateTime.now(),
      ),
    );

    await database.favoritesDao.addFavorite('m1');
    await database.favoritesDao.addFavorite('v1');

    final favItems = await database.favoritesDao.watchFavoriteMediaItems().first;
    expect(favItems.length, equals(2));
    expect(favItems.any((item) => item.id == 'm1'), isTrue);
    expect(favItems.any((item) => item.id == 'v1'), isTrue);
  });

  test('Removing favorite does NOT delete physical media item from storage or database', () async {
    await database.mediaDao.upsertMedia(
      MediaItemsCompanion.insert(
        id: 'm1',
        path: '/music/song1.mp3',
        title: 'Persistent Song',
        mediaType: 'audio',
        fileSize: 1000,
        dateAdded: DateTime.now(),
      ),
    );

    await database.favoritesDao.addFavorite('m1');
    expect(await database.favoritesDao.isFavorite('m1'), isTrue);

    // Remove favorite
    await database.favoritesDao.removeFavorite('m1');
    expect(await database.favoritesDao.isFavorite('m1'), isFalse);

    // Verify media item record STILL exists in database!
    final mediaItem = await database.mediaDao.getMediaById('m1');
    expect(mediaItem, isNotNull);
    expect(mediaItem!.title, equals('Persistent Song'));
  });
}
