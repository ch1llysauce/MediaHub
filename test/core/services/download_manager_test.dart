import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediahub/core/services/downloader/download_manager.dart';
import 'package:mediahub/core/services/downloader/media_source_provider.dart';
import 'package:mediahub/domain/entities/download_task_entity.dart';

void main() {
  group('DownloadManager Filename Sanitizer Tests', () {
    test('sanitizeFilename removes path traversal and dangerous characters', () {
      final result = DownloadManager.sanitizeFilename('../../etc/passwd', '.mp4');
      expect(result.contains('..'), isFalse);
      expect(result.contains('/'), isFalse);
      expect(result.endsWith('.mp4'), isTrue);
    });

    test('sanitizeFilename handles special characters cleanly', () {
      final result = DownloadManager.sanitizeFilename('my:video?name*', '.mp3');
      expect(result, equals('my_video_name_.mp3'));
    });

    test('sanitizeFilename provides fallback when name is empty', () {
      final result = DownloadManager.sanitizeFilename('', '.mp4');
      expect(result.startsWith('media_'), isTrue);
      expect(result.endsWith('.mp4'), isTrue);
    });

    test('generateUniqueDestinationPathAndTitle increments index when file exists', () {
      final tempDir = Directory.systemTemp.createTempSync('mediahub_test_dl_');
      try {
        final res1 = DownloadManager.generateUniqueDestinationPathAndTitle(
          tempDir.path,
          'Test Track',
          '.mp3',
        );
        expect(res1.uniqueTitle, equals('Test Track'));
        expect(res1.targetPath.endsWith('Test Track.mp3'), isTrue);

        // Create dummy file for Test Track.mp3
        File(res1.targetPath).writeAsStringSync('dummy content');

        final res2 = DownloadManager.generateUniqueDestinationPathAndTitle(
          tempDir.path,
          'Test Track',
          '.mp3',
        );
        expect(res2.uniqueTitle, equals('Test Track (1)'));
        expect(res2.targetPath.endsWith('Test Track (1).mp3'), isTrue);

        // Create dummy file for Test Track (1).mp3
        File(res2.targetPath).writeAsStringSync('dummy content');

        final res3 = DownloadManager.generateUniqueDestinationPathAndTitle(
          tempDir.path,
          'Test Track',
          '.mp3',
        );
        expect(res3.uniqueTitle, equals('Test Track (2)'));
        expect(res3.targetPath.endsWith('Test Track (2).mp3'), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
    test('isTaskAudio accurately detects audio tasks from mediaType, pending path, or extension', () {
      final audioTask1 = DownloadTaskEntity(
        id: '1',
        url: 'https://youtube.com/watch?v=123',
        destinationPath: '/downloads/song.mp3',
        status: DownloadStatus.failed,
        progress: 0,
        bytesDownloaded: 0,
        totalBytes: 0,
        createdAt: DateTime.now(),
        mediaType: 'audio',
      );
      expect(DownloadManager.isTaskAudio(audioTask1), isTrue);

      final audioTask2 = DownloadTaskEntity(
        id: '2',
        url: 'https://youtube.com/watch?v=123',
        destinationPath: '/downloads/pending_audio_2',
        status: DownloadStatus.failed,
        progress: 0,
        bytesDownloaded: 0,
        totalBytes: 0,
        createdAt: DateTime.now(),
      );
      expect(DownloadManager.isTaskAudio(audioTask2), isTrue);

      final videoTask = DownloadTaskEntity(
        id: '3',
        url: 'https://youtube.com/watch?v=123',
        destinationPath: '/downloads/pending_3',
        status: DownloadStatus.failed,
        progress: 0,
        bytesDownloaded: 0,
        totalBytes: 0,
        createdAt: DateTime.now(),
      );
      expect(DownloadManager.isTaskAudio(videoTask), isFalse);
    });
  });

  group('DownloadStatus Enum Tests', () {
    test('fromString accurately converts string to DownloadStatus', () {
      expect(DownloadStatus.fromString('queued'), equals(DownloadStatus.queued));
      expect(DownloadStatus.fromString('downloading'), equals(DownloadStatus.downloading));
      expect(DownloadStatus.fromString('completed'), equals(DownloadStatus.completed));
      expect(DownloadStatus.fromString('failed'), equals(DownloadStatus.failed));
      expect(DownloadStatus.fromString('cancelled'), equals(DownloadStatus.cancelled));
      expect(DownloadStatus.fromString('unknown'), equals(DownloadStatus.queued));
    });
  });

  group('MediaSourceProvider Matcher Tests', () {
    final directProvider = DirectMediaSourceProvider();
    final youtubeProvider = YoutubeSourceProvider();
    final socialProvider = GenericSocialMediaProvider();

    test('DirectMediaSourceProvider handles direct audio and video URLs', () {
      expect(directProvider.canHandle(Uri.parse('https://example.com/song.mp3')), isTrue);
      expect(directProvider.canHandle(Uri.parse('https://example.com/clip.mp4')), isTrue);
      expect(directProvider.canHandle(Uri.parse('https://example.com/page.html')), isFalse);
    });

    test('YoutubeSourceProvider handles YouTube and Youtu.be URLs', () {
      expect(youtubeProvider.canHandle(Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ')), isTrue);
      expect(youtubeProvider.canHandle(Uri.parse('https://youtu.be/dQw4w9WgXcQ')), isTrue);
      expect(youtubeProvider.canHandle(Uri.parse('https://example.com/video')), isFalse);
    });

    final tiktokProvider = TikTokSourceProvider();
    final instagramProvider = InstagramSourceProvider();
    final twitterProvider = TwitterSourceProvider();
    final facebookProvider = FacebookSourceProvider();

    test('TikTokSourceProvider handles TikTok URLs', () {
      expect(tiktokProvider.canHandle(Uri.parse('https://www.tiktok.com/@user/video/123456')), isTrue);
      expect(tiktokProvider.canHandle(Uri.parse('https://vt.tiktok.com/ZS12345/')), isTrue);
      expect(tiktokProvider.canHandle(Uri.parse('https://example.com/video')), isFalse);
    });

    test('InstagramSourceProvider handles Instagram URLs', () {
      expect(instagramProvider.canHandle(Uri.parse('https://www.instagram.com/reel/C12345/')), isTrue);
      expect(instagramProvider.canHandle(Uri.parse('https://instagr.am/p/C12345/')), isTrue);
      expect(instagramProvider.canHandle(Uri.parse('https://example.com/video')), isFalse);
    });

    test('InstagramSourceProvider handles mobile and share URLs', () {
      expect(instagramProvider.canHandle(Uri.parse('https://m.instagram.com/reel/C12345/')), isTrue);
      expect(instagramProvider.canHandle(Uri.parse('https://www.instagram.com/share/reel/C12345/')), isTrue);
    });

    test('TwitterSourceProvider handles Twitter and X URLs', () {
      expect(twitterProvider.canHandle(Uri.parse('https://twitter.com/user/status/123456789')), isTrue);
      expect(twitterProvider.canHandle(Uri.parse('https://x.com/user/status/123456789')), isTrue);
      expect(twitterProvider.canHandle(Uri.parse('https://vxtwitter.com/user/status/123456789')), isTrue);
      expect(twitterProvider.canHandle(Uri.parse('https://example.com/video')), isFalse);
    });

    test('FacebookSourceProvider handles Facebook URLs', () {
      expect(facebookProvider.canHandle(Uri.parse('https://www.facebook.com/watch/?v=12345')), isTrue);
      expect(facebookProvider.canHandle(Uri.parse('https://fb.watch/12345/')), isTrue);
      expect(facebookProvider.canHandle(Uri.parse('https://example.com/video')), isFalse);
    });

    test('GenericSocialMediaProvider handles Instagram, X, TikTok, and Facebook URLs', () {
      expect(socialProvider.canHandle(Uri.parse('https://www.instagram.com/reel/C12345/')), isTrue);
      expect(socialProvider.canHandle(Uri.parse('https://x.com/user/status/12345678')), isTrue);
      expect(socialProvider.canHandle(Uri.parse('https://www.tiktok.com/@user/video/12345')), isTrue);
      expect(socialProvider.canHandle(Uri.parse('https://www.facebook.com/watch/?v=12345')), isTrue);
    });
  });
}
