import 'package:readspark/domain/documents/entities/document.dart';

/// One paragraph matching a reader search (RF-12).
class ReaderMatch {
  const ReaderMatch({required this.paragraphIndex, required this.sectionIndex});

  /// Index into the document's paragraph list (reading order).
  final int paragraphIndex;

  /// Index into the document's section list.
  final int sectionIndex;
}

/// Pure in-document search (RF-12): case-insensitive substring matches over
/// the paragraphs in reading order. Empty/blank queries return no matches.
List<ReaderMatch> findParagraphMatches({
  required List<DocumentSection> sections,
  required List<DocumentParagraph> paragraphs,
  required String query,
}) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];

  final sectionIndexById = <String, int>{
    for (var index = 0; index < sections.length; index++)
      sections[index].id: index,
  };
  final matches = <ReaderMatch>[];
  for (var index = 0; index < paragraphs.length; index++) {
    final paragraph = paragraphs[index];
    if (paragraph.text.toLowerCase().contains(needle)) {
      matches.add(
        ReaderMatch(
          paragraphIndex: index,
          sectionIndex: sectionIndexById[paragraph.sectionId] ?? 0,
        ),
      );
    }
  }
  return matches;
}
