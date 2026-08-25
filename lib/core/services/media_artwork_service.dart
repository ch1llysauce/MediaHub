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

    final bytes = await vt.VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 400,
      quality: 75,
    );

    if (bytes != null && bytes.isNotEmpty) {
      final file = File(outputPath);
      await file.writeAsBytes(bytes);
      return outputPath;
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
    // Fallback: Check for common album art files in the same folder
    final parentDir = File(audioPath).parent;
    final possibleCovers = ['cover.jpg', 'Cover.jpg', 'folder.jpg', 'Folder.jpg', 'cover.png', 'albumart.jpg'];
    for (final coverName in possibleCovers) {
      final coverFile = File(p.join(parentDir.path, coverName));
      if (await coverFile.exists()) {
        final copied = await coverFile.copy(outputPath);
        return copied.path;
      }
    }
    return null;
  }

  final outputFile = File(outputPath);
  await outputFile.writeAsBytes(picture.bytes);
  return outputFile.path;
}
}