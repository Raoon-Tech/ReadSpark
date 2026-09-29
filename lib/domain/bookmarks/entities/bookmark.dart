/// A saved reading position with an optional note (Phase 8 scope for notes;
/// persisted since schema v1).
class Bookmark {
  const Bookmark({
    required this.id,
    required this.documentId,
    required this.characterOffset,
    required this.createdAt,
    this.sectionId,
    this.paragraphId,
    this.pageNumber,
    this.note,
  });

  final String id;
  final String documentId;
  final String? sectionId;
  final String? paragraphId;
  final int characterOffset;
  final int? pageNumber;
  final String? note;
  final DateTime createdAt;
}
