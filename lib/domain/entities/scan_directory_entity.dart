class ScanDirectoryEntity {
  final String id;
  final String path;
  final bool isDefault;
  final DateTime dateAdded;

  const ScanDirectoryEntity({
    required this.id,
    required this.path,
    this.isDefault = false,
    required this.dateAdded,
  });
}
