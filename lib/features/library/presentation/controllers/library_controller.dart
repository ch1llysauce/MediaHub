import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/providers.dart';
import '../../../../domain/repositories/media_repository.dart';

class LibraryState {
  final bool isScanning;
  final String? statusMessage;
  final String? errorMessage;
  final bool permissionGranted;

  const LibraryState({
    this.isScanning = false,
    this.statusMessage,
    this.errorMessage,
    this.permissionGranted = true,
  });

  LibraryState copyWith({
    bool? isScanning,
    String? statusMessage,
    String? errorMessage,
    bool? permissionGranted,
  }) {
    return LibraryState(
      isScanning: isScanning ?? this.isScanning,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  final MediaRepository _repository;
  final Ref _ref;

  LibraryController(this._repository, this._ref) : super(const LibraryState());

  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      state = state.copyWith(permissionGranted: true);
      return true;
    }

    if (Platform.isAndroid) {
      final statuses = await [
        Permission.storage,
        Permission.audio,
        Permission.videos,
      ].request();

      var isGranted = statuses.values.any((status) =>
          status.isGranted || status.isLimited || status.isRestricted);

      if (!isGranted) {
        final manageStatus = await Permission.manageExternalStorage.request();
        isGranted = manageStatus.isGranted;
      }

      if (!isGranted) {
        // Check if user permanently denied permissions
        final isPermanentlyDenied = statuses.values.any((s) => s.isPermanentlyDenied);
        if (isPermanentlyDenied) {
          await openAppSettings();
        }
      }

      state = state.copyWith(
        permissionGranted: isGranted,
        errorMessage: isGranted ? null : 'Storage permission is required to scan device media.',
      );

      return isGranted;
    }

    return true;
  }


  Future<void> scanIfEmpty() async {
    final media = await _repository.getAllMedia();
    if (media.isEmpty) {
      await scanDeviceMedia();
    }
  }

  Future<void> scanDeviceMedia() async {
    final granted = await requestStoragePermission();
    if (!granted) return;

    state = state.copyWith(
      isScanning: true,
      statusMessage: 'Scanning device storage for music and videos...',
      errorMessage: null,
    );

    try {
      final scannerService = _ref.read(mediaScannerServiceProvider);
      final defaultDirs = scannerService.getDefaultScanDirectories();

      // Fetch user configured scan directories if any
      final configuredDirs = await _repository.getScanDirectories();
      final configuredPaths = configuredDirs.map((d) => d.path).toList();

      final allScanPaths = {
        ...defaultDirs,
        ...configuredPaths,
      }.toList();

      final initialCount = (await _repository.getAllMedia()).length;
      await _repository.scanDirectories(allScanPaths);
      final finalCount = (await _repository.getAllMedia()).length;
      final newCount = finalCount - initialCount;

      final statusMsg = newCount > 0
          ? 'Scan complete! Added $newCount new media file${newCount > 1 ? 's' : ''}.'
          : 'Library is already up to date. No new media found.';

      state = state.copyWith(
        isScanning: false,
        statusMessage: statusMsg,
      );

    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Failed to scan media: ${e.toString()}',
      );
    }
  }
}

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>((ref) {
  final repository = ref.watch(mediaRepositoryProvider);
  return LibraryController(repository, ref);
});
