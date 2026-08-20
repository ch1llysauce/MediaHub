import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'history_dao.g.dart';

class HistoryItemWithMedia {
  final MediaItemRow mediaItem;
  final DateTime lastPlayed;
  final int playbackPosition;

  HistoryItemWithMedia({
    required this.mediaItem,
    required this.lastPlayed,
    required this.playbackPosition,
  });
}

@DriftAccessor(tables: [History, MediaItems])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.db);

  /// Watch recently played items joined with MediaItems, ordered by lastPlayed DESC
  Stream<List<HistoryItemWithMedia>> watchHistoryMediaItems() {
    final query = select(history).join([
      innerJoin(mediaItems, mediaItems.id.equalsExp(history.mediaId)),
    ])
      ..orderBy([OrderingTerm.desc(history.lastPlayed)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final item = row.readTable(mediaItems);
        final hist = row.readTable(history);
        return HistoryItemWithMedia(
          mediaItem: item,
          lastPlayed: hist.lastPlayed,
          playbackPosition: hist.playbackPosition,
        );
      }).toList();
    });
  }

  /// Get saved playback position for a media item in seconds
  Future<int> getPlaybackPosition(String mediaId) async {
    final row = await (select(history)..where((tbl) => tbl.mediaId.equals(mediaId))).getSingleOrNull();
    return row?.playbackPosition ?? 0;
  }

  /// Record playback activity (upserts timestamp and position)
  Future<void> recordPlayback(String mediaId, {int? playbackPosition, DateTime? customTimestamp}) async {
    final now = customTimestamp ?? DateTime.now();
    final existing = await (select(history)..where((tbl) => tbl.mediaId.equals(mediaId))).getSingleOrNull();

    if (existing != null) {
      await (update(history)..where((tbl) => tbl.mediaId.equals(mediaId))).write(
        HistoryCompanion(
          lastPlayed: Value(now),
          playbackPosition: playbackPosition != null ? Value(playbackPosition) : const Value.absent(),
        ),
      );
    } else {
      await into(history).insert(
        HistoryCompanion.insert(
          id: 'hist_$mediaId',
          mediaId: mediaId,
          lastPlayed: now,
          playbackPosition: Value(playbackPosition ?? 0),
        ),
      );
    }

    // Also update lastPlayed on MediaItems table
    await (update(mediaItems)..where((tbl) => tbl.id.equals(mediaId))).write(
      MediaItemsCompanion(lastPlayed: Value(now)),
    );
  }

  /// Remove a single media item from history
  Future<void> removeHistoryItem(String mediaId) {
    return (delete(history)..where((tbl) => tbl.mediaId.equals(mediaId))).go();
  }

  /// Clear all history records (does NOT delete physical media files)
  Future<void> clearHistory() {
    return delete(history).go();
  }
}
