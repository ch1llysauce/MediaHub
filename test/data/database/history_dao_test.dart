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

  test('HistoryDao records playback and updates position and timestamp', () async {
    // 1. Insert media item
    await database.mediaDao.upsertMedia(
      MediaItemsCompanion.insert(
        id: 'm1',
        path: '/music/song1.mp3',
        title: 'History Song 1',
        mediaType: 'audio',
        fileSize: 1000,
        dateAdded: DateTime.now(),
      ),
    );

    // Initial position should be 0
    var pos = await database.historyDao.getPlaybackPosition('m1');
    expect(pos, equals(0));

    // Record playback with position 45s
    await database.historyDao.recordPlayback('m1', playbackPosition: 45);

    pos = await database.historyDao.getPlaybackPosition('m1');
    expect(pos, equals(45));

    final historyList = await database.historyDao.watchHistoryMediaItems().first;
    expect(historyList.length, equals(1));
    expect(historyList.first.mediaItem.id, equals('m1'));
    expect(historyList.first.playbackPosition, equals(45));
  });

  test('HistoryDao orders items by lastPlayed DESC', () async {
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
        title: 'Video 1',
        mediaType: 'video',
        fileSize: 5000,
        dateAdded: DateTime.now(),
      ),
    );

    final t1 = DateTime.now().subtract(const Duration(minutes: 10));
    final t2 = DateTime.now().subtract(const Duration(minutes: 5));
    final t3 = DateTime.now();

    await database.historyDao.recordPlayback('m1', playbackPosition: 10, customTimestamp: t1);
    await database.historyDao.recordPlayback('v1', playbackPosition: 90, customTimestamp: t2);

    var historyList = await database.historyDao.watchHistoryMediaItems().first;
    expect(historyList.length, equals(2));
    expect(historyList.first.mediaItem.id, equals('v1')); // most recent first

    // Play m1 again -> m1 moves to top
    await database.historyDao.recordPlayback('m1', playbackPosition: 30, customTimestamp: t3);

    historyList = await database.historyDao.watchHistoryMediaItems().first;
    expect(historyList.first.mediaItem.id, equals('m1'));
    expect(historyList.first.playbackPosition, equals(30));
  });

  test('HistoryDao clearHistory wipes history without deleting physical media items', () async {
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

    await database.historyDao.recordPlayback('m1', playbackPosition: 120);
    var historyList = await database.historyDao.watchHistoryMediaItems().first;
    expect(historyList.length, equals(1));

    // Clear history
    await database.historyDao.clearHistory();
    historyList = await database.historyDao.watchHistoryMediaItems().first;
    expect(historyList.isEmpty, isTrue);

    // Verify media item record still exists in MediaDao
    final item = await database.mediaDao.getMediaById('m1');
    expect(item, isNotNull);
    expect(item!.title, equals('Persistent Song'));
  });
}
