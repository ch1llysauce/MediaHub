class MediaItemEntity {
  final String id;
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? duration; // in seconds
  final String mediaType; // 'audio' or 'video'
  final String? artworkPath;
  final int fileSize; // in bytes
  final DateTime dateAdded;
  final DateTime? lastPlayed;
  final bool isAvailable;

  const MediaItemEntity({
    required this.id,
    required this.path,
    required this.title,
    this.artist,
    this.album,
    this.genre,
    this.duration,
    required this.mediaType,
    this.artworkPath,
    required this.fileSize,
    required this.dateAdded,
    this.lastPlayed,
    this.isAvailable = true,
  });

  bool get isAudio => mediaType == 'audio';
  bool get isVideo => mediaType == 'video';

  MediaItemEntity copyWith({
    String? id,
    String? path,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? duration,
    String? mediaType,
    String? artworkPath,
    int? fileSize,
    DateTime? dateAdded,
    DateTime? lastPlayed,
    bool? isAvailable,
  }) {
    return MediaItemEntity(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      mediaType: mediaType ?? this.mediaType,
      artworkPath: artworkPath ?? this.artworkPath,
      fileSize: fileSize ?? this.fileSize,
      dateAdded: dateAdded ?? this.dateAdded,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
