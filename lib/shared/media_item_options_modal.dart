import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/providers/providers.dart';
import '../domain/entities/media_item_entity.dart';
import '../features/favorites/presentation/controllers/favorites_controller.dart';
import '../features/playlists/presentation/widgets/add_to_playlist_dialog.dart';
import 'media_thumbnail.dart';

class MediaItemOptionsModal extends ConsumerWidget {
  final MediaItemEntity item;
  final VoidCallback? onRemoveFromHistory;

  const MediaItemOptionsModal({
    super.key,
    required this.item,
    this.onRemoveFromHistory,
  });

  static Future<void> show(
    BuildContext context,
    MediaItemEntity item, {
    VoidCallback? onRemoveFromHistory,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaItemOptionsModal(
        item: item,
        onRemoveFromHistory: onRemoveFromHistory,
      ),
    );
  }

  Future<void> _confirmAndDeleteFile(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
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

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MediaThumbnail(
                    artworkPath: item.artworkPath,
                    mediaType: item.mediaType,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.artist ?? (item.isVideo ? 'Video File' : 'Audio Track'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.share_rounded,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text(
              'Share File',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Send media file to other apps'),
            onTap: () => _shareFile(context),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.playlist_add_rounded,
                color: colorScheme.primary,
              ),
            ),
            title: const Text(
              'Add to Playlist',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              AddToPlaylistDialog.show(context, item);
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isFavorite
                  ? Colors.redAccent.withValues(alpha: 0.2)
                  : colorScheme.surfaceContainerHighest,
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.redAccent : colorScheme.primary,
              ),
            ),
            title: Text(
              isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              ref.read(favoritesControllerProvider).toggleFavorite(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite
                        ? 'Removed "${item.title}" from favorites'
                        : 'Added "${item.title}" to favorites',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.errorContainer,
              child: Icon(
                Icons.delete_forever_rounded,
                color: colorScheme.onErrorContainer,
              ),
            ),
            title: Text(
              'Delete File from Device',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            onTap: () => _confirmAndDeleteFile(context, ref),
          ),
          if (onRemoveFromHistory != null)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.errorContainer,
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              title: Text(
                'Remove from History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onRemoveFromHistory!();
              },
            ),
        ],
      ),
    );
  }
}
