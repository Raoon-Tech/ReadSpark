/// Reading position of a document (§12). The primary identity for resuming
/// is `documentId + sectionId + paragraphId + characterOffset`; the page is
/// auxiliary data only.
class ReadingProgress {
  const ReadingProgress({
    required this.id,
    required this.documentId,
    required this.characterOffset,
    required this.percentage,
    required this.lastReadAt,
    this.sectionId,
    this.paragraphId,
    this.pageNumber,
  });

  final String id;
  final String documentId;
  final String? sectionId;
  final String? paragraphId;
  final int characterOffset;
  final int? pageNumber;
  final double percentage;
  final DateTime lastReadAt;

  ReadingProgress copyWith({
    String? sectionId,
    String? paragraphId,
    int? characterOffset,
    int? pageNumber,
    double? percentage,
    DateTime? lastReadAt,
  }) {
    return ReadingProgress(
      id: id,
      documentId: documentId,
      sectionId: sectionId ?? this.sectionId,
      paragraphId: paragraphId ?? this.paragraphId,
      characterOffset: characterOffset ?? this.characterOffset,
      pageNumber: pageNumber ?? this.pageNumber,
      percentage: percentage ?? this.percentage,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }
}
