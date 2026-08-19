class PlaylistEntity {
  final String id;
  final String name;
  final DateTime createdAt;
  final int itemCount;
  final String? artworkPath;

  const PlaylistEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.itemCount,
    this.artworkPath,
  });

  PlaylistEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? itemCount,
    String? artworkPath,
  }) {
    return PlaylistEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      itemCount: itemCount ?? this.itemCount,
      artworkPath: artworkPath ?? this.artworkPath,
    );
  }
}
