import 'dart:async';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MediaQualityOption {
  final String label; // e.g. "1080p (HD)", "720p (HD)", "480p (SD)", "360p" or "320 kbps (HQ)", "192 kbps"
  final String streamUrl;
  final String? sizeLabel;

  const MediaQualityOption({
    required this.label,
    required this.streamUrl,
    this.sizeLabel,
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
      final video = await yt.videos.get(url.toString());
      final manifest = await yt.videos.streamsClient.getManifest(video.id);

      final thumbnailUrl = video.thumbnails.highResUrl.isNotEmpty
          ? video.thumbnails.highResUrl
          : video.thumbnails.mediumResUrl;

      final qualities = <MediaQualityOption>[];

      if (audioOnly && manifest.audioOnly.isNotEmpty) {
        final sortedAudio = manifest.audioOnly.toList()
          ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
        for (final s in sortedAudio) {
          final kbits = (s.bitrate.bitsPerSecond / 1000).round();
          final formatTag = s.container.name.toLowerCase() == 'mp4' ? 'MP3' : s.container.name.toUpperCase();
          final label = '$kbits kbps ($formatTag)';
          if (!qualities.any((q) => q.label == label)) {
            qualities.add(MediaQualityOption(
              label: label,
              streamUrl: s.url.toString(),
              sizeLabel: s.size.totalBytes > 0
                  ? '${(s.size.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                  : null,
            ));
          }
        }

        final mainStream = manifest.audioOnly.withHighestBitrate();
        return MediaSourceInfo(
          title: video.title,
          streamUrl: mainStream.url.toString(),
          mediaType: 'audio',
          fileExtension: '.mp3',
          thumbnailUrl: thumbnailUrl,
          availableQualities: qualities.isNotEmpty
              ? qualities
              : [
                  MediaQualityOption(label: '320 kbps (HQ MP3)', streamUrl: mainStream.url.toString()),
                  MediaQualityOption(label: '192 kbps (Standard MP3)', streamUrl: mainStream.url.toString()),
                  MediaQualityOption(label: '128 kbps (Compact MP3)', streamUrl: mainStream.url.toString()),
                ],
        );
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
            ));
          }
        }

        final mainStream = manifest.muxed.withHighestBitrate();

        return MediaSourceInfo(
          title: video.title,
          streamUrl: mainStream.url.toString(),
          mediaType: 'video',
          fileExtension: '.${mainStream.container.name}',
          thumbnailUrl: thumbnailUrl,
          availableQualities: qualities.isNotEmpty
              ? qualities
              : [
                  MediaQualityOption(label: '720p (HD)', streamUrl: mainStream.url.toString()),
                  MediaQualityOption(label: '480p (SD)', streamUrl: mainStream.url.toString()),
                  MediaQualityOption(label: '360p (SD)', streamUrl: mainStream.url.toString()),
                ],
        );
      }

      if (manifest.audioOnly.isNotEmpty) {
        final audioStream = manifest.audioOnly.withHighestBitrate();
        return MediaSourceInfo(
          title: video.title,
          streamUrl: audioStream.url.toString(),
          mediaType: 'audio',
          fileExtension: '.m4a',
          thumbnailUrl: thumbnailUrl,
          availableQualities: [
            MediaQualityOption(label: '320 kbps (HQ)', streamUrl: audioStream.url.toString()),
            MediaQualityOption(label: '192 kbps (Standard)', streamUrl: audioStream.url.toString()),
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
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      followRedirects: true,
    ));

    final ddUrl = url.toString().replaceAll('instagram.com', 'ddinstagram.com');
    try {
      final response = await dio.get<String>(
        ddUrl,
        options: Options(headers: {
          'User-Agent': 'telegrambot',
        }),
      );
      if (response.statusCode == 200 && response.data != null) {
        final html = response.data!;
        final document = html_parser.parse(html);
        final videoMeta = document.querySelector('meta[property="og:video"]') ??
            document.querySelector('meta[property="og:video:secure_url"]');
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

    return GenericSocialMediaProvider().resolve(url, audioOnly: audioOnly);
  }
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

    // 0. Resolve short share links (fb.watch, facebook.com/share/r/, etc.) to canonical URL
    try {
      final redirectResponse = await dio.get<String>(
        canonicalUrl,
        options: Options(
          followRedirects: true,
          maxRedirects: 10,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ),
      );
      final realUri = redirectResponse.realUri.toString();
      if (realUri.isNotEmpty && realUri.contains('facebook.com')) {
        canonicalUrl = realUri;
      }
    } catch (_) {}

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
          final result = _parseFbExtractorHtml(htmlContent, audioOnly: audioOnly);
          if (result != null) return result;
        }
      }
    } catch (_) {}

    // Strategy 2: GetMyFB API (process)
    try {
      final apiResponse = await dio.post<String>(
        'https://getmyfb.com/process',
        data: 'id=${Uri.encodeComponent(canonicalUrl)}&locale=en',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest',
            'Origin': 'https://getmyfb.com',
            'Referer': 'https://getmyfb.com/',
          },
        ),
      );

      if (apiResponse.statusCode == 200 && apiResponse.data != null) {
        final result = _parseFbExtractorHtml(apiResponse.data!, audioOnly: audioOnly);
        if (result != null) return result;
      }
    } catch (_) {}

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
        final result = _parseFbExtractorHtml(snapResponse.data!, audioOnly: audioOnly);
        if (result != null) return result;
      }
    } catch (_) {}

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
      } catch (_) {}
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
        } catch (_) {}
      }
    }

    return GenericSocialMediaProvider().resolve(url, audioOnly: audioOnly);
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
    final allLinks = doc.querySelectorAll('a[href*="fbcdn"], a[href*=".mp4"], a[href*="download"]');
    for (final link in allLinks) {
      final href = link.attributes['href'];
      if (href != null && href.startsWith('http')) {
        final isHd = link.text.toUpperCase().contains('HD') || href.contains('quality_hd');
        final label = isHd ? '1080p / HD Quality' : '720p / SD Quality';
        if (!qualities.any((q) => q.streamUrl == href)) {
          qualities.add(MediaQualityOption(label: label, streamUrl: href));
        }
        primaryStreamUrl ??= href;
      }
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
