import 'media_item_entity.dart';

class HistoryItemEntity {
  final MediaItemEntity mediaItem;
  final DateTime lastPlayed;
  final int playbackPosition; // in seconds

  HistoryItemEntity({
    required this.mediaItem,
    required this.lastPlayed,
    required this.playbackPosition,
  });
}
