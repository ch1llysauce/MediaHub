import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MediaQualityOption {
  final String label; // e.g. "1080p (HD)", "720p (HD)", "480p (SD)", "360p" or "320 kbps (HQ)", "192 kbps"
  final String streamUrl;
  final String? sizeLabel;
  final String? fileExtension;

  const MediaQualityOption({
    required this.label,
    required this.streamUrl,
    this.sizeLabel,
    this.fileExtension,
  });
}

class MediaSourceInfo {
  final String title;
  final String streamUrl;
  final String mediaType; // 'audio' or 'video'
  final String fileExtension;
  final String? thumbnailUrl;
  final List<MediaQualityOption> availableQualities;

  const MediaSourceInfo({
    required this.title,
    required this.streamUrl,
    required this.mediaType,
    required this.fileExtension,
    this.thumbnailUrl,
    this.availableQualities = const [],
  });
}

abstract class MediaSourceProvider {
  bool canHandle(Uri url);
  Future<MediaSourceInfo> resolve(Uri url, {bool audioOnly = false});
}

/// Provider for direct media file URLs (e.g., https://example.com/song.mp3)
class DirectMediaSourceProvider implements MediaSourceProvider {
  static const audioExts = ['.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg'];
  static const videoExts = ['.mp4', '.mkv', '.webm', '.avi', '.mov'];

  @override
  bool canHandle(Uri url) {
    final path = url.path.toLowerCase();
    return audioExts.any((ext) => path.endsWith(ext)) ||
        videoExts.any((ext) => path.endsWith(ext));
  }

  @override
  Future<MediaSourceInfo> resolve(Uri url, {bool audioOnly = false}) async {
    final path = url.path.toLowerCase();
    final isAudio = audioExts.any((ext) => path.endsWith(ext));
    final ext = isAudio
        ? (path.substring(path.lastIndexOf('.')))
        : (videoExts.firstWhere((e) => path.endsWith(e), orElse: () => '.mp4'));

    // Extract file name from URL path as fallback title
    String filename = url.pathSegments.isNotEmpty ? url.pathSegments.last : 'download';
    if (filename.contains('.')) {
      filename = filename.substring(0, filename.lastIndexOf('.'));
    }
    filename = Uri.decodeComponent(filename).replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
    if (filename.isEmpty) filename = 'download_${DateTime.now().millisecondsSinceEpoch}';

    final defaultQualities = isAudio || audioOnly
        ? [
            MediaQualityOption(label: '320 kbps (HQ)', streamUrl: url.toString()),
            MediaQualityOption(label: '192 kbps (Standard)', streamUrl: url.toString()),
            MediaQualityOption(label: '128 kbps (Compact)', streamUrl: url.toString()),
          ]
        : [
            MediaQualityOption(label: '1080p (HD)', streamUrl: url.toString()),
            MediaQualityOption(label: '720p (HD)', streamUrl: url.toString()),
            MediaQualityOption(label: '480p (SD)', streamUrl: url.toString()),
          ];

    return MediaSourceInfo(
      title: filename,
      streamUrl: url.toString(),
      mediaType: isAudio || audioOnly ? 'audio' : 'video',
      fileExtension: ext,
      availableQualities: defaultQualities,
    );
  }
}

/// Provider for YouTube videos and shorts using YoutubeExplode
class YoutubeSourceProvider implements MediaSourceProvider {
  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('youtube.com') || host.contains('youtu.be');
  }

  @override
  Future<MediaSourceInfo> resolve(Uri url, {bool audioOnly = false}) async {
    final yt = YoutubeExplode();
    try {
      final videoIdStr = VideoId.parseVideoId(url.toString()) ?? url.toString();
      final videoId = VideoId(videoIdStr);

      String title = 'YouTube Media';
      String thumbnailUrl = 'https://i.ytimg.com/vi/${videoId.value}/hqdefault.jpg';

      // 1. Fetch title & thumbnail via YouTube oEmbed API for fast, unthrottled resolution
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      try {
        final oembedRes = await dio.get<Map<String, dynamic>>(
          'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId.value}&format=json',
        );
        if (oembedRes.data != null) {
          if (oembedRes.data!['title'] != null && (oembedRes.data!['title'] as String).isNotEmpty) {
            title = oembedRes.data!['title'] as String;
          }
          if (oembedRes.data!['thumbnail_url'] != null && (oembedRes.data!['thumbnail_url'] as String).isNotEmpty) {
            thumbnailUrl = oembedRes.data!['thumbnail_url'] as String;
          }
        }
      } catch (_) {}

      Video? video;
      try {
        video = await yt.videos.get(videoId);
        if (video.title.isNotEmpty) {
          title = video.title;
        }
        if (video.thumbnails.highResUrl.isNotEmpty) {
          thumbnailUrl = video.thumbnails.highResUrl;
        }
      } catch (_) {}

      // 2. Try Cobalt API for primary stream resolution
      final targetUrl = 'https://www.youtube.com/watch?v=${videoId.value}';
      for (final cobaltHost in ['api.cobalt.tools', 'co.wuk.sh']) {
        try {
          final cobaltResponse = await dio.post<Map<String, dynamic>>(
            'https://$cobaltHost/api/json',
            data: {
              'url': targetUrl,
              if (audioOnly) 'isAudioOnly': true,
              if (audioOnly) 'aFormat': 'mp4',
              if (!audioOnly) 'videoQuality': 'max',
            },
            options: Options(
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
            ),
          );

          if (cobaltResponse.statusCode == 200 && cobaltResponse.data != null) {
            final data = cobaltResponse.data!;
            String? streamUrl = data['url']?.toString();
            if ((streamUrl == null || streamUrl.isEmpty) && data['picker'] is List && (data['picker'] as List).isNotEmpty) {
              final firstItem = (data['picker'] as List).first;
              if (firstItem is Map) {
                streamUrl = firstItem['url']?.toString();
              }
            }
            if (streamUrl != null && streamUrl.isNotEmpty) {
              if (data['filename'] != null) {
                String cobaltTitle = data['filename'].toString();
                if (cobaltTitle.isNotEmpty && cobaltTitle != 'youtube') {
                   title = cobaltTitle;
                }
              }

              return MediaSourceInfo(
                title: title,
                streamUrl: streamUrl,
                mediaType: audioOnly ? 'audio' : 'video',
                fileExtension: audioOnly ? '.m4a' : '.mp4',
                thumbnailUrl: thumbnailUrl,
                availableQualities: [
                  MediaQualityOption(
                    label: audioOnly ? 'High Quality Audio (M4A)' : 'High Quality Video (MP4)',
                    streamUrl: streamUrl,
                    fileExtension: audioOnly ? '.m4a' : '.mp4',
                  ),
                ],
              );
            }
          }
        } catch (e) {
          developer.log('Cobalt API ($cobaltHost) failed: $e', name: 'MediaHub.YoutubeProvider');
        }
      }

      // 3. Try Invidious API Proxy Fallback
      final invidiousInstances = [
        'invidious.jing.rocks',
        'invidious.namazso.eu',
        'inv.tux.pizza',
        'vid.puffyan.us',
      ];
      
      for (final invInstance in invidiousInstances) {
        try {
          final invResponse = await dio.get<Map<String, dynamic>>(
            'https://$invInstance/api/v1/videos/${videoId.value}',
            options: Options(
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

          if (invResponse.statusCode == 200 && invResponse.data != null) {
            final data = invResponse.data!;
            final formats = data['adaptiveFormats'] as List?;
            final formatStreams = data['formatStreams'] as List?;
            
            String? selectedUrl;
            String? selectedExt;
            
            if (audioOnly && formats != null) {
              // Try to find m4a audio
              final audioStreams = formats.where((f) => 
                f['type'] != null && f['type'].toString().contains('audio/mp4')
              ).toList();
              
              if (audioStreams.isNotEmpty) {
                audioStreams.sort((a, b) => (b['bitrate'] as int? ?? 0).compareTo(a['bitrate'] as int? ?? 0));
                selectedUrl = audioStreams.first['url']?.toString();
                selectedExt = '.m4a';
              } else {
                // Fallback to webm/opus audio
                final altStreams = formats.where((f) => 
                  f['type'] != null && f['type'].toString().contains('audio/')
                ).toList();
                if (altStreams.isNotEmpty) {
                  altStreams.sort((a, b) => (b['bitrate'] as int? ?? 0).compareTo(a['bitrate'] as int? ?? 0));
                  selectedUrl = altStreams.first['url']?.toString();
                  selectedExt = '.webm';
                }
              }
            } else if (!audioOnly && formatStreams != null && formatStreams.isNotEmpty) {
              // Pick highest quality muxed video
              final videoStreams = formatStreams.toList();
              videoStreams.sort((a, b) => 
                 (b['qualityLabel']?.toString() ?? '').compareTo(a['qualityLabel']?.toString() ?? '')
              );
              selectedUrl = videoStreams.first['url']?.toString();
              selectedExt = '.mp4';
            }

            if (selectedUrl != null && selectedUrl.isNotEmpty) {
              final invTitle = data['title']?.toString() ?? title;
              return MediaSourceInfo(
                title: invTitle,
                streamUrl: selectedUrl,
                mediaType: audioOnly ? 'audio' : 'video',
                fileExtension: selectedExt ?? (audioOnly ? '.m4a' : '.mp4'),
                thumbnailUrl: thumbnailUrl,
                availableQualities: [
                  MediaQualityOption(
                    label: audioOnly ? 'Proxy Quality Audio' : 'Proxy Quality Video',
                    streamUrl: selectedUrl,
                    fileExtension: selectedExt ?? (audioOnly ? '.m4a' : '.mp4'),
                  ),
                ],
              );
            }
          }
        } catch (e) {
          developer.log('Invidious API ($invInstance) failed: $e', name: 'MediaHub.YoutubeProvider');
        }
      }

      StreamManifest? manifest;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          manifest = await yt.videos.streamsClient.getManifest(videoId);
          break;
        } catch (e) {
          if (attempt == 3) rethrow;
          await Future.delayed(Duration(milliseconds: 400 * attempt));
        }
      }

      if (manifest == null) {
        throw Exception('Failed to resolve YouTube video details.');
      }

      final qualities = <MediaQualityOption>[];

      if (audioOnly) {
        if (manifest.audioOnly.isNotEmpty) {
          final sortedAudio = manifest.audioOnly.toList()
            ..sort((a, b) => b.bitrate.compareTo(a.bitrate));

          for (final s in sortedAudio) {
            final kbits = (s.bitrate.bitsPerSecond / 1000).round();
            final format = s.container.name == 'mp4' ? 'M4A' : s.container.name.toUpperCase();
            final label = '$kbits kbps ($format Audio)';
            if (!qualities.any((q) => q.label == label)) {
              qualities.add(MediaQualityOption(
                label: label,
                streamUrl: s.url.toString(),
                sizeLabel: s.size.totalBytes > 0
                    ? '${(s.size.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                    : null,
                fileExtension: s.container.name == 'mp4' ? '.m4a' : '.${s.container.name}',
              ));
            }
          }

          final m4aStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4');
          final mainStream = m4aStreams.isNotEmpty
              ? m4aStreams.withHighestBitrate()
              : manifest.audioOnly.withHighestBitrate();
          return MediaSourceInfo(
            title: title,
            streamUrl: mainStream.url.toString(),
            mediaType: 'audio',
            fileExtension: mainStream.container.name == 'mp4' ? '.m4a' : '.${mainStream.container.name}',
            thumbnailUrl: thumbnailUrl,
            availableQualities: qualities.isNotEmpty
                ? qualities
                : [
                    MediaQualityOption(
                      label: 'High Quality Audio',
                      streamUrl: mainStream.url.toString(),
                    ),
                  ],
          );
        }
      }

      final muxedStreams = manifest.muxed.toList();
      if (muxedStreams.isNotEmpty) {
        muxedStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        for (final s in muxedStreams) {
          final qLabel = s.qualityLabel.isNotEmpty ? s.qualityLabel : '720p';
          final label = qLabel.contains('p') ? qLabel : '$qLabel HD';
          if (!qualities.any((q) => q.label == label)) {
            qualities.add(MediaQualityOption(
              label: label,
              streamUrl: s.url.toString(),
              sizeLabel: s.size.totalBytes > 0
                  ? '${(s.size.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                  : null,
              fileExtension: '.${s.container.name}',
            ));
          }
        }

        final mainStream = manifest.muxed.withHighestBitrate();

        return MediaSourceInfo(
          title: title,
          streamUrl: mainStream.url.toString(),
          mediaType: audioOnly ? 'audio' : 'video',
          fileExtension: audioOnly ? '.m4a' : '.${mainStream.container.name}',
          thumbnailUrl: thumbnailUrl,
          availableQualities: qualities.isNotEmpty
              ? qualities
              : [
                  MediaQualityOption(
                    label: audioOnly ? 'High Quality Audio' : '720p (HD)',
                    streamUrl: mainStream.url.toString(),
                  ),
                  MediaQualityOption(
                    label: audioOnly ? 'Standard Quality Audio' : '480p (SD)',
                    streamUrl: mainStream.url.toString(),
                  ),
                ],
        );
      }

      if (manifest.audioOnly.isNotEmpty) {
        final m4aStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4');
        final audioStream = m4aStreams.isNotEmpty
            ? m4aStreams.withHighestBitrate()
            : manifest.audioOnly.withHighestBitrate();
        return MediaSourceInfo(
          title: title,
          streamUrl: audioStream.url.toString(),
          mediaType: audioOnly ? 'audio' : 'video',
          fileExtension: audioOnly ? '.mp3' : '.mp4',
          thumbnailUrl: thumbnailUrl,
          availableQualities: [
            MediaQualityOption(
              label: audioOnly ? '320 kbps (HQ MP3)' : '720p (HD)',
              streamUrl: audioStream.url.toString(),
            ),
            MediaQualityOption(
              label: audioOnly ? '192 kbps (Standard MP3)' : '480p (SD)',
              streamUrl: audioStream.url.toString(),
            ),
          ],
        );
      }

      throw Exception('No playable streams found for this video.');
    } finally {
      yt.close();
    }
  }
}

/// Provider for TikTok videos using public resolution APIs
class TikTokSourceProvider implements MediaSourceProvider {
  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('tiktok.com');
  }

  @override
  Future<MediaSourceInfo> resolve(Uri url, {bool audioOnly = false}) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ));

    try {
      final apiUrl = 'https://www.tikwm.com/api/?url=${Uri.encodeComponent(url.toString())}';
      final response = await dio.get<Map<String, dynamic>>(apiUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        if (data['code'] == 0 && data['data'] != null) {
          final info = data['data'] as Map<String, dynamic>;
          final playUrl = info['play'] as String? ?? info['wmplay'] as String?;
          final title = info['title'] as String? ?? 'TikTok Video';
          if (playUrl != null && playUrl.isNotEmpty) {
            final fullPlayUrl = playUrl.startsWith('http') ? playUrl : 'https://www.tikwm.com$playUrl';
            var cleanTitle = title.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
            if (cleanTitle.isEmpty) cleanTitle = 'tiktok_${DateTime.now().millisecondsSinceEpoch}';

            return MediaSourceInfo(
              title: cleanTitle,
              streamUrl: fullPlayUrl,
              mediaType: audioOnly ? 'audio' : 'video',
              fileExtension: audioOnly ? '.mp3' : '.mp4',
            );
          }
        }
      }
    } catch (_) {}

    return GenericSocialMediaProvider().resolve(url, audioOnly: audioOnly);
  }
}

/// Provider for Instagram Reels and Posts using OpenGraph Mirrors
class InstagramSourceProvider implements MediaSourceProvider {
  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('instagram.com') || host.contains('instagr.am');
  }

  @override
  Future<MediaSourceInfo> resolve(Uri url, {bool audioOnly = false}) async {
    InstagramResolutionDebugLog.start();
    _logInstagramResolution('Started fast parallel Instagram resolution.');

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
    ));

    var targetUrl = url.toString();
    final cleanUri = Uri.parse(targetUrl).removeFragment().replace(queryParameters: {});
    final canonicalUrl = cleanUri.toString();

    final targetUrls = [canonicalUrl];
    if (canonicalUrl.contains('instagram.com') && !canonicalUrl.contains('m.instagram.com')) {
      targetUrls.add(canonicalUrl.replaceFirst('instagram.com', 'm.instagram.com'));
    }

    final proxyDomains = [
      'ddinstagram.com',
      'vxinstagram.com',
      'instagramez.com',
      'eeinstagram.com',
      'kkinstagram.com',
      'fxinstagram.com',
      'iginstagram.com',
      'gramfix.com',
      'distagram.com',
      'ddinstagram.org',
    ];

    // Extract shortcode for direct web API strategies
    final shortcodeMatch = RegExp(r'/(?:p|reel|reels|tv)/([A-Za-z0-9_-]+)').firstMatch(canonicalUrl);
    final shortcode = shortcodeMatch?.group(1);

    final completer = Completer<MediaSourceInfo>();
    int pendingTasks = 0;

    void submitTask(Future<MediaSourceInfo?> taskFuture, String strategyName) {
      pendingTasks++;
      taskFuture.then((result) {
        if (result != null && !completer.isCompleted) {
          _logInstagramResolution('FIRST-WIN [$strategyName]: Successfully resolved video stream.');
          completer.complete(result);
        } else if (result == null) {
          _logInstagramResolution('FAILED [$strategyName]: No stream found in payload.');
        }
      }).catchError((err) {
        _logInstagramResolution('ERROR [$strategyName]: $err');
      }).whenComplete(() {
        pendingTasks--;
        if (pendingTasks <= 0 && !completer.isCompleted) {
          _logInstagramResolution('All parallel strategies finished for this pass.');
        }
      });
    }

    // ─────────────────────────────────────────────────────────────
    // STRATEGY 0: Crawler Metadata on public page variants
    // ─────────────────────────────────────────────────────────────
    for (final target in targetUrls) {
      submitTask(
        Future(() async {
          try {
            final response = await dio.get<String>(
              target,
              options: Options(headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept-Language': 'en-US,en;q=0.9',
              }),
            );
            if (response.data != null && response.data!.isNotEmpty) {
              final document = html_parser.parse(response.data!);
              final videoMeta = document.querySelector('meta[property="og:video"]') ??
                  document.querySelector('meta[property="og:video:secure_url"]') ??
                  document.querySelector('meta[property="og:video:url"]') ??
                  document.querySelector('meta[name="twitter:player:stream"]');
              if (videoMeta?.attributes['content'] != null && videoMeta!.attributes['content']!.isNotEmpty) {
                final videoUrl = videoMeta.attributes['content']!;
                final titleMeta = document.querySelector('meta[property="og:title"]');
                var title = titleMeta?.attributes['content'] ?? 'Instagram Video';
                title = title.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
                if (title.isEmpty) title = 'instagram_${DateTime.now().millisecondsSinceEpoch}';

                return MediaSourceInfo(
                  title: title,
                  streamUrl: videoUrl,
                  mediaType: audioOnly ? 'audio' : 'video',
                  fileExtension: audioOnly ? '.mp3' : '.mp4',
                );
              }
            }
          } catch (_) {}
          return null;
        }),
        'Crawler Metadata ($target)',
      );
    }

    // ─────────────────────────────────────────────────────────────
    // STRATEGY 1: Official Instagram Embed Scraper
    // ─────────────────────────────────────────────────────────────
    submitTask(
      Future(() async {
        try {
          final embedUrl = canonicalUrl.endsWith('/') ? '${canonicalUrl}embed/' : '$canonicalUrl/embed/';
          final response = await dio.get<String>(
            embedUrl,
            options: Options(headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept-Language': 'en-US,en;q=0.9',
            }),
          );
          if (response.statusCode == 200 && response.data != null) {
            final body = response.data!;
            final mp4Regex = RegExp(r'https?:\\?/\\?/[^"\s\\]+?cdninstagram\.com[^"\s\\]+?\.mp4[^"\s\\]*');
            final match = mp4Regex.firstMatch(body);
            if (match != null && match.group(0) != null) {
              final cleanVideoUrl = _cleanEscapedUrl(match.group(0)!);
              if (cleanVideoUrl.isNotEmpty) {
                final document = html_parser.parse(body);
                final titleMeta = document.querySelector('title');
                var title = titleMeta?.text ?? 'Instagram Video';
                title = title.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
                if (title.isEmpty) title = 'instagram_${DateTime.now().millisecondsSinceEpoch}';

                return MediaSourceInfo(
                  title: title,
                  streamUrl: cleanVideoUrl,
                  mediaType: audioOnly ? 'audio' : 'video',
                  fileExtension: audioOnly ? '.mp3' : '.mp4',
                );
              }
            }
          }
        } catch (_) {}
        return null;
      }),
      'Embed Scraper',
    );

    // ─────────────────────────────────────────────────────────────
    // STRATEGY 2: Embedded Public Page Data (JSON Parser)
    // ─────────────────────────────────────────────────────────────
    for (final target in targetUrls) {
      submitTask(
        Future(() async {
          try {
            final response = await dio.get<String>(
              target,
              options: Options(headers: {
                'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                'Accept-Language': 'en-US,en;q=0.9',
              }),
            );
            return _parseInstagramPublicPage(response.data);
          } catch (_) {}
          return null;
        }),
        'Embedded JSON Parser ($target)',
      );
    }

    // ─────────────────────────────────────────────────────────────
    // STRATEGY 3: OpenGraph Parallel Proxy Mirrors (All 10 Domains)
    // ─────────────────────────────────────────────────────────────
    for (final proxy in proxyDomains) {
      submitTask(
        Future(() async {
          try {
            var proxyUrl = canonicalUrl;
            if (shortcode != null && shortcode.isNotEmpty) {
              proxyUrl = 'https://$proxy/reel/$shortcode/';
            } else {
              proxyUrl = proxyUrl.replaceAll(RegExp(r'(www\.)?instagram\.com'), proxy);
            }

            final response = await dio.get<String>(
              proxyUrl,
              options: Options(headers: {
                'User-Agent': 'Discordbot/2.0',
              }),
            );

            if (response.statusCode == 200 && response.data != null) {
              final html = response.data!;
              final document = html_parser.parse(html);
              final videoMeta = document.querySelector('meta[property="og:video"]') ??
                  document.querySelector('meta[property="og:video:secure_url"]') ??
                  document.querySelector('meta[property="og:video:url"]') ??
                  document.querySelector('meta[name="twitter:player:stream"]');
              if (videoMeta?.attributes['content'] != null && videoMeta!.attributes['content']!.isNotEmpty) {
                final videoUrl = videoMeta.attributes['content']!;
                final titleMeta = document.querySelector('meta[property="og:title"]');
                var title = titleMeta?.attributes['content'] ?? 'Instagram Video';
                title = title.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
                if (title.isEmpty) title = 'instagram_${DateTime.now().millisecondsSinceEpoch}';

                return MediaSourceInfo(
                  title: title,
                  streamUrl: videoUrl,
                  mediaType: audioOnly ? 'audio' : 'video',
                  fileExtension: audioOnly ? '.mp3' : '.mp4',
                );
              }
            }
          } catch (_) {}
          return null;
        }),
        'Mirror Proxy ($proxy)',
      );
    }

    // ─────────────────────────────────────────────────────────────
    // STRATEGY 4: SaveIG API
    // ─────────────────────────────────────────────────────────────
    submitTask(
      Future(() async {
        try {
          final response = await dio.post(
            'https://saveig.app/api/ajaxSearch',
            data: 'q=${Uri.encodeComponent(canonicalUrl)}&vt=instagram',
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'X-Requested-With': 'XMLHttpRequest',
                'Origin': 'https://saveig.app',
                'Referer': 'https://saveig.app/',
              },
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            String htmlContent = '';
            if (response.data is Map && (response.data as Map)['data'] != null) {
              htmlContent = (response.data as Map)['data'].toString();
            } else if (response.data is String) {
              htmlContent = response.data as String;
            }

            if (htmlContent.isNotEmpty) {
              final unpackedHtml = _unpackIfNeeded(htmlContent);
              final result = _parseFbExtractorHtml(unpackedHtml, audioOnly: audioOnly);
              if (result != null) {
                return MediaSourceInfo(
                  title: result.title == 'Facebook Video' ? 'Instagram Video' : result.title,
                  streamUrl: result.streamUrl,
                  mediaType: result.mediaType,
                  fileExtension: result.fileExtension,
                  thumbnailUrl: result.thumbnailUrl,
                  availableQualities: result.availableQualities,
                );
              }
            }
          }
        } catch (_) {}
        return null;
      }),
      'SaveIG API',
    );

    // ─────────────────────────────────────────────────────────────
    // STRATEGY 5: SnapSave API
    // ─────────────────────────────────────────────────────────────
    submitTask(
      Future(() async {
        try {
          final snapResponse = await dio.post<String>(
            'https://snapsave.app/action.php?lang=en',
            data: 'url=${Uri.encodeComponent(canonicalUrl)}',
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'X-Requested-With': 'XMLHttpRequest',
                'Origin': 'https://snapsave.app',
                'Referer': 'https://snapsave.app/',
              },
            ),
          );

          if (snapResponse.statusCode == 200 && snapResponse.data != null) {
            final unpackedHtml = _unpackIfNeeded(snapResponse.data!);
            final result = _parseFbExtractorHtml(unpackedHtml, audioOnly: audioOnly);
            if (result != null) {
              return MediaSourceInfo(
                title: result.title == 'Facebook Video' ? 'Instagram Video' : result.title,
                streamUrl: result.streamUrl,
                mediaType: result.mediaType,
                fileExtension: result.fileExtension,
                thumbnailUrl: result.thumbnailUrl,
                availableQualities: result.availableQualities,
              );
            }
          }
        } catch (_) {}
        return null;
      }),
      'SnapSave API',
    );

    // ─────────────────────────────────────────────────────────────
    // STRATEGY 6: SSSInstagram API
    // ─────────────────────────────────────────────────────────────
    submitTask(
      Future(() async {
        try {
          final response = await dio.post<Map<String, dynamic>>(
            'https://sssinstagram.com/api/convert',
            data: {'url': canonicalUrl},
            options: Options(headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'application/json',
            }),
          );
          if (response.statusCode == 200 && response.data != null) {
            final data = response.data!;
            if (data['url'] is List && (data['url'] as List).isNotEmpty) {
              final first = (data['url'] as List).first as Map;
              final streamUrl = first['url']?.toString();
              if (streamUrl != null && streamUrl.isNotEmpty) {
                return MediaSourceInfo(
                  title: 'Instagram Video',
                  streamUrl: streamUrl,
                  mediaType: audioOnly ? 'audio' : 'video',
                  fileExtension: audioOnly ? '.mp3' : '.mp4',
                );
              }
            }
          }
        } catch (_) {}
        return null;
      }),
      'SSSInstagram API',
    );

    // ─────────────────────────────────────────────────────────────
    // STRATEGY 7: Instagram Web API (__a=1 with X-IG-App-ID)
    // ─────────────────────────────────────────────────────────────
    if (shortcode != null && shortcode.isNotEmpty) {
      submitTask(
        Future(() async {
          try {
            final apiResponse = await dio.get<Map<String, dynamic>>(
              'https://www.instagram.com/p/$shortcode/?__a=1&__d=dis',
              options: Options(headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'X-IG-App-ID': '936619743392459',
                'X-Requested-With': 'XMLHttpRequest',
              }),
            );
            if (apiResponse.statusCode == 200 && apiResponse.data != null) {
              final data = apiResponse.data!;
              final items = data['items'] as List?;
              if (items != null && items.isNotEmpty) {
                final item = items.first as Map;
                final videoVersions = item['video_versions'] as List?;
                if (videoVersions != null && videoVersions.isNotEmpty) {
                  final bestVideo = videoVersions.first as Map;
                  final streamUrl = bestVideo['url']?.toString();
                  if (streamUrl != null && streamUrl.isNotEmpty) {
                    final caption = item['caption']?['text']?.toString() ?? 'Instagram Video';
                    var title = caption.split('\n').first;
                    title = title.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
                    if (title.isEmpty) title = 'instagram_${DateTime.now().millisecondsSinceEpoch}';

                    return MediaSourceInfo(
                      title: title,
                      streamUrl: streamUrl,
                      mediaType: audioOnly ? 'audio' : 'video',
                      fileExtension: audioOnly ? '.mp3' : '.mp4',
                    );
                  }
                }
              }
            }
          } catch (_) {}
          return null;
        }),
        'Instagram Web API (__a=1)',
      );

      // ─────────────────────────────────────────────────────────────
      // STRATEGY 8: Cobalt Engine API (High Quality Multi-Host)
      // ─────────────────────────────────────────────────────────────
      for (final cobaltHost in ['api.cobalt.tools', 'co.wuk.sh']) {
        submitTask(
          Future(() async {
            try {
              final cobaltResponse = await dio.post<Map<String, dynamic>>(
                'https://$cobaltHost/api/json',
                data: {
                  'url': canonicalUrl,
                  'videoQuality': 'max',
                },
                options: Options(headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                }),
              );
              if (cobaltResponse.statusCode == 200 && cobaltResponse.data != null) {
                final data = cobaltResponse.data!;
                String? streamUrl = data['url']?.toString();
                if ((streamUrl == null || streamUrl.isEmpty) && data['picker'] is List && (data['picker'] as List).isNotEmpty) {
                  final firstItem = (data['picker'] as List).first;
                  if (firstItem is Map) {
                    streamUrl = firstItem['url']?.toString();
                  }
                }
                if (streamUrl != null && streamUrl.isNotEmpty) {
                  final title = data['filename']?.toString() ?? 'Instagram Video';
                  return MediaSourceInfo(
                    title: title,
                    streamUrl: streamUrl,
                    mediaType: audioOnly ? 'audio' : 'video',
                    fileExtension: audioOnly ? '.mp3' : '.mp4',
                  );
                }
              }
            } catch (_) {}
            return null;
          }),
          'Cobalt Engine API ($cobaltHost)',
        );
      }
    }

    // Wait for the FIRST task that resolves a valid result, or fallback if all fail within max 10 seconds
    try {
      return await completer.future.timeout(const Duration(seconds: 10));
    } catch (_) {
      _logInstagramResolution('Parallel race timed out (10s); using generic fallback.');
    }

    return GenericSocialMediaProvider().resolve(url, audioOnly: audioOnly);
  }

}

const _instagramLogName = 'MediaHub.InstagramProvider';

/// Keeps the latest Instagram resolver trace available to the download UI.
/// Entries omit source URLs and temporary CDN tokens.
class InstagramResolutionDebugLog {
  static const _maximumEntries = 60;
  static final List<String> _entries = [];

  static void start() {
    _entries
      ..clear()
      ..add('[${DateTime.now().toLocal()}] Started Instagram resolution');
  }

  static void add(String message) {
    _entries.add('[${DateTime.now().toLocal()}] $message');
    if (_entries.length > _maximumEntries) {
      _entries.removeRange(0, _entries.length - _maximumEntries);
    }
  }

  static String get formatted =>
      _entries.isEmpty ? 'No Instagram resolver trace is available yet.' : _entries.join('\n');
}

void _logInstagramResolution(String message) {
  InstagramResolutionDebugLog.add(message);
  developer.log(message, name: _instagramLogName);
}

/// Resolves media made available directly in a public Instagram page. It does
/// not use authenticated sessions or attempt to access private posts.
MediaSourceInfo? _parseInstagramPublicPage(
  String? html,
) {
  if (html == null || html.isEmpty) return null;

  String? streamUrl;

  // 1. Structural JSON decoding from <script> tags
  try {
    final document = html_parser.parse(html);
    final scripts = document.querySelectorAll('script');
    for (final script in scripts) {
      final text = script.text.trim();
      if (text.contains('video_url') || text.contains('video_versions')) {
        final jsonMatch = RegExp(r'(\{.*"video_url".*\})').firstMatch(text) ??
            RegExp(r'(\{.*"video_versions".*\})').firstMatch(text);
        if (jsonMatch != null && jsonMatch.group(1) != null) {
          try {
            final Map<String, dynamic> parsed = jsonDecode(jsonMatch.group(1)!);
            final candidate = parsed['video_url']?.toString() ??
                (parsed['video_versions'] is List && (parsed['video_versions'] as List).isNotEmpty
                    ? (parsed['video_versions'] as List).first['url']?.toString()
                    : null);
            if (candidate != null && candidate.isNotEmpty) {
              final cleaned = _cleanInstagramUrl(candidate);
              if (cleaned.contains('.mp4')) {
                streamUrl = cleaned;
                break;
              }
            }
          } catch (_) {}
        }
      }
    }
  } catch (_) {}

  // 2. Fallback to Regex patterns
  if (streamUrl == null) {
    final streamPatterns = [
      // Instagram video URL
      RegExp(r'"video_url"\s*:\s*"([^"]+)"'),

      // Instagram GraphQL video_versions array
      RegExp(r'"video_versions"\s*:\s*\[\s*\{\s*"[^"]*"\s*:\s*"[^"]*"\s*,\s*"url"\s*:\s*"([^"]+)"'),
      RegExp(r'"video_resources"\s*:\s*\[\s*\{\s*"src"\s*:\s*"([^"]+)"'),

      // Facebook-style fields sometimes exposed by Instagram
      RegExp(r'"playable_url_quality_hd"\s*:\s*"([^"]+)"'),
      RegExp(r'"playable_url"\s*:\s*"([^"]+)"'),

      // Generic video CDN URL — ONLY accept URLs containing .mp4
      RegExp(
        r'"(?:src|url)"\s*:\s*"(https?:[^"]*cdninstagram\.com[^"]*\.mp4[^"]*)"',
      ),
    ];

    for (final pattern in streamPatterns) {
      final candidate = pattern.firstMatch(html)?.group(1);
      if (candidate == null) continue;

      final cleaned = _cleanInstagramUrl(candidate);
      final uri = Uri.tryParse(cleaned);

      if (uri != null &&
          uri.scheme == 'https' &&
          uri.host.contains('cdninstagram.com') &&
          uri.path.toLowerCase().contains('.mp4')) {
        streamUrl = cleaned;
        break;
      }
    }
  }

  if (streamUrl == null) return null;

  final document = html_parser.parse(html);
  final rawTitle = document.querySelector('meta[property="og:title"]')?.attributes['content'] ??
      document.querySelector('title')?.text ??
      'Instagram Video';
  var title = rawTitle.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
  if (title.isEmpty) title = 'instagram_${DateTime.now().millisecondsSinceEpoch}';

  return MediaSourceInfo(
    title: title,
    streamUrl: streamUrl,
    // The manager does not transcode. Saving an MP4 stream as .mp3 creates a
    // broken audio download, so preserve the source container.
    mediaType: 'video',
    fileExtension: '.mp4',
    thumbnailUrl: document.querySelector('meta[property="og:image"]')?.attributes['content'],
  );
}

String _cleanInstagramUrl(String raw) {
  var url = raw
      .replaceAll(r'\/', '/')
      .replaceAll(r'\\/', '/')
      .replaceAll(r'\u0026', '&')
      .replaceAll(r'\u00253A', ':')
      .replaceAll(r'\u00252F', '/')
      .replaceAll(r'\u0025', '%');

  try {
    url = Uri.decodeComponent(url);
  } catch (_) {}

  return url;
}

/// Provider for Facebook Videos, Reels, and Shorts using multi-strategy resolution (Redirect Unshortener, FDownloader API, GetMyFB API, SnapSave API, Embed Plugin, HTML Scrapers)
class FacebookSourceProvider implements MediaSourceProvider {
  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('facebook.com') || host.contains('fb.watch') || host.contains('fb.com');
  }

  @override
  Future<MediaSourceInfo> resolve(Uri url, {bool audioOnly = false}) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      followRedirects: true,
      maxRedirects: 10,
    ));

    String canonicalUrl = url.toString();

    // 0. Try facebookexternalhit crawler request first (Bypasses login gates & parses og:video/secure_url directly)
    try {
      final response = await dio.get<String>(
        canonicalUrl,
        options: Options(
          followRedirects: true,
          maxRedirects: 10,
          headers: {
            'User-Agent': 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ),
      );
      final realUri = response.realUri.toString();
      if (realUri.isNotEmpty && realUri.contains('facebook.com')) {
        canonicalUrl = realUri;
      }
      if (response.data != null && response.data!.isNotEmpty) {
        final result = _parseFbHtml(response.data!, audioOnly: audioOnly);
        if (result != null) return result;
      }
    } catch (e, stack) {
  print('Facebook resolver error: $e');
  print(stack);
}

    // Strategy 1: FDownloader / SaveFB API (ajaxSearch)
    try {
      final response = await dio.post(
        'https://fdownloader.net/api/ajaxSearch',
        data: 'q=${Uri.encodeComponent(canonicalUrl)}&vt=facebook',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest',
            'Origin': 'https://fdownloader.net',
            'Referer': 'https://fdownloader.net/',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        String htmlContent = '';
        if (response.data is Map && (response.data as Map)['data'] != null) {
          htmlContent = (response.data as Map)['data'].toString();
        } else if (response.data is String) {
          htmlContent = response.data as String;
        }

        if (htmlContent.isNotEmpty) {
          final unpackedHtml = _unpackIfNeeded(htmlContent);
          final result = _parseFbExtractorHtml(unpackedHtml, audioOnly: audioOnly);
          if (result != null) return result;
        }
      }
    }catch (e, stack) {
  print('Facebook resolver error: $e');
  print(stack);
}


    // Strategy 3: SnapSave API (action.php)
    try {
      final snapResponse = await dio.post<String>(
        'https://snapsave.app/action.php?lang=en',
        data: 'url=${Uri.encodeComponent(canonicalUrl)}',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest',
            'Origin': 'https://snapsave.app',
            'Referer': 'https://snapsave.app/',
          },
        ),
      );

      if (snapResponse.statusCode == 200 && snapResponse.data != null) {
        final unpackedHtml = _unpackIfNeeded(snapResponse.data!);
        final result = _parseFbExtractorHtml(unpackedHtml, audioOnly: audioOnly);
        if (result != null) return result;
      }
    } catch (e, stack) {
  print('Facebook resolver error: $e');
  print(stack);
}

    // Strategy 4: Direct Embed Plugin Resolver (plugins/video.php)
    final embedUrl = 'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(canonicalUrl)}&show_text=0';
    final userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
    ];

    for (final ua in userAgents) {
      try {
        final response = await dio.get<String>(
          embedUrl,
          options: Options(headers: {
            'User-Agent': ua,
            'Accept-Language': 'en-US,en;q=0.9',
            'Cookie': 'locale=en_US',
          }),
        );
        if (response.statusCode == 200 && response.data != null && response.data!.isNotEmpty) {
          final result = _parseFbHtml(response.data!, audioOnly: audioOnly);
          if (result != null) return result;
        }
      } catch (e, stack) {
  print('Facebook resolver error: $e');
  print(stack);
}

    }

    // Strategy 5: Target URL HTML parsing (mbasic & www)
    final fallbackUrls = [
      canonicalUrl,
      canonicalUrl.replaceAll('www.facebook.com', 'mbasic.facebook.com').replaceAll('m.facebook.com', 'mbasic.facebook.com'),
      canonicalUrl.replaceAll('www.facebook.com', 'm.facebook.com'),
    ];

    for (final fUrl in fallbackUrls) {
      for (final ua in userAgents) {
        try {
          final response = await dio.get<String>(
            fUrl,
            options: Options(headers: {
              'User-Agent': ua,
              'Accept-Language': 'en-US,en;q=0.9',
              'Cookie': 'locale=en_US',
            }),
          );
          if (response.statusCode == 200 && response.data != null) {
            final result = _parseFbHtml(response.data!, audioOnly: audioOnly);
            if (result != null) return result;
          }
        } catch (e, stack) {
  print('Facebook resolver error: $e');
  print(stack);
}

      }
    }

    return GenericSocialMediaProvider().resolve(url, audioOnly: audioOnly);
  }
}

  String _unpackIfNeeded(String content) {
    if (!content.contains('eval(function(p,a,c,k,e,d)')) {
      return content;
    }
    try {
      final match = RegExp(
        r'\}\s*\(\s*[\x27"](.*?)[\x27"]\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*[\x27"](.*?)[\x27"]\.split\('
      ).firstMatch(content);
      if (match != null) {
        final p = _unescapePackedString(match.group(1)!);
        final a = int.parse(match.group(2)!);
        final c = int.parse(match.group(3)!);
        final k = match.group(4)!.split('|');

        final unpacked = _unpackDeanEdwards(p, a, c, k);
        final htmlStart = unpacked.indexOf('<');
        final htmlEnd = unpacked.lastIndexOf('>');
        if (htmlStart != -1 && htmlEnd != -1 && htmlEnd > htmlStart) {
          return unpacked.substring(htmlStart, htmlEnd + 1)
              .replaceAll(r'\"', '"')
              .replaceAll(r'\/', '/')
              .replaceAll(r'\n', '\n')
              .replaceAll(r'\r', '\r')
              .replaceAll(r'\t', '\t');
        }
        return unpacked;
      }
    } catch (_) {}
    return content;
  }

  String _unescapePackedString(String s) {
    return s
        .replaceAll(r"\'", "'")
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', r'\');
  }

  String _unpackDeanEdwards(String p, int a, int c, List<String> k) {
    String encodeRadix(int val, int radix) {
      const chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      if (val == 0) return '0';
      var res = '';
      var temp = val;
      while (temp > 0) {
        res = chars[temp % radix] + res;
        temp = temp ~/ radix;
      }
      return res;
    }

    final Map<String, String> dict = {};
    for (int i = 0; i < k.length; i++) {
      final key = encodeRadix(i, a);
      if (k[i].isNotEmpty) {
        dict[key] = k[i];
      }
    }

    final regex = RegExp(r'\b[0-9a-zA-Z]+\b');
    return p.replaceAllMapped(regex, (match) {
      final word = match.group(0)!;
      return dict[word] ?? word;
    });
  }

  MediaSourceInfo? _parseFbExtractorHtml(String html, {bool audioOnly = false}) {
    final doc = html_parser.parse(html);
    final qualities = <MediaQualityOption>[];
    String? primaryStreamUrl;
    String? title;
    String? thumbnailUrl;

    final titleElem = doc.querySelector('.results-item-text') ?? doc.querySelector('h4') ?? doc.querySelector('h3');
    if (titleElem != null && titleElem.text.trim().isNotEmpty) {
      title = titleElem.text.trim().replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
    }

    final imgElem = doc.querySelector('.results-item-image img') ?? doc.querySelector('img[src*="fbcdn"]');
    if (imgElem?.attributes['src'] != null) {
      thumbnailUrl = imgElem!.attributes['src'];
    }

    // Check all <a> tags with video/download links
    final allLinks = doc.querySelectorAll('a');
    for (final link in allLinks) {
      final href = link.attributes['href'];
      if (href != null && href.startsWith('http')) {
        // Exclude App Store and Google Play Store ads, and Facebook help/plugin links
        if (href.contains('play.google.com') ||
            href.contains('apple.com') ||
            href.contains('market://') ||
            href.contains('facebook.com/plugins') ||
            href.contains('help/')) {
          continue;
        }

        // Keep links that are direct media or proxied stream/download links
        final text = link.text.trim().toLowerCase();
        final isVideoLink = href.contains('fbcdn.net') ||
            href.contains('cdninstagram.com') ||
            href.contains('instagram.com') ||
            href.contains('saveig.app') ||
            href.contains('snapinsta') ||
            href.contains('ssscdn.io') ||
            href.contains('.mp4') ||
            href.contains('snapsave') ||
            href.contains('fdownloader') ||
            text.contains('download') ||
            text.contains('hd') ||
            text.contains('sd') ||
            text.contains('normal') ||
            text.contains('high');

        if (!isVideoLink) continue;

        final isHd = text.contains('hd') ||
            text.contains('high') ||
            href.contains('quality_hd');
        final label = isHd ? '1080p / HD Quality' : '720p / SD Quality';

        if (!qualities.any((q) => q.streamUrl == href)) {
          qualities.add(MediaQualityOption(label: label, streamUrl: href));
        }
      }
    }

    if (qualities.isNotEmpty) {
      // Find HD quality if available, otherwise use the first one
      final hdOption = qualities.firstWhere(
        (q) => q.label.contains('HD') || q.label.contains('1080p'),
        orElse: () => qualities.first,
      );
      primaryStreamUrl = hdOption.streamUrl;
    }


    if (primaryStreamUrl == null) {
      final regexMatch = RegExp(r'https?:\\?/\\?/[^"\s\\]*?fbcdn\.net[^"\s\\]*?\.mp4[^"\s\\]*').firstMatch(html);
      if (regexMatch != null && regexMatch.group(0) != null) {
        primaryStreamUrl = _cleanEscapedUrl(regexMatch.group(0)!);
      }
    }

    if (primaryStreamUrl != null && primaryStreamUrl.isNotEmpty) {
      return MediaSourceInfo(
        title: (title != null && title.isNotEmpty) ? title : 'Facebook Video',
        streamUrl: primaryStreamUrl,
        mediaType: audioOnly ? 'audio' : 'video',
        fileExtension: audioOnly ? '.mp3' : '.mp4',
        thumbnailUrl: thumbnailUrl,
        availableQualities: qualities.isNotEmpty
            ? qualities
            : [
                MediaQualityOption(label: audioOnly ? '320 kbps (HQ)' : '1080p (HD)', streamUrl: primaryStreamUrl),
                MediaQualityOption(label: audioOnly ? '192 kbps (Standard)' : '720p (SD)', streamUrl: primaryStreamUrl),
              ],
      );
    }
    return null;
  }

  MediaSourceInfo? _parseFbHtml(String html, {bool audioOnly = false}) {
    final doc = html_parser.parse(html);
    String? title;
    final titleMeta = doc.querySelector('meta[property="og:title"]') ?? doc.querySelector('meta[name="title"]');
    if (titleMeta?.attributes['content'] != null && titleMeta!.attributes['content']!.isNotEmpty) {
      title = titleMeta.attributes['content']!.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
    }

    String? thumbnailUrl;
    final thumbMeta = doc.querySelector('meta[property="og:image"]');
    if (thumbMeta?.attributes['content'] != null) {
      thumbnailUrl = thumbMeta!.attributes['content'];
    }

    // Try parsing og:video or og:video:secure_url directly from crawler page
    final ogVideoMeta = doc.querySelector('meta[property="og:video"]') ??
        doc.querySelector('meta[property="og:video:secure_url"]');
    if (ogVideoMeta?.attributes['content'] != null && ogVideoMeta!.attributes['content']!.isNotEmpty) {
      final streamUrl = _cleanEscapedUrl(ogVideoMeta.attributes['content']!);
      if (streamUrl.startsWith('http')) {
        return MediaSourceInfo(
          title: (title != null && title.isNotEmpty) ? title : 'Facebook Video',
          streamUrl: streamUrl,
          mediaType: audioOnly ? 'audio' : 'video',
          fileExtension: audioOnly ? '.mp3' : '.mp4',
          thumbnailUrl: thumbnailUrl,
          availableQualities: [
            MediaQualityOption(label: audioOnly ? '320 kbps (HQ)' : '1080p (HD)', streamUrl: streamUrl),
            MediaQualityOption(label: audioOnly ? '192 kbps (Standard)' : '720p (SD)', streamUrl: streamUrl),
          ],
        );
      }
    }

    final qualities = <MediaQualityOption>[];
    String? hdUrl;
    String? sdUrl;

    final hdMatch = RegExp(r'"(playable_url_quality_hd|hd_src|hd_src_no_ratelimit|browser_native_hd_url)"\s*:\s*"([^"]+)"').firstMatch(html);
    if (hdMatch != null && hdMatch.group(2) != null) {
      hdUrl = _cleanEscapedUrl(Uri.decodeComponent(hdMatch.group(2)!));
    }

    final sdMatch = RegExp(r'"(playable_url|sd_src|sd_src_no_ratelimit|browser_native_sd_url)"\s*:\s*"([^"]+)"').firstMatch(html);
    if (sdMatch != null && sdMatch.group(2) != null) {
      sdUrl = _cleanEscapedUrl(Uri.decodeComponent(sdMatch.group(2)!));
    }

    if (hdUrl != null && hdUrl.startsWith('http')) {
      qualities.add(MediaQualityOption(label: audioOnly ? '320 kbps (HQ)' : '1080p (HD)', streamUrl: hdUrl));
    }
    if (sdUrl != null && sdUrl.startsWith('http')) {
      qualities.add(MediaQualityOption(label: audioOnly ? '192 kbps (Standard)' : '720p (SD)', streamUrl: sdUrl));
    }

    final primaryUrl = hdUrl ?? sdUrl;
    if (primaryUrl != null && primaryUrl.startsWith('http')) {
      return MediaSourceInfo(
        title: (title != null && title.isNotEmpty) ? title : 'Facebook Video',
        streamUrl: primaryUrl,
        mediaType: audioOnly ? 'audio' : 'video',
        fileExtension: audioOnly ? '.mp3' : '.mp4',
        thumbnailUrl: thumbnailUrl,
        availableQualities: qualities.isNotEmpty
            ? qualities
            : [
                MediaQualityOption(label: audioOnly ? '320 kbps (HQ)' : '1080p (HD)', streamUrl: primaryUrl),
              ],
      );
    }

    // Direct fbcdn mp4 fallback
    final fbcdnRegex = RegExp(r'https?:\\?/\\?/[^"\s\\]*?fbcdn\.net[^"\s\\]*?\.mp4[^"\s\\]*').firstMatch(html);
    if (fbcdnRegex != null && fbcdnRegex.group(0) != null) {
      final cleanUrl = _cleanEscapedUrl(fbcdnRegex.group(0)!);
      return MediaSourceInfo(
        title: (title != null && title.isNotEmpty) ? title : 'Facebook Video',
        streamUrl: cleanUrl,
        mediaType: audioOnly ? 'audio' : 'video',
        fileExtension: audioOnly ? '.mp3' : '.mp4',
        thumbnailUrl: thumbnailUrl,
        availableQualities: [
          MediaQualityOption(label: audioOnly ? '320 kbps (HQ)' : '1080p (HD)', streamUrl: cleanUrl),
        ],
      );
    }

    return null;
  }

  String _cleanEscapedUrl(String raw) {
    return raw
        .replaceAll(r'\/', '/')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\u00253A', ':')
        .replaceAll(r'\u00252F', '/')
        .replaceAll(r'\u0025', '%');
  }


/// Provider for Twitter / X posts and videos using multi-strategy resolution (vxtwitter API, fxtwitter API, Cobalt Engine API, TwitSave API, OpenGraph Proxy Mirrors)
class TwitterSourceProvider implements MediaSourceProvider {
  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('twitter.com') ||
        host.contains('x.com') ||
        host.contains('t.co') ||
        host.contains('vxtwitter.com') ||
        host.contains('fxtwitter.com') ||
        host.contains('fixupx.com');
  }

  @override
  Future<MediaSourceInfo> resolve(Uri url, {bool audioOnly = false}) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
    ));

    final originalUrl = url.toString();
    var cleanUrl = originalUrl;
    if (cleanUrl.contains('t.co/')) {
      try {
        final res = await dio.head<void>(cleanUrl);
        if (res.realUri.toString().isNotEmpty) {
          cleanUrl = res.realUri.toString();
        }
      } catch (_) {}
    }

    final statusMatch = RegExp(r'/status/(\d+)').firstMatch(cleanUrl);
    final statusId = statusMatch?.group(1);

    // Strategy 1: vxtwitter API (api.vxtwitter.com)
    if (statusId != null) {
      try {
        final vxUrl = 'https://api.vxtwitter.com/Twitter/status/$statusId';
        final response = await dio.get<Map<String, dynamic>>(
          vxUrl,
          options: Options(headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          }),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data!;
          final mediaList = data['media_extended'] as List?;
          if (mediaList != null && mediaList.isNotEmpty) {
            for (final item in mediaList) {
              if (item is Map) {
                final type = item['type']?.toString();
                final streamUrl = item['url']?.toString();
                if ((type == 'video' || type == 'gif') && streamUrl != null && streamUrl.isNotEmpty) {
                  final text = data['text']?.toString() ?? 'Twitter Video';
                  var title = text.split('\n').first;
                  title = title.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
                  if (title.isEmpty) title = 'twitter_${DateTime.now().millisecondsSinceEpoch}';

                  final thumbnail = data['user_screen_name'] != null ? item['thumbnail_url']?.toString() : null;

                  return MediaSourceInfo(
                    title: title,
                    streamUrl: streamUrl,
                    mediaType: audioOnly ? 'audio' : 'video',
                    fileExtension: audioOnly ? '.mp3' : '.mp4',
                    thumbnailUrl: thumbnail,
                  );
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    // Strategy 2: fxtwitter API (api.fxtwitter.com)
    if (statusId != null) {
      try {
        final fxUrl = 'https://api.fxtwitter.com/status/$statusId';
        final response = await dio.get<Map<String, dynamic>>(
          fxUrl,
          options: Options(headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          }),
        );

        if (response.statusCode == 200 && response.data != null) {
          final tweet = response.data!['tweet'] as Map?;
          if (tweet != null) {
            final media = tweet['media'] as Map?;
            final videos = media?['videos'] as List?;
            if (videos != null && videos.isNotEmpty) {
              final firstVideo = videos.first as Map;
              final variants = firstVideo['variants'] as List?;
              String? bestUrl;
              int maxBitrate = -1;

              if (variants != null) {
                for (final v in variants) {
                  if (v is Map) {
                    final vUrl = v['url']?.toString();
                    final bitrate = (v['bitrate'] as num?)?.toInt() ?? 0;
                    if (vUrl != null && vUrl.isNotEmpty && bitrate >= maxBitrate) {
                      maxBitrate = bitrate;
                      bestUrl = vUrl;
                    }
                  }
                }
              }

              bestUrl ??= firstVideo['url']?.toString();

              if (bestUrl != null && bestUrl.isNotEmpty) {
                final text = tweet['text']?.toString() ?? 'Twitter Video';
                var title = text.split('\n').first;
                title = title.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
                if (title.isEmpty) title = 'twitter_${DateTime.now().millisecondsSinceEpoch}';

                return MediaSourceInfo(
                  title: title,
                  streamUrl: bestUrl,
                  mediaType: audioOnly ? 'audio' : 'video',
                  fileExtension: audioOnly ? '.mp3' : '.mp4',
                  thumbnailUrl: firstVideo['thumbnail_url']?.toString(),
                );
              }
            }
          }
        }
      } catch (_) {}
    }

    // Strategy 3: Cobalt Engine API
    try {
      final cobaltResponse = await dio.post<Map<String, dynamic>>(
        'https://api.cobalt.tools/api/json',
        data: {
          'url': cleanUrl,
          'videoQuality': 'max',
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        }),
      );
      if (cobaltResponse.statusCode == 200 && cobaltResponse.data != null) {
        final data = cobaltResponse.data!;
        final streamUrl = data['url']?.toString();
        if (streamUrl != null && streamUrl.isNotEmpty) {
          final title = data['filename']?.toString() ?? 'Twitter Video';
          return MediaSourceInfo(
            title: title,
            streamUrl: streamUrl,
            mediaType: audioOnly ? 'audio' : 'video',
            fileExtension: audioOnly ? '.mp3' : '.mp4',
          );
        }
      }
    } catch (_) {}

    // Strategy 4: TwitSave HTML Scraper
    try {
      final twitSaveUrl = 'https://twitsave.com/info?url=${Uri.encodeComponent(cleanUrl)}';
      final response = await dio.get<String>(
        twitSaveUrl,
        options: Options(headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        }),
      );
      if (response.statusCode == 200 && response.data != null) {
        final html = response.data!;
        final doc = html_parser.parse(html);
        final downloadBtn = doc.querySelector('a[href*="twitsave.com/download"]') ??
            doc.querySelector('a[href*="video.twimg.com"]') ??
            doc.querySelector('a.origin-button');

        final streamUrl = downloadBtn?.attributes['href'];
        if (streamUrl != null && streamUrl.isNotEmpty) {
          final titleElem = doc.querySelector('p.text-gray-800') ?? doc.querySelector('title');
          var title = titleElem?.text ?? 'Twitter Video';
          title = title.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
          if (title.isEmpty) title = 'twitter_${DateTime.now().millisecondsSinceEpoch}';

          return MediaSourceInfo(
            title: title,
            streamUrl: streamUrl,
            mediaType: audioOnly ? 'audio' : 'video',
            fileExtension: audioOnly ? '.mp3' : '.mp4',
          );
        }
      }
    } catch (_) {}

    // Strategy 5: OpenGraph Proxy Scraper (vxtwitter / fxtwitter / fixupx with Discordbot UA)
    final proxyHosts = ['vxtwitter.com', 'fxtwitter.com', 'fixupx.com'];
    for (final proxyHost in proxyHosts) {
      try {
        var proxyUrl = cleanUrl;
        if (proxyUrl.contains('twitter.com')) {
          proxyUrl = proxyUrl.replaceAll('twitter.com', proxyHost);
        } else if (proxyUrl.contains('x.com')) {
          proxyUrl = proxyUrl.replaceAll('x.com', proxyHost);
        }

        final response = await dio.get<String>(
          proxyUrl,
          options: Options(headers: {
            'User-Agent': 'Discordbot/2.0',
          }),
        );
        if (response.statusCode == 200 && response.data != null) {
          final doc = html_parser.parse(response.data!);
          final videoMeta = doc.querySelector('meta[property="og:video"]') ??
              doc.querySelector('meta[property="og:video:secure_url"]') ??
              doc.querySelector('meta[property="og:video:url"]') ??
              doc.querySelector('meta[name="twitter:player:stream"]');
          if (videoMeta?.attributes['content'] != null && videoMeta!.attributes['content']!.isNotEmpty) {
            final streamUrl = videoMeta.attributes['content']!;
            final titleMeta = doc.querySelector('meta[property="og:title"]') ?? doc.querySelector('meta[name="twitter:title"]');
            var title = titleMeta?.attributes['content'] ?? 'Twitter Video';
            title = title.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
            if (title.isEmpty) title = 'twitter_${DateTime.now().millisecondsSinceEpoch}';

            return MediaSourceInfo(
              title: title,
              streamUrl: streamUrl,
              mediaType: audioOnly ? 'audio' : 'video',
              fileExtension: audioOnly ? '.mp3' : '.mp4',
            );
          }
        }
      } catch (_) {}
    }

    return GenericSocialMediaProvider().resolve(url, audioOnly: audioOnly);
  }
}

/// Generic OpenGraph / Meta Tag provider for public web and social media links (Instagram, X, TikTok, Facebook, etc.)
class GenericSocialMediaProvider implements MediaSourceProvider {
  @override
  bool canHandle(Uri url) {
    final scheme = url.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  @override
  Future<MediaSourceInfo> resolve(Uri url, {bool audioOnly = false}) async {
    final dio = Dio(
      BaseOptions(
        followRedirects: true,
        maxRedirects: 10,
        validateStatus: (status) => status != null && status < 500,
        receiveTimeout: const Duration(seconds: 12),
        connectTimeout: const Duration(seconds: 12),
      ),
    );

    // List of user agents: Android Mobile, FB External Hit, Desktop Chrome
    final userAgents = [
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    ];

    // Try target URL as well as m.facebook.com variant if it's a Facebook share link
    final targetUrls = [url.toString()];
    if (url.host.contains('facebook.com') && !url.host.startsWith('m.')) {
      targetUrls.add(url.toString().replaceFirst('www.facebook.com', 'm.facebook.com'));
    }

    String? htmlBody;
    String? foundVideoUrl;

    for (final targetUrl in targetUrls) {
      for (final ua in userAgents) {
        try {
          final response = await dio.get<String>(
            targetUrl,
            options: Options(headers: {'User-Agent': ua}),
          );
          if (response.statusCode == 200 && response.data != null && response.data!.isNotEmpty) {
            htmlBody = response.data;
            foundVideoUrl = _extractVideoUrlFromHtml(htmlBody!);
            if (foundVideoUrl != null && foundVideoUrl.isNotEmpty) {
              break;
            }
          }
        } catch (err) {
          // Log resolution attempt
        }
      }
      if (foundVideoUrl != null && foundVideoUrl.isNotEmpty) break;
    }

    if (foundVideoUrl != null && foundVideoUrl.isNotEmpty) {
      var title = 'Social Media Video';
      if (htmlBody != null) {
        final document = html_parser.parse(htmlBody);
        final titleMeta = document.querySelector('meta[property="og:title"]') ??
            document.querySelector('meta[name="twitter:title"]');
        if (titleMeta?.attributes['content'] != null) {
          title = titleMeta!.attributes['content']!;
        }
      }
      title = title.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
      if (title.isEmpty) title = 'social_video_${DateTime.now().millisecondsSinceEpoch}';

      return MediaSourceInfo(
        title: title,
        streamUrl: foundVideoUrl,
        mediaType: 'video',
        fileExtension: '.mp4',
      );
    }

    throw Exception('Unable to resolve video stream. Make sure the post is public and try again.');
  }

  String? _extractVideoUrlFromHtml(String htmlBody) {
    // 1. Try HTML meta tags
    final document = html_parser.parse(htmlBody);
    final videoMeta = document.querySelector('meta[property="og:video"]') ??
        document.querySelector('meta[property="og:video:secure_url"]') ??
        document.querySelector('meta[property="og:video:url"]') ??
        document.querySelector('meta[name="twitter:player:stream"]');

    if (videoMeta?.attributes['content'] != null && videoMeta!.attributes['content']!.isNotEmpty) {
      return videoMeta.attributes['content'];
    }

    // 2. Try Facebook/Instagram/TikTok/X JSON stream properties
    final socialMediaJsonPatterns = [
      RegExp(r'"playable_url_quality_hd"\s*:\s*"([^"]+)"'),
      RegExp(r'"playable_url"\s*:\s*"([^"]+)"'),
      RegExp(r'"browser_native_hd_url"\s*:\s*"([^"]+)"'),
      RegExp(r'"browser_native_sd_url"\s*:\s*"([^"]+)"'),
      RegExp(r'"hd_src"\s*:\s*"([^"]+)"'),
      RegExp(r'"sd_src"\s*:\s*"([^"]+)"'),
      RegExp(r'"playAddr"\s*:\s*"([^"]+)"'),
      RegExp(r'"downloadAddr"\s*:\s*"([^"]+)"'),
      RegExp(r'"video_url"\s*:\s*"([^"]+)"'),
      RegExp(r'"contentUrl"\s*:\s*"([^"]+)"'),
    ];

    for (final pattern in socialMediaJsonPatterns) {
      final match = pattern.firstMatch(htmlBody);
      if (match != null && match.group(1) != null) {
        return _cleanEscapedUrl(match.group(1)!);
      }
    }

    // 3. Fallback: regex search for any video .mp4 URL in HTML
    final mp4Regex = RegExp(r'https?:\\?/\\?/[^"\s\\]+?\.mp4[^"\s\\]*');
    final match = mp4Regex.firstMatch(htmlBody);
    if (match != null && match.group(0) != null) {
      return _cleanEscapedUrl(match.group(0)!);
    }

    return null;
  }

  String _cleanEscapedUrl(String raw) {
    var unescaped = raw.replaceAll(r'\/', '/').replaceAll(r'\u0026', '&');
    if (unescaped.contains(r'\u0025')) {
      unescaped = unescaped.replaceAll(r'\u00253A', ':').replaceAll(r'\u00252F', '/');
    }
    return unescaped;
  }
}
