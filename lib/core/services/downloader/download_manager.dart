import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/download_task_entity.dart';
import '../../../domain/repositories/download_repository.dart';
import '../../../domain/repositories/media_repository.dart';
import 'media_source_provider.dart';

class DownloadManager {
  final DownloadRepository _downloadRepository;
  final MediaRepository _mediaRepository;
  final Dio _dio;
  final List<MediaSourceProvider> _providers;
  final Map<String, CancelToken> _cancelTokens = {};
  final Set<String> _pauseRequested = {};

  DownloadManager({
    required DownloadRepository downloadRepository,
    required MediaRepository mediaRepository,
    Dio? dio,
    List<MediaSourceProvider>? providers,
  }) : _downloadRepository = downloadRepository,
       _mediaRepository = mediaRepository,
       _dio = dio ?? Dio(),
       _providers =
           providers ??
           [
             DirectMediaSourceProvider(),
             YoutubeSourceProvider(),
             TikTokSourceProvider(),
             InstagramSourceProvider(),
             FacebookSourceProvider(),
             GenericSocialMediaProvider(),
           ];

  /// Utility to sanitize file names to prevent path traversal attacks (../) and illegal characters
  static String sanitizeFilename(String name, String ext) {
    var safeName = name.replaceAll(RegExp(r'[\\/:*?"<>|.]'), '_').trim();
    if (safeName.isEmpty) {
      safeName = 'media_${DateTime.now().millisecondsSinceEpoch}';
    }
    return '$safeName$ext';
  }

  /// Get the app's designated download folder path.
  /// Respects a user-configured directory from Settings when present.
  Future<String> getDownloadDirectory() async {
    final userConfigured = await _getConfiguredDownloadDirectory();
    if (userConfigured != null && userConfigured.isNotEmpty) {
      try {
        final dir = Directory(userConfigured);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return userConfigured;
      } catch (_) {
        // Fall back to default if the configured path can't be created
      }
    }

    if (Platform.isAndroid) {
      final publicDownloadDir = Directory(
        '/storage/emulated/0/Download/MediaHub',
      );
      try {
        if (!await publicDownloadDir.exists()) {
          await publicDownloadDir.create(recursive: true);
        }
        return publicDownloadDir.path;
      } catch (_) {}
    }

    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(p.join(appDir.path, 'MediaHub_Downloads'));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<String?> _getConfiguredDownloadDirectory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('settings.downloadDirectory');
      return (saved != null && saved.isNotEmpty) ? saved : null;
    } catch (_) {
      return null;
    }
  }

  /// Resolve media info (thumbnail, title, streams, qualities) before downloading
  Future<MediaSourceInfo> resolveSourceInfo(
    String urlString, {
    bool audioOnly = false,
  }) async {
    final uri = Uri.parse(urlString.trim());
    final provider = _providers.firstWhere(
      (p) => p.canHandle(uri),
      orElse: () => DirectMediaSourceProvider(),
    );
    return await provider.resolve(uri, audioOnly: audioOnly);
  }

  /// Enqueue and start a new URL download
  Future<String> startDownload(
    String urlString, {
    bool audioOnly = false,
    String? customTitle,
    String? customStreamUrl,
  }) async {
    final uri = Uri.parse(urlString.trim());
    final taskId =
        'dl_${DateTime.now().millisecondsSinceEpoch}_${uri.hashCode.abs()}';
    final downloadFolder = await getDownloadDirectory();

    // Find provider
    final provider = _providers.firstWhere(
      (p) => p.canHandle(uri),
      orElse: () => DirectMediaSourceProvider(),
    );

    // Initial queued task
    final initialTask = DownloadTaskEntity(
      id: taskId,
      url: urlString,
      title: customTitle,
      destinationPath: p.join(downloadFolder, 'pending_$taskId'),
      status: DownloadStatus.resolving,
      progress: 0.0,
      bytesDownloaded: 0,
      totalBytes: 0,
      createdAt: DateTime.now(),
    );

    await _downloadRepository.saveTask(initialTask);
    unawaited(
      _executeDownloadTask(
        taskId,
        uri,
        provider,
        downloadFolder,
        audioOnly: audioOnly,
        customTitle: customTitle,
        customStreamUrl: customStreamUrl,
      ),
    );
    return taskId;
  }

  /// Execute resolution and HTTP stream downloading in background
  Future<void> _executeDownloadTask(
    String taskId,
    Uri uri,
    MediaSourceProvider provider,
    String downloadFolder, {
    bool audioOnly = false,
    String? customTitle,
    String? customStreamUrl,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    try {
      await _downloadRepository.updateStatus(taskId, DownloadStatus.resolving);

      final MediaSourceInfo mediaInfo;

      if (customStreamUrl != null && customStreamUrl.isNotEmpty) {
        mediaInfo = MediaSourceInfo(
          title: customTitle ?? 'Download Media',
          streamUrl: customStreamUrl,
          mediaType: audioOnly ? 'audio' : 'video',
          fileExtension: audioOnly ? '.mp3' : '.mp4',
        );
      } else {
        mediaInfo = await provider.resolve(uri, audioOnly: audioOnly);
      }

      if (cancelToken.isCancelled) return;

      final existingTask = await _downloadRepository.getTaskById(taskId);

      if (existingTask == null) return;

      /*
     * IMPORTANT:
     * If this task already has a real destination path, preserve it.
     * This is what allows pause/resume to continue the same file.
     */
      String targetPath;
      String uniqueTitle;

      final existingPath = existingTask.destinationPath;
      final existingFile = File(existingPath);

      if (existingTask.status == DownloadStatus.paused &&
          await existingFile.exists() &&
          !existingPath.contains('pending_$taskId')) {
        targetPath = existingPath;
        uniqueTitle = existingTask.title ?? mediaInfo.title;
      } else {
        final uniqueResult = generateUniqueDestinationPathAndTitle(
          downloadFolder,
          customTitle ?? mediaInfo.title,
          mediaInfo.fileExtension,
        );

        targetPath = uniqueResult.targetPath;
        uniqueTitle = uniqueResult.uniqueTitle;
      }

      await _downloadRepository.saveTask(
        existingTask.copyWith(
          destinationPath: targetPath,
          title: uniqueTitle,
          mediaType: mediaInfo.mediaType,
          status: DownloadStatus.downloading,
        ),
      );

      final streamUrlLower = mediaInfo.streamUrl.toLowerCase();

      String referer;

      if (streamUrlLower.contains('instagram') ||
          streamUrlLower.contains('cdninstagram')) {
        referer = 'https://www.instagram.com/';
      } else if (streamUrlLower.contains('facebook') ||
          streamUrlLower.contains('fbcdn')) {
        referer = 'https://www.facebook.com/';
      } else if (streamUrlLower.contains('tiktok') ||
          streamUrlLower.contains('tikwm')) {
        referer = 'https://www.tiktok.com/';
      } else {
        referer = 'https://www.google.com/';
      }

      final file = File(targetPath);

      var existingBytes = 0;

      if (await file.exists()) {
        existingBytes = await file.length();
      }

      final headers = <String, dynamic>{
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/120.0.0.0 Safari/537.36',
        'Referer': referer,
        'Accept': '*/*',
      };

      if (existingBytes > 0) {
        headers['Range'] = 'bytes=$existingBytes-';
      }

      final response = await _dio.get<ResponseBody>(
        mediaInfo.streamUrl,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          validateStatus: (status) {
            return status != null && status >= 200 && status < 300;
          },
        ),
      );

      final statusCode = response.statusCode ?? 0;

      final isResumeRequest = existingBytes > 0;
      final supportsRange = statusCode == 206;

      var startOffset = existingBytes;

      /*
     * Server does not support HTTP Range.
     *
     * We cannot append to the partial file because doing so
     * would corrupt the downloaded media.
     */
      if (isResumeRequest && !supportsRange) {
        startOffset = 0;

        if (await file.exists()) {
          await file.delete();
        }
      }

      final contentLength =
          int.tryParse(
            response.headers.value(Headers.contentLengthHeader) ?? '',
          ) ??
          0;

      final totalBytes = startOffset + contentLength;

      var received = 0;

      final sink = file.openWrite(
        mode: startOffset > 0 ? FileMode.append : FileMode.write,
      );

      try {
        await for (final chunk in response.data!.stream) {
          if (cancelToken.isCancelled) {
            break;
          }

          sink.add(chunk);

          received += chunk.length;

          final currentBytes = startOffset + received;

          final progress = totalBytes > 0
              ? (currentBytes / totalBytes).clamp(0.0, 1.0)
              : 0.0;

          await _downloadRepository.updateProgress(
            taskId,
            progress,
            currentBytes,
            totalBytes,
          );
        }
      } finally {
        await sink.close();
      }

      /*
     * If the download was paused/cancelled while reading the stream,
     * don't mark it as completed.
     */
      if (cancelToken.isCancelled) {
        if (_pauseRequested.contains(taskId)) {
          await _downloadRepository.updateStatus(taskId, DownloadStatus.paused);
        } else {
          await _downloadRepository.updateStatus(
            taskId,
            DownloadStatus.cancelled,
          );
        }

        return;
      }

      /*
     * Validate Instagram downloads.
     */
      if (provider is InstagramSourceProvider) {
        await _validateInstagramVideoDownload(
          targetPath,
          contentType: response.headers.value(Headers.contentTypeHeader),
        );
      }

      /*
     * Download completed successfully.
     */
      await _downloadRepository.updateProgress(
        taskId,
        1.0,
        totalBytes,
        totalBytes,
      );

      await _downloadRepository.updateStatus(taskId, DownloadStatus.completed);

      // Add downloaded media to library.
      unawaited(_mediaRepository.scanSingleFile(targetPath));
      if (Platform.isAndroid) {
        unawaited(
          MediaScanner.loadMedia(path: targetPath).catchError((e) {
            return null;
          }),
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        if (_pauseRequested.contains(taskId)) {
          await _downloadRepository.updateStatus(taskId, DownloadStatus.paused);
        } else {
          await _downloadRepository.updateStatus(
            taskId,
            DownloadStatus.cancelled,
          );
        }

        return;
      }

      final isInstagram = provider is InstagramSourceProvider;

      await _downloadRepository.updateStatus(
        taskId,
        DownloadStatus.failed,
        errorMessage: isInstagram
            ? 'Instagram did not provide a downloadable public video. '
                  'Check that the Reel or post is public, then try again.'
            : 'Unable to connect to source. '
                  'Please check your internet connection or URL.',
      );
    } catch (e) {
      var msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();

      if (msg.contains('DioException') || msg.contains('validateStatus')) {
        msg =
            'Unable to resolve video stream from this link. '
            'Make sure the post is public.';
      }

      await _downloadRepository.updateStatus(
        taskId,
        DownloadStatus.failed,
        errorMessage: msg,
      );
    } finally {
      _cancelTokens.remove(taskId);
      _pauseRequested.remove(taskId);
    }
  }

  /// Rejects HTML/challenge pages and incomplete data that may be saved with an
  /// MP4 filename when a social-media CDN denies a stream request.
  Future<void> _validateInstagramVideoDownload(
    String targetPath, {
    required String? contentType,
  }) async {
    final file = File(targetPath);
    final fileSize = await file.length();
    final normalizedContentType = contentType?.toLowerCase();

    InstagramResolutionDebugLog.add(
      'Download completed: content type ${normalizedContentType ?? 'unknown'}; '
      'file size $fileSize bytes.',
    );

    final isNonVideoResponse =
        normalizedContentType != null &&
        normalizedContentType.isNotEmpty &&
        !normalizedContentType.startsWith('video/') &&
        !normalizedContentType.startsWith('application/octet-stream');
    if (isNonVideoResponse || fileSize < 1024) {
      await _removeInvalidDownload(file);
      throw Exception(
        'Instagram returned an invalid video response. Please retry the download.',
      );
    }

    final handle = await file.open();
    try {
      final header = await handle.read(12);
      final hasMp4Header =
          header.length >= 8 &&
          header[4] == 0x66 && // f
          header[5] == 0x74 && // t
          header[6] == 0x79 && // y
          header[7] == 0x70; // p
      if (!hasMp4Header) {
        await _removeInvalidDownload(file);
        throw Exception(
          'Instagram returned a file that is not a playable MP4 video.',
        );
      }
    } finally {
      await handle.close();
    }

    InstagramResolutionDebugLog.add('MP4 file validation passed.');
  }

  Future<void> _removeInvalidDownload(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Cancel an active download task
  Future<void> cancelDownload(String taskId) async {
    _pauseRequested.remove(taskId);

    final token = _cancelTokens[taskId];

    if (token != null && !token.isCancelled) {
      token.cancel('User cancelled download');
      return;
    }

    await _downloadRepository.updateStatus(taskId, DownloadStatus.cancelled);
  }

  /// Delete download task record and remove partially downloaded file
  Future<void> deleteTask(String taskId) async {
    final task = await _downloadRepository.getTaskById(taskId);
    if (task != null) {
      await cancelDownload(taskId);
      final file = File(task.destinationPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      await _downloadRepository.deleteTask(taskId);
    }
  }

  /// Pause an active download task
  Future<void> pauseDownload(String taskId) async {
    final task = await _downloadRepository.getTaskById(taskId);

    if (task == null) return;

    if (task.status != DownloadStatus.downloading &&
        task.status != DownloadStatus.resolving) {
      return;
    }

    _pauseRequested.add(taskId);

    final token = _cancelTokens[taskId];

    if (token != null && !token.isCancelled) {
      token.cancel('Pause');
    }
  }

  /// Resume a paused download task
  Future<void> resumeDownload(String taskId) async {
    final task = await _downloadRepository.getTaskById(taskId);

    if (task == null || task.status != DownloadStatus.paused) {
      return;
    }

    // Remove old pause request before starting again.
    _pauseRequested.remove(taskId);

    final uri = Uri.parse(task.url);

    final provider = _providers.firstWhere(
      (p) => p.canHandle(uri),
      orElse: () => DirectMediaSourceProvider(),
    );

    await _downloadRepository.saveTask(
      task.copyWith(
        status: DownloadStatus.queued,
        retryCount: 0,
        errorMessage: null,
      ),
    );

    /*
   * IMPORTANT:
   * Use the SAME destinationPath.
   * _executeDownloadTask() will detect the existing file
   * and continue from its current byte count.
   */
    unawaited(
      _executeDownloadTask(
        taskId,
        uri,
        provider,
        File(task.destinationPath).parent.path,
        customTitle: task.title,
      ),
    );
  }

  /// Retry a failed download with exponential backoff
  Future<void> retryDownload(String taskId) async {
    final task = await _downloadRepository.getTaskById(taskId);

    if (task == null || !task.isFailed) return;

    final canRetry = task.retryCount < task.maxRetries;

    if (!canRetry) return;

    final delaySeconds = 1 << task.retryCount;

    await Future.delayed(Duration(seconds: delaySeconds));

    final uri = Uri.parse(task.url);

    final provider = _providers.firstWhere(
      (p) => p.canHandle(uri),
      orElse: () => DirectMediaSourceProvider(),
    );

    await _downloadRepository.saveTask(
      task.copyWith(
        status: DownloadStatus.queued,
        retryCount: task.retryCount + 1,
        errorMessage: null,
      ),
    );

    unawaited(
      _executeDownloadTask(
        taskId,
        uri,
        provider,
        File(task.destinationPath).parent.path,
        customTitle: task.title,
      ),
    );
  }

  /// Generates a unique, non-overwriting destination file path and display title.
  /// If a file with the same title exists on disk, it appends an incremental index:
  /// e.g. "My Video.mp4" -> "My Video (1).mp4" -> "My Video (2).mp4".
  static ({String targetPath, String uniqueTitle})
  generateUniqueDestinationPathAndTitle(
    String downloadFolder,
    String rawTitle,
    String fileExtension,
  ) {
    final ext = fileExtension.startsWith('.')
        ? fileExtension
        : '.$fileExtension';
    final baseTitle = sanitizeFilename(rawTitle, '');

    var candidateTitle = baseTitle;
    var candidatePath = p.join(downloadFolder, '$candidateTitle$ext');
    if (!File(candidatePath).existsSync()) {
      return (targetPath: candidatePath, uniqueTitle: candidateTitle);
    }

    int counter = 1;
    while (true) {
      candidateTitle = '$baseTitle ($counter)';
      candidatePath = p.join(downloadFolder, '$candidateTitle$ext');
      if (!File(candidatePath).existsSync()) {
        return (targetPath: candidatePath, uniqueTitle: candidateTitle);
      }
      counter++;
    }
  }
}
