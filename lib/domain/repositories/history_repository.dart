import '../entities/history_item_entity.dart';

abstract class HistoryRepository {
  Stream<List<HistoryItemEntity>> watchHistoryMediaItems();
  Future<int> getPlaybackPosition(String mediaId);
  Future<void> recordPlayback(String mediaId, {int? playbackPosition, DateTime? customTimestamp});
  Future<void> removeHistoryItem(String mediaId);
  Future<void> clearHistory();
}
