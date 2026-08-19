import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediahub/core/services/media_scanner_service.dart';

void main() {
  late MediaScannerService scannerService;

  setUp(() {
    scannerService = MediaScannerService();
  });

  test('isSupportedMediaFile correctly identifies audio and video formats', () {
    expect(scannerService.isSupportedMediaFile('track.mp3'), isTrue);
    expect(scannerService.isSupportedMediaFile('song.flac'), isTrue);
    expect(scannerService.isSupportedMediaFile('video.mp4'), isTrue);
    expect(scannerService.isSupportedMediaFile('clip.mkv'), isTrue);

    expect(scannerService.isSupportedMediaFile('document.pdf'), isFalse);
    expect(scannerService.isSupportedMediaFile('executable.exe'), isFalse);
    expect(scannerService.isSupportedMediaFile('notes.txt'), isFalse);
  });

  test('getMediaType accurately classifies audio vs video', () {
    expect(scannerService.getMediaType('audio.mp3'), equals('audio'));
    expect(scannerService.getMediaType('audio.m4a'), equals('audio'));
    expect(scannerService.getMediaType('video.mp4'), equals('video'));
    expect(scannerService.getMediaType('video.webm'), equals('video'));
  });

  test('scanDirectories parses mock directory and extracts fallback title', () async {
    final tempDir = await Directory.systemTemp.createTemp('mediahub_scan_test');

    final audioFile = File('${tempDir.path}/sample_track.mp3');
    await audioFile.writeAsString('mock audio content');

    final videoFile = File('${tempDir.path}/sample_video.mp4');
    await videoFile.writeAsString('mock video content');

    final txtFile = File('${tempDir.path}/readme.txt');
    await txtFile.writeAsString('unsupported text file');

    final discovered = await scannerService.scanDirectories([tempDir.path]);

    expect(discovered.length, equals(2));

    final titles = discovered.map((f) => f.title).toList();
    expect(titles, contains('sample_track'));
    expect(titles, contains('sample_video'));

    await tempDir.delete(recursive: true);
  });
}
