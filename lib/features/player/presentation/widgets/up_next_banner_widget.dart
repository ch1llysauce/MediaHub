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
    final isVideo = item.mediaType == 'video';
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    // Dedicated type recognition colors for AUDIO vs VIDEO chips
    final typeAccentColor = isVideo ? const Color(0xFFFFB74D) : const Color(0xFF4DD0E1);
    final badgeBg = typeAccentColor.withValues(alpha: 0.18);
    final badgeBorder = typeAccentColor.withValues(alpha: 0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: isLandscape ? 0.0 : 14.0,
        vertical: isLandscape ? 0.0 : 8.0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 10.0 : 12.0,
        vertical: isLandscape ? 6.0 : 10.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E28).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(isLandscape ? 16.0 : 20.0),
        border: Border.all(
          color: primaryAccent.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onDismiss != null) ...[
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(isLandscape ? 4.0 : 6.0),
                child: Icon(
                  Icons.close_rounded,
                  size: isLandscape ? 18 : 20,
                  color: Colors.white70,
                ),
              ),
            ),
            SizedBox(width: isLandscape ? 2 : 4),
          ],
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
                      style: TextStyle(
                        color: primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: isLandscape ? 11 : 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Type Recognition Chip (AUDIO / VIDEO)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(color: badgeBorder, width: 0.8),
                      ),
                      child: Text(
                        isVideo ? 'VIDEO' : 'AUDIO',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: typeAccentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isLandscape ? 2 : 4),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isLandscape ? 12.5 : 13.5,
                  ),
                ),
                if (!isLandscape) ...[
                  const SizedBox(height: 1),
                  Text(
                    item.artist ?? (isVideo ? 'Video File' : 'Unknown Artist'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Play Now Action Button
          ElevatedButton(
            onPressed: onPlayNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 10 : 12,
                vertical: isLandscape ? 6 : 8,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.skip_next_rounded, size: isLandscape ? 15 : 16, color: Colors.black),
                const SizedBox(width: 3),
                Text(
                  'Play Now',
                  style: TextStyle(
                    fontSize: isLandscape ? 11 : 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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
