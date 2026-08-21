enum DownloadStatus {
  queued,
  resolving,
  downloading,
  paused,
  completed,
  failed,
  cancelled;

  static DownloadStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'queued':
        return DownloadStatus.queued;
      case 'resolving':
        return DownloadStatus.resolving;
      case 'downloading':
        return DownloadStatus.downloading;
      case 'paused':
        return DownloadStatus.paused;
      case 'completed':
        return DownloadStatus.completed;
      case 'failed':
        return DownloadStatus.failed;
      case 'cancelled':
        return DownloadStatus.cancelled;
      default:
        return DownloadStatus.queued;
    }
  }

  String toDbString() => name;
}

class DownloadTaskEntity {
  final String id;
  final String url;
  final String destinationPath;
  final DownloadStatus status;
  final double progress;
  final int bytesDownloaded;
  final int totalBytes;
  final String? errorMessage;
  final DateTime createdAt;
  final String? title;
  final String? mediaType;
  final int retryCount;
  final int maxRetries;

  const DownloadTaskEntity({
    required this.id,
    required this.url,
    required this.destinationPath,
    required this.status,
    required this.progress,
    required this.bytesDownloaded,
    required this.totalBytes,
    this.errorMessage,
    required this.createdAt,
    this.title,
    this.mediaType,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  bool get isActive =>
      status == DownloadStatus.queued ||
      status == DownloadStatus.resolving ||
      status == DownloadStatus.downloading;

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isPaused => status == DownloadStatus.paused;

  DownloadTaskEntity copyWith({
    String? id,
    String? url,
    String? destinationPath,
    DownloadStatus? status,
    double? progress,
    int? bytesDownloaded,
    int? totalBytes,
    String? errorMessage,
    DateTime? createdAt,
    String? title,
    String? mediaType,
    int? retryCount,
    int? maxRetries,
  }) {
    return DownloadTaskEntity(
      id: id ?? this.id,
      url: url ?? this.url,
      destinationPath: destinationPath ?? this.destinationPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      mediaType: mediaType ?? this.mediaType,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }
}
