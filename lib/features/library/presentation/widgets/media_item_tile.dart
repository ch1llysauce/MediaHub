import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/media_item_entity.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';

class MediaItemTile extends ConsumerWidget {
  final MediaItemEntity item;
  final String? customSubtitle;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const MediaItemTile({
    super.key,
    required this.item,
    this.customSubtitle,
    this.onTap,
    this.onMoreTap,
  });

  String _formatDuration(int? durationSeconds) {
    if (durationSeconds == null || durationSeconds <= 0) return '--:--';
    final duration = Duration(seconds: durationSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAudio = item.mediaType == 'audio';

    final favoriteIdsAsync = ref.watch(favoriteMediaIdsStreamProvider);
    final isFavorite = favoriteIdsAsync.value?.contains(item.id) ?? false;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 52,
          height: 52,
          color: isAudio
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer,
          child: Icon(
            isAudio ? Icons.music_note_rounded : Icons.movie_rounded,
            color: isAudio
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSecondaryContainer,
            size: 28,
          ),
        ),
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              customSubtitle ?? item.artist ?? (isAudio ? 'Unknown Artist' : 'Local Video'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(item.duration),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (item.fileSize > 0) ...[
            const SizedBox(width: 6),
            Text(
              '• ${_formatFileSize(item.fileSize)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.redAccent : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            onPressed: () {
              ref.read(favoritesControllerProvider).toggleFavorite(item.id);
            },
            tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: onMoreTap,
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }
}
