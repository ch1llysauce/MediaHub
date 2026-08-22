import 'package:flutter/material.dart';
import '../../../../domain/entities/media_item_entity.dart';

class UpNextBannerWidget extends StatelessWidget {
  final MediaItemEntity item;
  final int remainingSeconds;
  final VoidCallback onPlayNow;
  final VoidCallback? onDismiss;

  const UpNextBannerWidget({
    super.key,
    required this.item,
    required this.remainingSeconds,
    required this.onPlayNow,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isVideo = item.mediaType == 'video';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isVideo ? Colors.amber.shade400 : colorScheme.primary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 24,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
          // Title, Artist, & Media Type Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Up Next in ${remainingSeconds}s',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isVideo
                            ? Colors.amber.shade400.withValues(alpha: 0.2)
                            : colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        isVideo ? '🎬 VIDEO' : '🎵 AUDIO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isVideo ? Colors.amber.shade400 : colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.artist ?? (isVideo ? 'Video File' : 'Unknown Artist'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Play Now Action Button
          FilledButton.tonal(
            onPressed: onPlayNow,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.skip_next_rounded, size: 16),
                SizedBox(width: 4),
                Text('Play Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
