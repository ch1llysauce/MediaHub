import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/downloads_controller.dart';
import 'download_quality_modal.dart';

class DownloadUrlDialog extends ConsumerStatefulWidget {
  const DownloadUrlDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DownloadUrlDialog(),
    );
  }

  @override
  ConsumerState<DownloadUrlDialog> createState() => _DownloadUrlDialogState();
}

class _DownloadUrlDialogState extends ConsumerState<DownloadUrlDialog> {
  final _urlController = TextEditingController();
  bool _audioOnly = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
    // Prompt storage permission when opening download dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(downloadsControllerProvider.notifier).requestStoragePermission();
    });
  }

  void _onUrlChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final controller = ref.read(downloadsControllerProvider.notifier);
    await controller.requestStoragePermission();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
        _errorText = null;
      });
    }
  }

  bool _isLoading = false;

  Future<void> _onStartDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorText = 'Please enter or paste a valid URL');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _errorText = 'URL must start with http:// or https://');
      return;
    }

    final controller = ref.read(downloadsControllerProvider.notifier);
    final granted = await controller.requestStoragePermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to save downloaded media files.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final info = await controller.resolveMediaInfo(url, audioOnly: _audioOnly);
      if (!mounted) return;

      Navigator.of(context).pop(); // Close initial dialog

      if (info != null) {
        DownloadQualityModal.show(
          context,
          originalUrl: url,
          mediaInfo: info,
          audioOnly: _audioOnly,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = 'Unable to fetch video details. Please check link and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.9,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 32.0 : 24.0,
          vertical: isLandscape ? 12.0 : 20.0,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Row(
                  children: [
                    Icon(Icons.download_rounded, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Download Media',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Paste a YouTube, Instagram, X, TikTok, FB, or direct media URL.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                
                if (_urlController.text.toLowerCase().contains('youtube.com') || 
                    _urlController.text.toLowerCase().contains('youtu.be')) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Note: YouTube downloads may occasionally stall or fail due to rate-limiting and server-side blocks. Retrying later may resolve the issue.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Input field with Paste button
                TextField(
                  enabled: !_isLoading,
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autofocus: true,
                  onChanged: (val) {
                    if (_errorText != null) {
                      setState(() {
                        _errorText = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    errorText: _errorText,
                    prefixIcon: const Icon(Icons.link_rounded),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: 'Clear input',
                          onPressed: _isLoading ? null : () {
                            setState(() {
                              _urlController.clear();
                              _errorText = null;
                            });
                          },
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.content_paste_rounded),
                          tooltip: 'Paste from Clipboard',
                          onPressed: _isLoading ? null : _pasteFromClipboard,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Format:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _isLoading ? null : () => setState(() => _audioOnly = false),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_audioOnly
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: !_audioOnly
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.2),
                              width: !_audioOnly ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.video_library_rounded,
                                size: 20,
                                color: !_audioOnly
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Video',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: !_audioOnly
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _isLoading ? null : () => setState(() => _audioOnly = true),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _audioOnly
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _audioOnly
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.2),
                              width: _audioOnly ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.audiotrack_rounded,
                                size: 20,
                                color: _audioOnly
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Audio',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _audioOnly
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Start Download CTA Button
                FilledButton.icon(
                  onPressed: _isLoading ? null : _onStartDownload,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(_isLoading ? 'Fetching Details & Qualities...' : 'Next • Choose Quality'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
