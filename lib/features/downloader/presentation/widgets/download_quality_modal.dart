import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/downloader/media_source_provider.dart';
import '../controllers/downloads_controller.dart';

class DownloadQualityModal extends ConsumerStatefulWidget {
  final String originalUrl;
  final MediaSourceInfo mediaInfo;
  final bool audioOnly;

  const DownloadQualityModal({
    super.key,
    required this.originalUrl,
    required this.mediaInfo,
    required this.audioOnly,
  });

  static Future<void> show(
    BuildContext context, {
    required String originalUrl,
    required MediaSourceInfo mediaInfo,
    required bool audioOnly,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadQualityModal(
        originalUrl: originalUrl,
        mediaInfo: mediaInfo,
        audioOnly: audioOnly,
      ),
    );
  }

  @override
  ConsumerState<DownloadQualityModal> createState() => _DownloadQualityModalState();
}

class _DownloadQualityModalState extends ConsumerState<DownloadQualityModal> {
  late MediaQualityOption _selectedQuality;

  @override
  void initState() {
    super.initState();
    final qualities = widget.mediaInfo.availableQualities;
    if (qualities.isNotEmpty) {
      _selectedQuality = qualities.first;
    } else {
      _selectedQuality = MediaQualityOption(
        label: widget.audioOnly ? '320 kbps (HQ)' : '1080p (HD)',
        streamUrl: widget.mediaInfo.streamUrl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qualities = widget.mediaInfo.availableQualities.isNotEmpty
        ? widget.mediaInfo.availableQualities
        : [
            MediaQualityOption(
              label: widget.audioOnly ? '320 kbps (HQ)' : '1080p (HD)',
              streamUrl: widget.mediaInfo.streamUrl,
            ),
            MediaQualityOption(
              label: widget.audioOnly ? '192 kbps (Standard)' : '720p (HD)',
              streamUrl: widget.mediaInfo.streamUrl,
            ),
            MediaQualityOption(
              label: widget.audioOnly ? '128 kbps (Compact)' : '480p (SD)',
              streamUrl: widget.mediaInfo.streamUrl,
            ),
          ];

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 32.0 : 24.0,
          vertical: isLandscape ? 12.0 : 16.0,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title
            Row(
              children: [
                Icon(
                  widget.audioOnly ? Icons.audiotrack_rounded : Icons.video_library_rounded,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  'Select Download Quality',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Thumbnail Preview & Title Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // Thumbnail preview image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.mediaInfo.thumbnailUrl != null &&
                            widget.mediaInfo.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            widget.mediaInfo.thumbnailUrl!,
                            width: 90,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildThumbnailFallback(theme),
                          )
                        : _buildThumbnailFallback(theme),
                  ),
                  const SizedBox(width: 14),

                  // Title & Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mediaInfo.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.audioOnly ? 'AUDIO' : 'VIDEO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quality Selection Label
            Text(
              widget.audioOnly ? 'Available Audio Quality:' : 'Available Video Quality:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),

            // Choice Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: qualities.map((q) {
                final isSelected = _selectedQuality.label == q.label;
                final displayLabel = q.label;
                final chipText = q.sizeLabel != null ? '$displayLabel (${q.sizeLabel})' : displayLabel;
                return ChoiceChip(
                  label: Text(
                    chipText,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedQuality = q);
                    }
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Download CTA Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await ref.read(downloadsControllerProvider.notifier).startDownload(
                        widget.originalUrl,
                        audioOnly: widget.audioOnly,
                        customTitle: widget.mediaInfo.title,
                        customStreamUrl: _selectedQuality.streamUrl,
                        customExtension: _selectedQuality.fileExtension ?? widget.mediaInfo.fileExtension,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Starting download (${_selectedQuality.label})...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  'Start Download • ${_selectedQuality.label}',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildThumbnailFallback(ThemeData theme) {
    return Container(
      width: 90,
      height: 64,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          widget.audioOnly ? Icons.music_note_rounded : Icons.movie_rounded,
          color: theme.colorScheme.primary,
          size: 30,
        ),
      ),
    );
  }
}
