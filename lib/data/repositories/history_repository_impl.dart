import '../../domain/entities/history_item_entity.dart';
import '../../domain/entities/media_item_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../database/app_database.dart';
import '../database/daos/history_dao.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryDao historyDao;

  HistoryRepositoryImpl({required this.historyDao});

  MediaItemEntity _rowToEntity(MediaItemRow row) {
    return MediaItemEntity(
      id: row.id,
      path: row.path,
      title: row.title,
      artist: row.artist,
      album: row.album,
      genre: row.genre,
      duration: row.duration,
      mediaType: row.mediaType,
      artworkPath: row.artworkPath,
      fileSize: row.fileSize,
      dateAdded: row.dateAdded,
      lastPlayed: row.lastPlayed,
      isAvailable: row.isAvailable,
    );
  }

  @override
  Stream<List<HistoryItemEntity>> watchHistoryMediaItems() {
    return historyDao.watchHistoryMediaItems().map((rows) {
      return rows.map((row) {
        return HistoryItemEntity(
          mediaItem: _rowToEntity(row.mediaItem),
          lastPlayed: row.lastPlayed,
          playbackPosition: row.playbackPosition,
        );
      }).toList();
    });
  }

  @override
  Future<int> getPlaybackPosition(String mediaId) {
    return historyDao.getPlaybackPosition(mediaId);
  }

  @override
  Future<void> recordPlayback(String mediaId, {int? playbackPosition, DateTime? customTimestamp}) {
    return historyDao.recordPlayback(mediaId, playbackPosition: playbackPosition, customTimestamp: customTimestamp);
  }

  @override
  Future<void> removeHistoryItem(String mediaId) {
    return historyDao.removeHistoryItem(mediaId);
  }

  @override
  Future<void> clearHistory() {
    return historyDao.clearHistory();
  }
}
