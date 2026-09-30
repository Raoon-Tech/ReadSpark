import 'package:readspark/domain/documents/entities/document.dart';

/// Accumulates sections and paragraphs while a parser walks a file and
/// produces the final [DocumentContent] aggregate (ADR-001).
///
/// Ids are derived from the document id so they stay unique across the
/// whole database (`sec_<docId>_<n>`, `par_<docId>_<n>`).
class ParsedContentBuilder {
  ParsedContentBuilder(this.base);

  /// Metadata created by the use case (id, title, path, dates); parsers
  /// enrich it via [author], [totalPages] and [textExtractable].
  final Document base;

  String? author;
  int? totalPages;
  bool textExtractable = true;

  final List<DocumentSection> _sections = [];
  final List<DocumentParagraph> _paragraphs = [];
  DocumentSection? _current;
  int _paragraphsInSection = 0;
  int _paragraphCounter = 0;

  int get sectionCount => _sections.length;

  int get paragraphCount => _paragraphs.length;

  /// Opens a new section; subsequent paragraphs belong to it. Level `0` is
  /// the root, `1..6` map to heading depth.
  void startSection({required String title, required int level}) {
    final section = DocumentSection(
      id: 'sec_${base.id}_${_sections.length}',
      documentId: base.id,
      title: title.trim(),
      order: _sections.length,
      level: level.clamp(0, 6),
    );
    _sections.add(section);
    _current = section;
    _paragraphsInSection = 0;
  }

  /// Appends a paragraph to the current section (a root section is created
  /// on demand). Whitespace-only texts are ignored.
  void addParagraph(String text, {int? pageNumber}) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    if (_current == null) startSection(title: '', level: 0);
    _paragraphs.add(
      DocumentParagraph(
        id: 'par_${base.id}_${_paragraphCounter++}',
        documentId: base.id,
        sectionId: _current!.id,
        order: _paragraphsInSection++,
        text: cleaned,
        pageNumber: pageNumber,
      ),
    );
  }

  /// Builds the aggregate, merging parser metadata and the total character
  /// count used as percentage base (§12).
  DocumentContent build() {
    if (_sections.isEmpty) startSection(title: '', level: 0);
    final totalCharacters = _paragraphs.fold<int>(
      0,
      (sum, paragraph) => sum + paragraph.text.length,
    );
    return DocumentContent(
      document: base.copyWith(
        author: author,
        totalPages: totalPages,
        totalCharacters: totalCharacters,
        textExtractable: textExtractable,
      ),
      sections: List.unmodifiable(_sections),
      paragraphs: List.unmodifiable(_paragraphs),
    );
  }
}
