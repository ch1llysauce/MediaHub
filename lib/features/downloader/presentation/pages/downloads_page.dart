import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/providers/providers.dart';
import '../../../../core/services/downloader/media_source_provider.dart';
import '../../../../domain/entities/download_task_entity.dart';
import '../../../player/presentation/controllers/music_player_controller.dart';
import '../controllers/downloads_controller.dart';
import '../widgets/download_url_dialog.dart';

enum DownloadSortOption {
  newest,
  oldest,
  titleAz,
  titleZa,
  sizeDesc,
}

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  DownloadSortOption _selectedSort = DownloadSortOption.newest;

  String _getDisplayTitle(DownloadTaskEntity task) {
    if (task.title != null && task.title!.trim().isNotEmpty) {
      return task.title!.trim();
    }
    final filename = p.basename(task.destinationPath);
    if (!filename.startsWith('pending_') && filename.isNotEmpty) {
      final dotIdx = filename.lastIndexOf('.');
      final clean = dotIdx > 0 ? filename.substring(0, dotIdx) : filename;
      if (clean.trim().isNotEmpty) return clean.replaceAll('_', ' ').trim();
    }
    return task.url;
  }

  List<DownloadTaskEntity> _sortTasks(List<DownloadTaskEntity> tasks) {
    final list = List<DownloadTaskEntity>.from(tasks);
    switch (_selectedSort) {
      case DownloadSortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case DownloadSortOption.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case DownloadSortOption.titleAz:
        list.sort((a, b) => _getDisplayTitle(a).toLowerCase().compareTo(_getDisplayTitle(b).toLowerCase()));
        break;
      case DownloadSortOption.titleZa:
        list.sort((a, b) => _getDisplayTitle(b).toLowerCase().compareTo(_getDisplayTitle(a).toLowerCase()));
        break;
      case DownloadSortOption.sizeDesc:
        list.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
        break;
    }
    return list;
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Clear History?'),
          ],
        ),
        content: const Text(
          'This will clear completed and cancelled download records from this list.\n\n'
          'Your downloaded video and audio files on your device will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(downloadsControllerProvider.notifier).clearCompleted();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download history cleared! (Media files preserved)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadsAsync = ref.watch(allDownloadsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Manager'),
        actions: [
          // Sort Menu Button
          PopupMenuButton<DownloadSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Downloads',
            onSelected: (option) => setState(() => _selectedSort = option),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: DownloadSortOption.newest,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Newest First'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: DownloadSortOption.oldest,
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Oldest First'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: DownloadSortOption.titleAz,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Title (A-Z)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: DownloadSortOption.titleZa,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Title (Z-A)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: DownloadSortOption.sizeDesc,
                child: Row(
                  children: [
                    Icon(Icons.data_usage_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('File Size (Largest)'),
                  ],
                ),
              ),
            ],
          ),

          // Clear Completed (Broom Icon)
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: 'Clear History',
            onPressed: () => _confirmClearHistory(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => DownloadUrlDialog.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Download'),
      ),
      body: downloadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading downloads: $err'),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return _buildEmptyState(context);
          }

          final activeTasks = _sortTasks(tasks.where((t) => t.isActive).toList());
          final completedTasks = _sortTasks(tasks.where((t) => t.isCompleted).toList());
          final otherTasks = _sortTasks(tasks.where((t) => !t.isActive && !t.isCompleted).toList());

          return CustomScrollView(
            slivers: [
              if (activeTasks.isNotEmpty) ...[
                _buildSectionHeader(context, 'Active Downloads (${activeTasks.length})'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _DownloadTaskTile(task: activeTasks[index]),
                    childCount: activeTasks.length,
                  ),
                ),
              ],
              if (completedTasks.isNotEmpty) ...[
                _buildSectionHeader(context, 'Completed (${completedTasks.length})'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _DownloadTaskTile(task: completedTasks[index]),
                    childCount: completedTasks.length,
                  ),
                ),
              ],
              if (otherTasks.isNotEmpty) ...[
                _buildSectionHeader(context, 'Other (${otherTasks.length})'),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _DownloadTaskTile(task: otherTasks[index]),
                    childCount: otherTasks.length,
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_download_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Downloads Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste a YouTube link, social media post, or direct MP3/MP4 URL to start downloading offline media.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => DownloadUrlDialog.show(context),
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Paste Media Link'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTaskTile extends ConsumerWidget {
  final DownloadTaskEntity task;

  const _DownloadTaskTile({required this.task});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _getDisplayTitle(DownloadTaskEntity task) {
    if (task.title != null && task.title!.trim().isNotEmpty) {
      return task.title!.trim();
    }
    final filename = p.basename(task.destinationPath);
    if (!filename.startsWith('pending_') && filename.isNotEmpty) {
      final dotIdx = filename.lastIndexOf('.');
      final clean = dotIdx > 0 ? filename.substring(0, dotIdx) : filename;
      if (clean.trim().isNotEmpty) {
        return clean.replaceAll('_', ' ').trim();
      }
    }
    try {
      final uri = Uri.parse(task.url);
      final host = uri.host.replaceFirst('www.', '');
      if (uri.path.length > 1) {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          return '$host/${segments.last}';
        }
      }
      return host.isNotEmpty ? host : task.url;
    } catch (_) {
      return task.url;
    }
  }

  String _getDisplaySubtitle(DownloadTaskEntity task) {
    if (task.status == DownloadStatus.downloading) {
      final pct = (task.progress * 100).toStringAsFixed(1);
      if (task.totalBytes > 0) {
        return '$pct% • ${_formatBytes(task.bytesDownloaded)} / ${_formatBytes(task.totalBytes)}';
      }
      return '$pct% • ${_formatBytes(task.bytesDownloaded)}';
    }
    if (task.status == DownloadStatus.resolving) {
      return 'Resolving media stream...';
    }
    if (task.status == DownloadStatus.completed) {
      final ext = task.destinationPath.contains('.')
          ? task.destinationPath.substring(task.destinationPath.lastIndexOf('.')).toUpperCase()
          : (task.mediaType == 'audio' ? '.MP3' : '.MP4');
      final size = task.totalBytes > 0 ? ' • ${_formatBytes(task.totalBytes)}' : '';
      return 'Completed $ext$size';
    }
    if (task.status == DownloadStatus.failed) {
      return task.errorMessage ?? 'Failed • Tap for details';
    }
    return task.status.name.toUpperCase();
  }

  void _showTaskDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DownloadDetailsModal(task: task),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(downloadsControllerProvider.notifier);

    IconData statusIcon;
    Color statusColor;

    switch (task.status) {
      case DownloadStatus.completed:
        statusIcon = Icons.check_circle_rounded;
        statusColor = Colors.green;
        break;
      case DownloadStatus.failed:
        statusIcon = Icons.error_rounded;
        statusColor = theme.colorScheme.error;
        break;
      case DownloadStatus.cancelled:
        statusIcon = Icons.cancel_rounded;
        statusColor = Colors.orange;
        break;
      default:
        statusIcon = Icons.downloading_rounded;
        statusColor = theme.colorScheme.primary;
    }

    final titleText = _getDisplayTitle(task);
    final subtitleText = _getDisplaySubtitle(task);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () => _showTaskDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: task.isFailed
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (task.isActive)
                    IconButton(
                      icon: const Icon(Icons.stop_circle_outlined),
                      color: Colors.red,
                      tooltip: 'Cancel Download',
                      onPressed: () => controller.cancelDownload(task.id),
                    ),
                  if (!task.isActive)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Delete Task',
                      onPressed: () => controller.deleteTask(task.id),
                    ),
                ],
              ),
              if (task.isActive) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: task.status == DownloadStatus.resolving ? null : task.progress,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadDetailsModal extends ConsumerWidget {
  final DownloadTaskEntity task;

  const _DownloadDetailsModal({required this.task});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(2)} ${suffixes[i]}';
  }

  String _getDisplayTitle(DownloadTaskEntity task) {
    if (task.title != null && task.title!.trim().isNotEmpty) {
      return task.title!.trim();
    }
    final filename = p.basename(task.destinationPath);
    if (!filename.startsWith('pending_') && filename.isNotEmpty) {
      final dotIdx = filename.lastIndexOf('.');
      final clean = dotIdx > 0 ? filename.substring(0, dotIdx) : filename;
      if (clean.trim().isNotEmpty) return clean.replaceAll('_', ' ').trim();
    }
    return task.url;
  }

  bool get _isInstagramTask {
    final host = Uri.tryParse(task.url)?.host.toLowerCase() ?? '';
    return host.contains('instagram.com') || host.contains('instagr.am');
  }

  void _showInstagramDebugLog(BuildContext context) {
    final trace = InstagramResolutionDebugLog.formatted;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Instagram Debug Log'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(trace),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: trace));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Instagram debug log copied.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = _getDisplayTitle(task);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? Colors.green.withValues(alpha: 0.15)
                          : (task.isFailed
                              ? colorScheme.errorContainer
                              : colorScheme.primaryContainer),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      task.isCompleted
                          ? Icons.check_circle_rounded
                          : (task.isFailed ? Icons.error_rounded : Icons.downloading_rounded),
                      color: task.isCompleted
                          ? Colors.green
                          : (task.isFailed ? colorScheme.error : colorScheme.primary),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: task.isCompleted
                                ? Colors.green.withValues(alpha: 0.2)
                                : (task.isFailed
                                    ? colorScheme.errorContainer
                                    : colorScheme.secondaryContainer),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.status.name.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: task.isCompleted
                                  ? Colors.green
                                  : (task.isFailed
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onSecondaryContainer),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Details List
              _buildDetailItem(
                context,
                icon: Icons.link_rounded,
                label: 'Source Link',
                value: task.url,
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy Link',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: task.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              _buildDetailItem(
                context,
                icon: Icons.folder_open_rounded,
                label: 'Saved Destination',
                value: task.destinationPath,
              ),
              const SizedBox(height: 16),

              _buildDetailItem(
                context,
                icon: Icons.data_usage_rounded,
                label: 'File Size',
                value: _formatBytes(task.totalBytes),
              ),
              const SizedBox(height: 16),

              _buildDetailItem(
                context,
                icon: Icons.calendar_today_rounded,
                label: 'Added On',
                value: task.createdAt.toLocal().toString().split('.').first,
              ),

              if (task.errorMessage != null && task.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (task.isFailed && _isInstagramTask) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showInstagramDebugLog(context),
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text('View Instagram Debug Log'),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        ref
                            .read(downloadsControllerProvider.notifier)
                            .deleteTask(task.id);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                    ),
                  ),
                  if (task.isCompleted) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          // Find item in media repository to play
                          final repository = ref.read(mediaRepositoryProvider);
                          final allMedia = await repository.getAllMedia();
                          final mediaItem = allMedia.firstWhere(
                            (m) => m.path == task.destinationPath,
                            orElse: () => allMedia.isNotEmpty ? allMedia.first : throw Exception('File not in library'),
                          );
                          ref
                              .read(musicPlayerControllerProvider.notifier)
                              .playItem(mediaItem);
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play Media'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
