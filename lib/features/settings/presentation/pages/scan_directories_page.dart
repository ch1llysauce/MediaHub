import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/providers/providers.dart';
import '../../../../domain/entities/scan_directory_entity.dart';

class ScanDirectoriesPage extends ConsumerWidget {
  const ScanDirectoriesPage({super.key});

  Future<void> _addDirectory(BuildContext context, WidgetRef ref) async {
    final scannerService = ref.read(mediaScannerServiceProvider);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => _AddScanDirectoryDialog(
        directories: scannerService.getDefaultScanDirectories(),
      ),
    );

    if (result == null || result.isEmpty) return;
    final existing = await ref.read(scanDirectoriesStreamProvider.future);
    if (existing.any((directory) => directory.path.toLowerCase() == result.toLowerCase())) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That directory is already being scanned.')),
        );
      }
      return;
    }

    await ref.read(mediaRepositoryProvider).addScanDirectory(result);
  }

  Future<void> _removeDirectory(
    BuildContext context,
    WidgetRef ref,
    ScanDirectoryEntity directory,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Directory?'),
        content: Text('Stop scanning "${directory.path}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(mediaRepositoryProvider).removeScanDirectory(directory.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directories = ref.watch(scanDirectoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Directories')),
      body: directories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Unable to load scan directories: $error'),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No custom scan directories configured.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final directory = items[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.folder_rounded),
                      title: Text(directory.path),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: 'Remove directory',
                        onPressed: () => _removeDirectory(context, ref, directory),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDirectory(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add directory'),
      ),
    );
  }
}

class _AddScanDirectoryDialog extends StatefulWidget {
  final List<String> directories;

  const _AddScanDirectoryDialog({required this.directories});

  @override
  State<_AddScanDirectoryDialog> createState() => _AddScanDirectoryDialogState();
}

class _AddScanDirectoryDialogState extends State<_AddScanDirectoryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, String path) {
    final trimmedPath = path.trim();
    if (trimmedPath.isNotEmpty) Navigator.pop(context, trimmedPath);
  }

  Future<void> _chooseDefaultFolder(BuildContext context) async {
    final directory = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
              title: Text('Choose a default folder'),
              subtitle: Text('Select a folder to scan for media'),
            ),
            for (final directory in widget.directories)
              ListTile(
                leading: const Icon(Icons.folder_rounded),
                title: Text(
                  directory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(sheetContext, directory),
              ),
          ],
        ),
      ),
    );

    if (directory != null && mounted) {
      _controller.text = directory;
      _controller.selection = TextSelection.collapsed(offset: directory.length);
    }
  }

  Future<void> _pickFolder(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose a folder to scan',
    );

    if (path != null && mounted) {
      _controller.text = path;
      _controller.selection = TextSelection.collapsed(offset: path.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Scan Directory'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a folder path that MediaHub should scan for media.'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '/storage/emulated/0/Music',
                prefixIcon: Icon(Icons.folder_outlined),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => _submit(context, value),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _pickFolder(context),
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Browse folders'),
              ),
            ),
            if (widget.directories.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _chooseDefaultFolder(context),
                  icon: const Icon(Icons.folder_copy_outlined),
                  label: const Text('Choose default folder'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(context, _controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}