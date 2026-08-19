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

  test('PlaylistsDao creates, renames, and queries playlists', () async {
    final playlist = PlaylistsCompanion.insert(
      id: 'p1',
      name: 'Rock Classics',
      createdAt: DateTime.now(),
    );

    await database.playlistsDao.createPlaylist(playlist);

    var fetched = await database.playlistsDao.getPlaylistById('p1');
    expect(fetched, isNotNull);
    expect(fetched!.name, equals('Rock Classics'));

    await database.playlistsDao.renamePlaylist('p1', 'Heavy Metal');
    fetched = await database.playlistsDao.getPlaylistById('p1');
    expect(fetched!.name, equals('Heavy Metal'));
  });

  test('PlaylistsDao adds items and streams playlist items in sortOrder', () async {
    // 1. Insert 2 media items
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
        id: 'm2',
        path: '/music/song2.mp3',
        title: 'Song 2',
        mediaType: 'audio',
        fileSize: 2000,
        dateAdded: DateTime.now(),
      ),
    );

    // 2. Create playlist
    await database.playlistsDao.createPlaylist(
      PlaylistsCompanion.insert(
        id: 'p1',
        name: 'My Playlist',
        createdAt: DateTime.now(),
      ),
    );

    // 3. Add items to playlist
    await database.playlistsDao.addMediaToPlaylist('p1', 'm1');
    await database.playlistsDao.addMediaToPlaylist('p1', 'm2');

    // 4. Watch playlist items
    final items = await database.playlistsDao.watchPlaylistItems('p1').first;
    expect(items.length, equals(2));
    expect(items[0].id, equals('m1'));
    expect(items[1].id, equals('m2'));
  });

  test('PlaylistsDao reorders playlist items', () async {
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
        id: 'm2',
        path: '/music/song2.mp3',
        title: 'Song 2',
        mediaType: 'audio',
        fileSize: 2000,
        dateAdded: DateTime.now(),
      ),
    );

    await database.playlistsDao.createPlaylist(
      PlaylistsCompanion.insert(
        id: 'p1',
        name: 'My Playlist',
        createdAt: DateTime.now(),
      ),
    );

    await database.playlistsDao.addMediaToPlaylist('p1', 'm1');
    await database.playlistsDao.addMediaToPlaylist('p1', 'm2');

    // Reorder: m2 first, then m1
    await database.playlistsDao.reorderPlaylistItems('p1', ['m2', 'm1']);

    final items = await database.playlistsDao.watchPlaylistItems('p1').first;
    expect(items[0].id, equals('m2'));
    expect(items[1].id, equals('m1'));
  });

  test('PlaylistsDao deletes playlist & item links WITHOUT deleting media item records', () async {
    // 1. Insert media item
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

    // 2. Create playlist & add item
    await database.playlistsDao.createPlaylist(
      PlaylistsCompanion.insert(
        id: 'p1',
        name: 'Temporary Playlist',
        createdAt: DateTime.now(),
      ),
    );
    await database.playlistsDao.addMediaToPlaylist('p1', 'm1');

    // 3. Remove item from playlist
    await database.playlistsDao.removeMediaFromPlaylist('p1', 'm1');
    var items = await database.playlistsDao.watchPlaylistItems('p1').first;
    expect(items.isEmpty, isTrue);

    // Verify media item record still exists in database!
    var mediaItem = await database.mediaDao.getMediaById('m1');
    expect(mediaItem, isNotNull);
    expect(mediaItem!.title, equals('Song 1'));

    // 4. Delete playlist entirely
    await database.playlistsDao.deletePlaylist('p1');
    final playlist = await database.playlistsDao.getPlaylistById('p1');
    expect(playlist, isNull);

    // Verify media item record STILL exists in database!
    mediaItem = await database.mediaDao.getMediaById('m1');
    expect(mediaItem, isNotNull);
  });
}
