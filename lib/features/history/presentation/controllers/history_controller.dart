import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../data/database/daos/history_dao.dart';
import '../../../../data/repositories/history_repository_impl.dart';
import '../../../../domain/entities/history_item_entity.dart';
import '../../../../domain/repositories/history_repository.dart';

/// HistoryDao provider
final historyDaoProvider = Provider<HistoryDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.historyDao;
});

/// HistoryRepository provider
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final dao = ref.watch(historyDaoProvider);
  return HistoryRepositoryImpl(historyDao: dao);
});

/// Stream of history media items
final historyMediaItemsStreamProvider = StreamProvider<List<HistoryItemEntity>>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.watchHistoryMediaItems();
});

class HistoryController {
  final HistoryRepository _repository;

  HistoryController(this._repository);

  Future<void> recordPlayback(String mediaId, {int? playbackPosition}) async {
    await _repository.recordPlayback(mediaId, playbackPosition: playbackPosition);
  }

  Future<int> getPlaybackPosition(String mediaId) async {
    return await _repository.getPlaybackPosition(mediaId);
  }

  Future<void> removeHistoryItem(String mediaId) async {
    await _repository.removeHistoryItem(mediaId);
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
  }
}

final historyControllerProvider = Provider<HistoryController>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryController(repository);
});
