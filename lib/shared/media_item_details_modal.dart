import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/providers/providers.dart';
import '../domain/entities/media_item_entity.dart';
import '../features/favorites/presentation/controllers/favorites_controller.dart';
import '../features/playlists/presentation/widgets/add_to_playlist_dialog.dart';
import 'media_thumbnail.dart';

class MediaItemDetailsModal extends ConsumerWidget {
  final MediaItemEntity item;

  const MediaItemDetailsModal({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, MediaItemEntity item) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaItemDetailsModal(item: item),
    );
  }

  Future<void> _confirmAndDeleteFile(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete File from Device?'),
        content: Text(
          'Are you sure you want to permanently delete "${item.title}" from your storage?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
      await ref.read(mediaRepositoryProvider).deleteMediaFile(item.id, item.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${item.title}" from device storage.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDuration(int? durationSeconds) {
    if (durationSeconds == null || durationSeconds <= 0) return 'Unknown';
    final duration = Duration(seconds: durationSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Unknown';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year at $hour:$minute $period';
  }

  Future<void> _shareFile(BuildContext context) async {
    Navigator.pop(context);
    try {
      final file = File(item.path);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(item.path)],
          text: 'Sharing "${item.title}" from MediaHub',
        );
      } else {
        await Share.share('Check out "${item.title}" on MediaHub');
      }
    } catch (e) {
      if (context.mounted) {
        final isMissingPlugin = e.toString().contains('MissingPluginException');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMissingPlugin
                  ? 'Please stop and restart the app completely (full rebuild) to enable native file sharing.'
                  : 'Unable to share file: $e',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final favoriteIdsAsync = ref.watch(favoriteMediaIdsStreamProvider);
    final isFavorite = favoriteIdsAsync.value?.contains(item.id) ?? false;
    final isAudio = item.mediaType == 'audio';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MediaThumbnail(
                      artworkPath: item.artworkPath,
                      mediaType: item.mediaType,
                      size: 64,
                      borderRadius: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAudio
                                      ? Icons.music_note_rounded
                                      : Icons.movie_rounded,
                                  size: 14,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAudio ? 'Audio Track' : 'Video File',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'FILE INFORMATION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.title_rounded,
              label: 'Title',
              value: item.title,
            ),
            _DetailRow(
              icon: Icons.person_rounded,
              label: isAudio ? 'Artist' : 'Source',
              value: item.artist ?? (isAudio ? 'Unknown Artist' : 'Local Video'),
            ),
            if (item.album != null && item.album!.isNotEmpty)
              _DetailRow(
                icon: Icons.album_rounded,
                label: 'Album',
                value: item.album!,
              ),
            if (item.genre != null && item.genre!.isNotEmpty)
              _DetailRow(
                icon: Icons.category_rounded,
                label: 'Genre',
                value: item.genre!,
              ),
            _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: _formatDuration(item.duration),
            ),
            _DetailRow(
              icon: Icons.storage_rounded,
              label: 'File Size',
              value: _formatFileSize(item.fileSize),
            ),
            _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date Added to Device',
              value: _formatDate(item.dateAdded),
            ),
            if (item.lastPlayed != null)
              _DetailRow(
                icon: Icons.history_rounded,
                label: 'Last Played',
                value: _formatDate(item.lastPlayed!),
              ),
            _DetailRow(
              icon: Icons.folder_open_rounded,
              label: 'File Path',
              value: item.path,
              isPath: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      minimumSize: const Size(0, 42),
                    ),
                    onPressed: () => _shareFile(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.share_rounded, size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Share',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      minimumSize: const Size(0, 42),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      AddToPlaylistDialog.show(context, item);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.playlist_add_rounded, size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Playlist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      minimumSize: const Size(0, 42),
                      foregroundColor: isFavorite ? Colors.redAccent : colorScheme.primary,
                    ),
                    onPressed: () {
                      ref
                          .read(favoritesControllerProvider)
                          .toggleFavorite(item.id);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isFavorite ? 'Saved' : 'Favorite',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: () => _confirmAndDeleteFile(context, ref),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    minimumSize: const Size(42, 42),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 20),
                  tooltip: 'Delete File',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isPath;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isPath = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (isPath)
                  SelectableText(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  )
                else
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
