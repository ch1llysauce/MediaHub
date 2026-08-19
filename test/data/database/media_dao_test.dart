import 'package:drift/drift.dart' hide isNotNull;
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

  test('MediaDao inserts and queries media item by ID', () async {
    final companion = MediaItemsCompanion.insert(
      id: '1',
      path: '/storage/music/song1.mp3',
      title: 'Song 1',
      artist: const Value('Artist A'),
      album: const Value('Album X'),
      mediaType: 'audio',
      fileSize: 1024,
      dateAdded: DateTime.now(),
    );

    await database.mediaDao.upsertMedia(companion);

    final item = await database.mediaDao.getMediaById('1');

    expect(item, isNotNull);
    expect(item!.title, equals('Song 1'));
    expect(item.artist, equals('Artist A'));
    expect(item.mediaType, equals('audio'));
  });

  test('MediaDao filters media by type (audio vs video)', () async {
    await database.mediaDao.upsertMedia(
      MediaItemsCompanion.insert(
        id: '1',
        path: '/storage/music/audio.mp3',
        title: 'Audio Track',
        mediaType: 'audio',
        fileSize: 2048,
        dateAdded: DateTime.now(),
      ),
    );

    await database.mediaDao.upsertMedia(
      MediaItemsCompanion.insert(
        id: '2',
        path: '/storage/videos/video.mp4',
        title: 'Video Clip',
        mediaType: 'video',
        fileSize: 4096,
        dateAdded: DateTime.now(),
      ),
    );

    final audioList = await database.mediaDao.getMediaByType('audio');
    final videoList = await database.mediaDao.getMediaByType('video');

    expect(audioList.length, equals(1));
    expect(audioList.first.title, equals('Audio Track'));

    expect(videoList.length, equals(1));
    expect(videoList.first.title, equals('Video Clip'));
  });

  test('MediaDao marks missing files unavailable', () async {
    await database.mediaDao.upsertMedia(
      MediaItemsCompanion.insert(
        id: '1',
        path: '/storage/music/existing.mp3',
        title: 'Existing',
        mediaType: 'audio',
        fileSize: 1024,
        dateAdded: DateTime.now(),
      ),
    );

    await database.mediaDao.upsertMedia(
      MediaItemsCompanion.insert(
        id: '2',
        path: '/storage/music/deleted.mp3',
        title: 'Deleted File',
        mediaType: 'audio',
        fileSize: 1024,
        dateAdded: DateTime.now(),
      ),
    );

    // Only 'existing.mp3' was scanned
    await database.mediaDao.markMissingFiles(['/storage/music/existing.mp3']);

    final allMedia = await database.mediaDao.getAllMedia();

    expect(allMedia.length, equals(1));
    expect(allMedia.first.path, equals('/storage/music/existing.mp3'));
  });
}
