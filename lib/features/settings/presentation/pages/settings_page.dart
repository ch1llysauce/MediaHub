import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/theme/app_color_scheme.dart';
import '../../../../core/providers/providers.dart';
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
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: SingleChildScrollView(
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
                          dense: true,
                          title: Text(_themeLabel(mode)),
                          value: mode,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await settingsController.setThemeMode(selected);
    }
  }

  Future<void> _showColorSchemeSelector(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final current = ref.read(settingsControllerProvider).appColorScheme;

    final selected = await showModalBottomSheet<AppColorScheme>(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    'Accent Color Scheme',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                RadioGroup<AppColorScheme>(
                  groupValue: current,
                  onChanged: (value) => Navigator.pop(sheetContext, value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final scheme in AppColorScheme.values)
                        RadioListTile<AppColorScheme>(
                          value: scheme,
                          dense: true,
                          title: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isDark ? scheme.darkPrimary : scheme.lightPrimary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark ? scheme.darkPrimary : scheme.lightPrimary)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(scheme.displayName),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await settingsController.setColorScheme(selected);
    }
  }

  Future<void> _pickFolder(
  BuildContext context,
  TextEditingController controller,
) async {
  final path = await FilePicker.platform.getDirectoryPath(
    dialogTitle: 'Choose a folder to save downloads.',
  );

  if (!context.mounted || path == null) return;

  controller
    ..text = path
    ..selection = TextSelection.collapsed(
      offset: path.length,
    );
}

  Future<void> _showDownloadDirectoryEditor(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final currentPath =
        ref.read(settingsControllerProvider).downloadDirectory ?? '';

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
              onSubmitted: (value) =>
                  Navigator.pop(dialogContext, value.trim()),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _pickFolder(context, textController),
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Browse folders'),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(dialogContext, '__reset__'),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset to Default'),
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
      appBar: AppBar(title: const Text('Settings')),
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

          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('Color Scheme'),
              subtitle: Text(settings.appColorScheme.displayName),
              trailing: _SettingsChevron(colorScheme: colorScheme),
              onTap: () => _showColorSchemeSelector(context, ref),
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
              onTap: () => context.pushNamed('scanDirectories'),
            ),
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
          // About & Legal
          // ─────────────────────────────────────────────
          Text(
            'About & Legal',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: _SettingsIcon(
                icon: Icons.info_outline_rounded,
                colorScheme: colorScheme,
              ),
              title: const Text('About MediaHub'),
              subtitle: const Text('Version 1.0.0 (Local-First Build)'),
              trailing: _SettingsChevron(colorScheme: colorScheme),
              onTap: () => _showAboutAppDialog(context),
            ),
          ),

          Card(
            child: ListTile(
              leading: _SettingsIcon(
                icon: Icons.description_outlined,
                colorScheme: colorScheme,
              ),
              title: const Text('Terms & Conditions'),
              subtitle: const Text('User agreement & usage guidelines'),
              trailing: _SettingsChevron(colorScheme: colorScheme),
              onTap: () => _showTermsAndConditions(context),
            ),
          ),

          Card(
            child: ListTile(
              leading: _SettingsIcon(
                icon: Icons.shield_outlined,
                colorScheme: colorScheme,
              ),
              title: const Text('Privacy Policy'),
              subtitle: const Text('100% Offline & Local Data Privacy'),
              trailing: _SettingsChevron(colorScheme: colorScheme),
              onTap: () => _showPrivacyPolicy(context),
            ),
          ),

          Card(
            child: ListTile(
              leading: _SettingsIcon(
                icon: Icons.article_outlined,
                colorScheme: colorScheme,
              ),
              title: const Text('Open Source Licenses'),
              subtitle: const Text('Third-party software & libraries'),
              trailing: _SettingsChevron(colorScheme: colorScheme),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'MediaHub',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 MediaHub Team. All rights reserved.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.headset_rounded, color: Theme.of(dialogContext).colorScheme.primary),
            const SizedBox(width: 10),
            const Text('MediaHub'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version 1.0.0 (MVP Build)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'MediaHub is a centralized local-first multimedia application designed to discover, organize, manage, and play your personal music and video files.',
              ),
              SizedBox(height: 12),
              Text(
                'Core Capabilities:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Local Music & Video Library Discovery'),
              Text('• Hardware-Accelerated Video Player & PiP'),
              Text('• Background Audio Player & Queue Management'),
              Text('• Custom Playlists, Favorites & Playback History'),
              Text('• Modular Media Download Manager'),
              SizedBox(height: 12),
              Text(
                'Built with Flutter for high-performance offline media experiences.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terms & Conditions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: const [
                      Text(
                        'Last Updated: August 2026',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      SizedBox(height: 12),
                      _LegalSection(
                        title: '1. Acceptance of Terms',
                        body: 'By downloading, installing, or using MediaHub, you agree to comply with and be bound by these Terms and Conditions. If you do not agree, please do not use the application.',
                      ),
                      _LegalSection(
                        title: '2. Personal & Non-Commercial Use',
                        body: 'MediaHub is provided strictly for personal, non-commercial media organization and playback. You are responsible for ensuring that all media files managed or downloaded via MediaHub comply with applicable copyright laws.',
                      ),
                      _LegalSection(
                        title: '3. Download & Third-Party Content',
                        body: 'MediaHub provides provider abstractions for downloading media. MediaHub does not host, store, or own any third-party online media content. Users must respect intellectual property rights and only download content they have lawful rights or permission to access.',
                      ),
                      _LegalSection(
                        title: '4. Local-First & Offline Operation',
                        body: 'MediaHub operates locally on your device. Storage of media files, playlists, favorites, and history occurs exclusively on local device storage. MediaHub is not liable for data loss caused by device formatting or manual deletion.',
                      ),
                      _LegalSection(
                        title: '5. Limitation of Liability',
                        body: 'MediaHub is provided "AS IS" without warranties of any kind. The developers shall not be liable for any indirect, incidental, or consequential damages resulting from the use or inability to use the application.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: const [
                      Text(
                        'Last Updated: August 2026',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      SizedBox(height: 12),
                      _LegalSection(
                        title: '100% Local Privacy Commitment',
                        body: 'MediaHub is engineered as a local-first application. Your privacy is paramount: WE DO NOT COLLECT, STORE, OR TRANSMIT ANY PERSONAL DATA, MEDIA FILES, OR PLAYBACK HISTORY TO EXTERNAL SERVERS.',
                      ),
                      _LegalSection(
                        title: 'Device Permissions & Storage Access',
                        body: 'MediaHub requests Storage and Media Access permissions solely to scan, index, and play local audio/video files on your device, and to save downloads to your specified folder. No files leave your device.',
                      ),
                      _LegalSection(
                        title: 'SQLite Local Database',
                        body: 'All application metadata (Playlists, Favorites, Playback History, and App Settings) is stored in a local SQLite database (via Drift) on your device. This data is private to your installation.',
                      ),
                      _LegalSection(
                        title: 'Network Activity',
                        body: 'Network access is used exclusively when you explicitly initiate a download or resolve an online media link. No background telemetry, analytics, or user tracking scripts exist within MediaHub.',
                      ),
                      _LegalSection(
                        title: 'Contact & Data Control',
                        body: 'Since all data resides on your device, clearing app data or uninstalling MediaHub completely removes all internal application databases.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String body;

  const _LegalSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(fontSize: 13, height: 1.4),
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

  const _SettingsIcon({required this.icon, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Icon(icon, color: colorScheme.primary, size: 24),
    );
  }
}

/// Trailing chevron colored like the folder chevrons on the Library page.
class _SettingsChevron extends StatelessWidget {
  final ColorScheme colorScheme;

  const _SettingsChevron({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      color: colorScheme.onSurfaceVariant,
    );
  }
}
