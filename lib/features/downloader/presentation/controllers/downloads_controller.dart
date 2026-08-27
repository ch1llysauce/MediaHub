import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/services/downloader/media_source_provider.dart';

class DownloadsControllerState {
  final bool isResolving;
  final String? error;

  const DownloadsControllerState({
    this.isResolving = false,
    this.error,
  });

  DownloadsControllerState copyWith({
    bool? isResolving,
    String? error,
  }) {
    return DownloadsControllerState(
      isResolving: isResolving ?? this.isResolving,
      error: error,
    );
  }
}

class DownloadsController extends StateNotifier<DownloadsControllerState> {
  final Ref _ref;

  DownloadsController(this._ref) : super(const DownloadsControllerState());

  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

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

      return isGranted;
    }

    return true;
  }

  Future<MediaSourceInfo?> resolveMediaInfo(String url, {bool audioOnly = false}) async {
    state = state.copyWith(isResolving: true, error: null);
    try {
      final manager = _ref.read(downloadManagerProvider);
      final info = await manager.resolveSourceInfo(url, audioOnly: audioOnly);
      state = state.copyWith(isResolving: false);
      return info;
    } catch (e) {
      state = state.copyWith(isResolving: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> startDownload(
    String url, {
    bool audioOnly = false,
    String? customTitle,
    String? customStreamUrl,
    String? customExtension,
  }) async {
    if (url.trim().isEmpty) return;
    state = state.copyWith(isResolving: true, error: null);
    try {
      final manager = _ref.read(downloadManagerProvider);
      await manager.startDownload(
        url,
        audioOnly: audioOnly,
        customTitle: customTitle,
        customStreamUrl: customStreamUrl,
        customExtension: customExtension,
      );
      state = state.copyWith(isResolving: false);
    } catch (e) {
      state = state.copyWith(isResolving: false, error: e.toString());
    }
  }

  Future<void> cancelDownload(String taskId) async {
    final manager = _ref.read(downloadManagerProvider);
    await manager.cancelDownload(taskId);
  }

  Future<void> pauseDownload(String taskId) async {
    final manager = _ref.read(downloadManagerProvider);
    await manager.pauseDownload(taskId);
  }

  Future<void> resumeDownload(String taskId) async {
    final manager = _ref.read(downloadManagerProvider);
    await manager.resumeDownload(taskId);
  }

  Future<void> retryDownload(String taskId) async {
    final manager = _ref.read(downloadManagerProvider);
    await manager.retryDownload(taskId);
  }

  Future<void> deleteTask(String taskId) async {
    final manager = _ref.read(downloadManagerProvider);
    await manager.deleteTask(taskId);
  }

  Future<void> clearCompleted() async {
    final repository = _ref.read(downloadRepositoryProvider);
    await repository.clearCompletedOrCancelled();
  }
}

final downloadsControllerProvider =
    StateNotifierProvider<DownloadsController, DownloadsControllerState>((ref) {
  return DownloadsController(ref);
});
