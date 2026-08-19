import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/database/app_database.dart';

/// Supported audio extensions
const Set<String> kSupportedAudioExtensions = {
  '.mp3',
  '.m4a',
  '.flac',
  '.wav',
  '.aac',
  '.ogg',
};

/// Supported video extensions
const Set<String> kSupportedVideoExtensions = {
  '.mp4',
  '.mkv',
  '.avi',
  '.mov',
  '.webm',
};

class ScannedMediaFile {
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? duration; // seconds
  final String mediaType; // 'audio' or 'video'
  final int fileSize;

  ScannedMediaFile({
    required this.path,
    required this.title,
    this.artist,
    this.album,
    this.genre,
    this.duration,
    required this.mediaType,
    required this.fileSize,
  });
}

class MediaScannerService {

  /// Determine if a file path is a supported media format
  bool isSupportedMediaFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return kSupportedAudioExtensions.contains(ext) || kSupportedVideoExtensions.contains(ext);
  }

  /// Get media type string ('audio' or 'video')
  String getMediaType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    if (kSupportedVideoExtensions.contains(ext)) {
      return 'video';
    }
    return 'audio';
  }

  /// Scan directories recursively and return discovered media items
  Future<List<ScannedMediaFile>> scanDirectories(List<String> directoryPaths) async {
    final List<ScannedMediaFile> discoveredFiles = [];

    for (final dirPath in directoryPaths) {
      final directory = Directory(dirPath);

      if (!await directory.exists()) {
        continue;
      }

      try {
        await for (final entity in directory.list(recursive: true, followLinks: false)) {
          if (entity is File && isSupportedMediaFile(entity.path)) {
            try {
              final file = entity;
              final stat = await file.stat();
              final mediaType = getMediaType(file.path);

              // Extract title fallback from filename if ID3 tags are omitted
              final fallbackTitle = p.basenameWithoutExtension(file.path);

              discoveredFiles.add(
                ScannedMediaFile(
                  path: file.path,
                  title: fallbackTitle,
                  mediaType: mediaType,
                  fileSize: stat.size,
                ),
              );
            } catch (_) {
              // Ignore individual unreadable/corrupted files safely
            }
          }
        }
      } catch (_) {
        // Ignore folder permission errors cleanly
      }
    }

    return discoveredFiles;
  }

  /// Convert scanned file into Drift MediaItemsCompanion for DB insertion
  MediaItemsCompanion toCompanion(ScannedMediaFile file) {
    // Generate deterministic id from path string
    final id = file.path.hashCode.abs().toString();

    return MediaItemsCompanion.insert(
      id: id,
      path: file.path,
      title: file.title,
      artist: Value(file.artist),
      album: Value(file.album),
      genre: Value(file.genre),
      duration: Value(file.duration),
      mediaType: file.mediaType,
      fileSize: file.fileSize,
      dateAdded: DateTime.now(),
      isAvailable: const Value(true),
    );
  }
}
