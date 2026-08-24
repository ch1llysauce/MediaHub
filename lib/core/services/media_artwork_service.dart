import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart'; 
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class MediaArtworkService {
  Future<Directory> _getArtworkDirectory() async {
    final cacheDir = await getApplicationCacheDirectory();
    final artworkDir = Directory(p.join(cacheDir.path, 'artwork'));
    if (!await artworkDir.exists()) {
      await artworkDir.create(recursive: true);
    }
    return artworkDir;
  }

  /// Fast check if artwork is already cached on disk without performing heavy extraction
  Future<String?> getCachedArtworkIfPresent(String mediaId) async {
    try {
      final artworkDir = await _getArtworkDirectory();
      final outputPath = p.join(artworkDir.path, '$mediaId.jpg');
      if (await File(outputPath).exists()) {
        return outputPath;
      }
    } catch (_) {}
    return null;
  }

  /// Main entry point 
  Future<String?> extractArtwork({
    required String filePath,
    required String mediaId,
    required String mediaType,
  }) async {
    try {
      if (mediaType == 'video') {
        return await _generateVideoThumbnail(filePath, mediaId);
      } else {
        return await _extractAudioArtwork(filePath, mediaId);
      }
    } catch (_) {
      return null; 
    }
  }

  Future<String?> _generateVideoThumbnail(String videoPath, String mediaId) async {
    final artworkDir = await _getArtworkDirectory();
    final outputPath = p.join(artworkDir.path, '$mediaId.jpg');

    // Kung meron nang naka-cache dati, wag na ulitin
    if (await File(outputPath).exists()) {
      return outputPath;
    }

    final thumbPath = await vt.VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: artworkDir.path,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 400,
      quality: 75,
    );

    if (thumbPath != null && await File(thumbPath).exists()) {
      if (thumbPath != outputPath) {
        final renamed = await File(thumbPath).rename(outputPath);
        return renamed.path;
      }
      return thumbPath;
    }
    return null;
  }

  Future<String?> _extractAudioArtwork(String audioPath, String mediaId) async {
  final artworkDir = await _getArtworkDirectory();
  final outputPath = p.join(artworkDir.path, '$mediaId.jpg');

  if (await File(outputPath).exists()) {
    return outputPath;
  }

  final metadata = readMetadata(File(audioPath), getImage: true);
  final picture = metadata.pictures.isNotEmpty ? metadata.pictures.first : null;

  if (picture == null || picture.bytes.isEmpty) {
    return null;
  }

  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(picture.bytes);
  return outputFile.path;
}
}