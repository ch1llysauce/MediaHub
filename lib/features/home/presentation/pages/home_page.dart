import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/history_item_entity.dart';
import '../../../../domain/entities/media_item_entity.dart';
import '../../../history/presentation/controllers/history_controller.dart';
import '../../../player/presentation/controllers/music_player_controller.dart';
import '../../../../shared/media_thumbnail.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _openMedia(BuildContext context, WidgetRef ref, MediaItemEntity item) {
    if (item.isVideo) {
      context.pushNamed('videoPlayer', extra: item);
    } else {
      ref.read(musicPlayerControllerProvider.notifier).playItem(item);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyMediaItemsStreamProvider);
    final mediaAsync = ref.watch(allMediaStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaHub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.pushNamed('search'),
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed('settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'Welcome to MediaHub',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Local-First Multimedia Hub',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Quick access'),
          const SizedBox(height: 8),
          _QuickActions(colorScheme: colorScheme),
          const SizedBox(height: 28),
          _SectionTitle(
            title: 'Recently played',
            action: TextButton(
              onPressed: () => context.pushNamed('history'),
              child: const Text('See all'),
            ),
          ),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const _LoadingSection(),
            error: (error, stackTrace) => const _EmptySection(
              icon: Icons.history_rounded,
              message: 'Unable to load playback history.',
            ),
            data: (items) => items.isEmpty
                ? const _EmptySection(
                    icon: Icons.history_rounded,
                    message: 'Play a song or video to see it here.',
                  )
                : SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length > 8 ? 8 : items.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final entry = items[index];
                        return _RecentCard(
                          item: entry.mediaItem,
                          subtitle: _relativeTime(entry.lastPlayed),
                          onTap: () => _openMedia(context, ref, entry.mediaItem),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle(title: 'Continue watching'),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const _LoadingSection(),
            error: (error, stackTrace) => const _EmptySection(
              icon: Icons.movie_outlined,
              message: 'Unable to load videos.',
            ),
            data: (items) {
              final videos = items
                  .where((entry) => entry.mediaItem.isVideo && entry.playbackPosition > 0)
                  .take(5)
                  .toList();
              return videos.isEmpty
                  ? const _EmptySection(
                      icon: Icons.play_circle_outline_rounded,
                      message: 'Videos you have started will appear here.',
                    )
                  : Column(
                      children: [
                        for (final entry in videos)
                          _ContinueTile(
                            entry: entry,
                            onTap: () => _openMedia(context, ref, entry.mediaItem),
                          ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 28),
          _SectionTitle(
            title: 'Featured media',
            action: TextButton(
              onPressed: () => context.pushNamed('library'),
              child: const Text('Open library'),
            ),
          ),
          const SizedBox(height: 8),
          mediaAsync.when(
            loading: () => const _LoadingSection(),
            error: (error, stackTrace) => const _EmptySection(
              icon: Icons.perm_media_outlined,
              message: 'Unable to load your library.',
            ),
            data: (items) {
              final featured = [...items]
                ..sort((first, second) => second.dateAdded.compareTo(first.dateAdded));
              final visibleItems = featured.take(5).toList();
              return visibleItems.isEmpty
                  ? const _EmptySection(
                      icon: Icons.perm_media_outlined,
                      message: 'Scan your device to add media to the library.',
                    )
                  : Column(
                      children: [
                        for (final item in visibleItems)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: _MediaIcon(item: item),
                            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              item.artist ?? (item.isVideo ? 'Local video' : 'Unknown artist'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _openMedia(context, ref, item),
                          ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

class _QuickActions extends StatelessWidget {
  final ColorScheme colorScheme;

  const _QuickActions({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    const actions = [
      ('Favorites', Icons.favorite_border_rounded, 'favorites'),
      ('Downloads', Icons.download_outlined, 'downloads'),
      ('Playlists', Icons.playlist_play_rounded, 'playlists'),
    ];

    return Row(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.pushNamed(actions[index].$3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Icon(actions[index].$2, color: colorScheme.primary),
                      const SizedBox(height: 6),
                      Text(actions[index].$1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  final MediaItemEntity item;
  final String subtitle;
  final VoidCallback onTap;

  const _RecentCard({required this.item, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MediaIcon(item: item, size: 44),
                const SizedBox(height: 8),
                Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueTile extends StatelessWidget {
  final HistoryItemEntity entry;
  final VoidCallback onTap;

  const _ContinueTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final duration = entry.mediaItem.duration ?? 0;
    final progress = duration > 0
        ? (entry.playbackPosition / duration).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _MediaIcon(item: entry.mediaItem),
        title: Text(entry.mediaItem.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: LinearProgressIndicator(value: progress),
        trailing: const Icon(Icons.play_arrow_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _MediaIcon extends StatelessWidget {
  final MediaItemEntity item;
  final double size;

  const _MediaIcon({required this.item, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return MediaThumbnail(
      artworkPath: item.artworkPath,
      mediaType: item.mediaType,
      size: size,
      borderRadius: 8,
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Center(child: Text('Loading...')),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
