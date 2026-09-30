import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';

import '../parsed_content_builder.dart';

/// A chapter/section announced by the PDF outline (bookmarks).
class PdfOutlineEntry {
  const PdfOutlineEntry({
    required this.title,
    required this.pageIndex,
    required this.depth,
  });

  /// Outline label (may be empty; skipped when so).
  final String title;

  /// Zero-based destination page (clamped to the document).
  final int pageIndex;

  /// Nesting depth in the outline tree (`0` = top level).
  final int depth;
}

/// Minimum extracted characters for a page to count as "with text"
/// (C7 scanned-PDF detection).
const int pdfPageMinExtractableChars = 10;

/// Pure conversion of extracted PDF page texts + outline into the common
/// document model (§14). Kept free of pdfrx types so it is unit-testable.
///
/// - Sections come from the outline ("capítulo si se detecta"); PDFs
///   without outline fall back to a single root section and real page
///   numbers on paragraphs.
/// - C7: when most pages have no extractable text the document is
///   imported with empty content, `textExtractable = false` and an
///   [ImportWarning.scannedPdf] warning (no OCR in the MVP).
ImportedDocument buildPdfContent({
  required Document base,
  required List<String> pageTexts,
  required List<PdfOutlineEntry> outline,
}) {
  final builder = ParsedContentBuilder(base)..totalPages = pageTexts.length;

  if (!_hasExtractableText(pageTexts)) {
    builder.textExtractable = false;
    return ImportedDocument(
      content: builder.build(),
      warning: ImportWarning.scannedPdf,
    );
  }

  final entries = _sortedOutline(outline, pageTexts.length);
  var nextEntry = 0;

  for (var pageIndex = 0; pageIndex < pageTexts.length; pageIndex++) {
    while (nextEntry < entries.length &&
        entries[nextEntry].pageIndex <= pageIndex) {
      final entry = entries[nextEntry];
      if (entry.title.isNotEmpty) {
        builder.startSection(title: entry.title, level: entry.depth + 1);
      }
      nextEntry++;
    }
    for (final block in _splitParagraphs(pageTexts[pageIndex])) {
      builder.addParagraph(block, pageNumber: pageIndex + 1);
    }
  }

  return ImportedDocument(content: builder.build());
}

/// C7: majority of pages without text → scanned document.
bool _hasExtractableText(List<String> pageTexts) {
  if (pageTexts.isEmpty) return false;
  final extractablePages = pageTexts
      .where((text) => text.trim().length >= pdfPageMinExtractableChars)
      .length;
  return extractablePages * 2 >= pageTexts.length;
}

/// Clamps entries to the document, drops destinations out of range and
/// keeps the outline (document) order, sorting only by start page so
/// same-page siblings stay in outline order.
List<PdfOutlineEntry> _sortedOutline(
  List<PdfOutlineEntry> outline,
  int pageCount,
) {
  final usable = <int, PdfOutlineEntry>{};
  for (var index = 0; index < outline.length; index++) {
    final entry = outline[index];
    if (entry.pageIndex < 0 || entry.pageIndex >= pageCount) continue;
    usable[index] = entry;
  }
  final keys = usable.keys.toList()..sort((a, b) {
      final byPage = usable[a]!.pageIndex.compareTo(usable[b]!.pageIndex);
      return byPage != 0 ? byPage : a.compareTo(b);
    });
  return [for (final key in keys) usable[key]!];
}

/// Splits one page into paragraph blocks on blank lines and normalizes
/// PDF line wrapping: single newlines join with a space, soft hyphenation
/// (`word-\nnext`) is rejoined without the hyphen.
List<String> _splitParagraphs(String pageText) {
  final blocks = <String>[];
  for (final rawBlock in pageText.split(RegExp(r'\n{2,}'))) {
    final lines = rawBlock
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) continue;
    var merged = lines.first;
    for (var index = 1; index < lines.length; index++) {
      final current = lines[index];
      if (merged.endsWith('-') && _isLowercaseStart(current)) {
        merged = '${merged.substring(0, merged.length - 1)}$current';
      } else {
        merged = '$merged $current';
      }
    }
    if (merged.isNotEmpty) blocks.add(merged);
  }
  return blocks;
}

bool _isLowercaseStart(String text) {
  final first = text.codeUnitAt(0);
  return first >= 0x61 && first <= 0x7a;
}
