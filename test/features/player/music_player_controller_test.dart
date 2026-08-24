import 'package:flutter_test/flutter_test.dart';
import 'package:mediahub/core/services/audio_player_service.dart';
import 'package:mediahub/domain/entities/media_item_entity.dart';
import 'package:mediahub/features/player/presentation/controllers/music_player_controller.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mediahub/domain/repositories/playlist_repository.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}
class MockPlaylistRepository extends Mock implements PlaylistRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  late MockAudioPlayerService mockAudioService;
  late MockPlaylistRepository mockPlaylistRepository;
  late MusicPlayerController controller;

  setUp(() {
    mockAudioService = MockAudioPlayerService();
    mockPlaylistRepository = MockPlaylistRepository();
    when(() => mockAudioService.playerStateStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioService.positionStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioService.durationStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioService.seek(any())).thenAnswer((_) async {});
    when(() => mockAudioService.pause()).thenAnswer((_) async {});
    when(() => mockAudioService.stop()).thenAnswer((_) async {});

    controller = MusicPlayerController(mockAudioService, mockPlaylistRepository);
  });

  test('Initial MusicPlayerState has empty values', () {
    expect(controller.state.activeItem, null);
    expect(controller.state.isPlaying, false);
    expect(controller.state.isShuffle, false);
    expect(controller.state.repeatMode, PlayerRepeatMode.off);
  });

  test('playItem updates activeItem, queue, and index', () async {
    final sampleItem = MediaItemEntity(
      id: '1',
      path: '/music/song.mp3',
      title: 'Test Song',
      artist: 'Test Artist',
      mediaType: 'audio',
      fileSize: 1024,
      dateAdded: DateTime.now(),
    );

    when(() => mockAudioService.setFilePath(any())).thenAnswer((_) async => null);
    when(() => mockAudioService.play()).thenAnswer((_) async {});

    await controller.playItem(sampleItem);

    expect(controller.state.activeItem?.id, '1');
    expect(controller.state.queue.length, 1);
    expect(controller.state.currentIndex, 0);
  });

  test('playItem with playlistId subscribes to watchPlaylistItems and updates queue dynamically', () async {
    final song1 = MediaItemEntity(
      id: '1',
      path: '/music/song1.mp3',
      title: 'Song 1',
      mediaType: 'audio',
      fileSize: 1024,
      dateAdded: DateTime.now(),
    );
    final song2 = MediaItemEntity(
      id: '2',
      path: '/music/song2.mp3',
      title: 'Song 2',
      mediaType: 'audio',
      fileSize: 1024,
      dateAdded: DateTime.now(),
    );

    when(() => mockAudioService.setFilePath(any())).thenAnswer((_) async => null);
    when(() => mockAudioService.play()).thenAnswer((_) async {});
    when(() => mockPlaylistRepository.watchPlaylistItems('p1')).thenAnswer(
      (_) => Stream.fromIterable([
        [song1],
        [song1, song2],
      ]),
    );

    await controller.playItem(song1, queue: [song1], playlistId: 'p1');

    await pumpEventQueue();

    expect(controller.state.activePlaylistId, 'p1');
    expect(controller.state.queue.length, 2);
    expect(controller.state.queue[1].id, '2');
  });

  test('skipToNext stops playback at the end of queue when repeatMode is off', () async {
    final song1 = MediaItemEntity(
      id: '1',
      path: '/music/song1.mp3',
      title: 'Song 1',
      mediaType: 'audio',
      fileSize: 1024,
      dateAdded: DateTime.now(),
    );

    when(() => mockAudioService.setFilePath(any())).thenAnswer((_) async => null);
    when(() => mockAudioService.play()).thenAnswer((_) async {});
    when(() => mockAudioService.stop()).thenAnswer((_) async {});

    await controller.playItem(song1, queue: [song1]);
    expect(controller.state.queue.length, 1);

    await controller.skipToNext();

    expect(controller.state.isPlaying, false);
    verify(() => mockAudioService.stop()).called(1);
  });

  test('peekNextItem returns correct upcoming item and identifies video mediaType', () async {
    final audioSong = MediaItemEntity(
      id: '1',
      path: '/music/song1.mp3',
      title: 'Audio Track',
      mediaType: 'audio',
      fileSize: 1024,
      dateAdded: DateTime.now(),
    );
    final videoFile = MediaItemEntity(
      id: '2',
      path: '/video/clip.mp4',
      title: 'Video Clip',
      mediaType: 'video',
      fileSize: 2048,
      dateAdded: DateTime.now(),
    );

    when(() => mockAudioService.setFilePath(any())).thenAnswer((_) async => null);
    when(() => mockAudioService.play()).thenAnswer((_) async {});

    await controller.playItem(audioSong, queue: [audioSong, videoFile]);

    final upcoming = controller.peekNextItem();
    expect(upcoming, isNotNull);
    expect(upcoming?.id, '2');
    expect(upcoming?.mediaType, 'video');
  });

  test('shufflePlay activates shuffle mode and maintains shuffled indices on skipToNext', () async {
    final s1 = MediaItemEntity(id: '1', path: '/m1.mp3', title: 'S1', mediaType: 'audio', fileSize: 10, dateAdded: DateTime.now());
    final s2 = MediaItemEntity(id: '2', path: '/m2.mp3', title: 'S2', mediaType: 'audio', fileSize: 10, dateAdded: DateTime.now());
    final s3 = MediaItemEntity(id: '3', path: '/m3.mp3', title: 'S3', mediaType: 'audio', fileSize: 10, dateAdded: DateTime.now());

    when(() => mockAudioService.setFilePath(any())).thenAnswer((_) async => null);
    when(() => mockAudioService.play()).thenAnswer((_) async {});

    await controller.shufflePlay([s1, s2, s3], startItem: s1);

    expect(controller.state.isShuffle, true);
    expect(controller.state.activeItem?.id, '1');
    expect(controller.state.shuffledIndices.length, 3);
    expect(controller.state.shuffledIndices.first, 0);

    final nextIndex = controller.state.shuffledIndices[1];
    await controller.skipToNext();

    expect(controller.state.isShuffle, true);
    expect(controller.state.currentIndex, nextIndex);
  });
}
