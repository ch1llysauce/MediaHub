import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/scan_directory_entity.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> _showThemeSelector(BuildContext context, WidgetRef ref) async {
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final current = ref.read(settingsControllerProvider).themeMode;

    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'App Theme',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              RadioGroup<ThemeMode>(
                groupValue: current,
                onChanged: (value) => Navigator.pop(sheetContext, value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final mode in ThemeMode.values)
                      RadioListTile<ThemeMode>(
                        title: Text(_themeLabel(mode)),
                        value: mode,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await settingsController.setThemeMode(selected);
    }
  }

  Future<void> _showAddScanDirectory(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final scannerService = ref.read(mediaScannerServiceProvider);
    final defaults = scannerService.getDefaultScanDirectories();
    final existingAsync = ref.read(scanDirectoriesStreamProvider.future);

    final textController = TextEditingController();
    FocusNode autofocusNode = FocusNode();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('Add Scan Directory'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter a folder path that MediaHub should scan for media.'),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                focusNode: autofocusNode,
                decoration: InputDecoration(
                  hintText: '/storage/emulated/0/Music',
                  prefixIcon: const Icon(Icons.folder_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
              ),
              const SizedBox(height: 16),
              Text(
                'Default folders',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 140,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final dir in defaults)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.folder_rounded, size: 20),
                        title: Text(
                          dir,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.add_rounded, size: 20),
                        onTap: () =>
                            Navigator.pop(dialogContext, dir),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final path = textController.text.trim();
                if (path.isNotEmpty) {
                  Navigator.pop(dialogContext, path);
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    // Guard against duplicates
    final existing = await existingAsync;
    final duplicate = existing.any(
      (d) => d.path.toLowerCase() == result.toLowerCase(),
    );

    if (duplicate) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That directory is already being scanned.')),
        );
      }
      return;
    }

    await ref.read(mediaRepositoryProvider).addScanDirectory(result);
  }

  Future<void> _removeScanDirectory(BuildContext context, WidgetRef ref, ScanDirectoryEntity dir) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Directory?'),
        content: Text(
          'Stop scanning "${dir.path}"?\n\nMedia already in your library will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(mediaRepositoryProvider).removeScanDirectory(dir.id);
    }
  }

  Future<void> _showDownloadDirectoryEditor(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final currentPath = ref.read(settingsControllerProvider).downloadDirectory ?? '';

    final textController = TextEditingController(text: currentPath);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Download Directory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Where downloaded media files are saved.'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '/storage/emulated/0/Download/MediaHub',
                prefixIcon: const Icon(Icons.download_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.pop(dialogContext, '__reset__'),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset to Default'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final path = textController.text.trim();
              if (path.isNotEmpty) {
                Navigator.pop(dialogContext, path);
              }
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    if (result == '__reset__') {
      await settingsController.resetDownloadDirectory();
    } else {
      await settingsController.setDownloadDirectory(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsControllerProvider);
    final scanDirsAsync = ref.watch(scanDirectoriesStreamProvider);
    final libraryState = ref.watch(libraryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─────────────────────────────────────────────
          // Appearance
          // ─────────────────────────────────────────────

          Text(
            'Appearance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: _SettingsIcon(
                icon: Icons.palette_outlined,
                colorScheme: colorScheme,
              ),
              title: const Text('Theme'),
              subtitle: Text(_themeLabel(settings.themeMode)),
              trailing: _SettingsChevron(colorScheme: colorScheme),
              onTap: () => _showThemeSelector(context, ref),
            ),
          ),

          const SizedBox(height: 24),

          // ─────────────────────────────────────────────
          // Media Directories
          // ─────────────────────────────────────────────

          Text(
            'Media Directories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: _SettingsIcon(
                icon: Icons.folder_outlined,
                colorScheme: colorScheme,
              ),
              title: const Text('Scan Directories'),
              subtitle: Text(
                scanDirsAsync.maybeWhen(
                  data: (dirs) => dirs.isEmpty
                      ? 'No custom folders — using default device folders'
                      : '${dirs.length} custom ${dirs.length == 1 ? 'folder' : 'folders'} configured',
                  orElse: () => 'Loading...',
                ),
              ),
              trailing: _SettingsChevron(colorScheme: colorScheme),
              onTap: () => _showAddScanDirectory(context, ref),
            ),
          ),

          // List of configured scan directories
          scanDirsAsync.when(
            data: (dirs) {
              if (dirs.isEmpty) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    for (final dir in dirs)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.folder_rounded,
                          color: colorScheme.primary,
                        ),
                        title: Text(
                          dir.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            color: colorScheme.error,
                          ),
                          tooltip: 'Remove directory',
                          onPressed: () => _removeScanDirectory(context, ref, dir),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          Card(
            child: ListTile(
              leading: _SettingsIcon(
                icon: Icons.download_outlined,
                colorScheme: colorScheme,
              ),
              title: const Text('Download Directory'),
              subtitle: Text(
                settings.downloadDirectory ?? 'Not configured',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _SettingsChevron(colorScheme: colorScheme),
              onTap: () => _showDownloadDirectoryEditor(context, ref),
            ),
          ),

          const SizedBox(height: 24),

          // ─────────────────────────────────────────────
          // Scanner
          // ─────────────────────────────────────────────

          Text(
            'Scanner',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: _SettingsIcon(
                icon: Icons.sync_outlined,
                colorScheme: colorScheme,
              ),
              title: Text(
                libraryState.isScanning ? 'Scanning...' : 'Rescan Media',
              ),
              subtitle: Text(
                libraryState.statusMessage ??
                    'Manually scan configured directories for new media',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: libraryState.isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : _SettingsChevron(colorScheme: colorScheme),
              onTap: libraryState.isScanning
                  ? null
                  : () => ref
                      .read(libraryControllerProvider.notifier)
                      .scanDeviceMedia(),
            ),
          ),

          const SizedBox(height: 24),

          // ─────────────────────────────────────────────
          // About
          // ─────────────────────────────────────────────

          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: _SettingsIcon(
                icon: Icons.info_outline,
                colorScheme: colorScheme,
              ),
              title: const Text('MediaHub'),
              subtitle: const Text('Version 1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Leading icon styled like the shortcut tiles on the Playlists page:
/// a subtle primary-tinted rounded container with a primary-colored icon.
class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final ColorScheme colorScheme;

  const _SettingsIcon({
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Icon(
        icon,
        color: colorScheme.primary,
        size: 24,
      ),
    );
  }
}

/// Trailing chevron colored like the folder chevrons on the Library page.
class _SettingsChevron extends StatelessWidget {
  final ColorScheme colorScheme;

  const _SettingsChevron({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      color: colorScheme.onSurfaceVariant,
    );
  }
}
