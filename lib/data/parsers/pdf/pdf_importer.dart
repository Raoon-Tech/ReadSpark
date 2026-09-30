import 'dart:io';

import 'package:pdfrx/pdfrx.dart';

import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';

import 'pdf_structure_builder.dart';

/// PDF importer (§14): pdfrx/PDFium extraction (`PdfPage.loadText`) plus
/// the outline (bookmarks) to recover chapters. The structure conversion
/// lives in [buildPdfContent] (pure, unit-tested).
class PdfImporter implements DocumentImporter {
  const PdfImporter();

  @override
  bool supports(String extension) => extension.toLowerCase() == '.pdf';

  @override
  Future<ImportedDocument> importDocument(File file, Document base) async {
    if (!await file.exists()) {
      throw const ParserException(
        ParserErrorCode.readFailed,
        'No se pudo leer el archivo.',
      );
    }

    try {
      await pdfrxFlutterInitialize();
      final document = await PdfDocument.openFile(file.path);
      try {
        final pageTexts = <String>[];
        for (final page in document.pages) {
          final raw = await page.loadText();
          pageTexts.add(raw?.fullText ?? '');
        }
        return buildPdfContent(
          base: base,
          pageTexts: pageTexts,
          outline: await _outlineOf(document),
        );
      } finally {
        await document.dispose();
      }
    } on ParserException {
      rethrow;
    } catch (error) {
      throw ParserException(
        ParserErrorCode.corruptFile,
        'El PDF no se pudo leer. Puede que esté dañado.',
        technicalDetail: '$error',
      );
    }
  }

  /// Flattens the outline tree into depth-annotated entries. The outline is
  /// optional: a PDF without bookmarks still imports (root section).
  Future<List<PdfOutlineEntry>> _outlineOf(PdfDocument document) async {
    final List<PdfOutlineNode> roots;
    try {
      roots = await document.loadOutline();
    } catch (_) {
      return const [];
    }
    final entries = <PdfOutlineEntry>[];
    void visit(List<PdfOutlineNode> nodes, int depth) {
      for (final node in nodes) {
        final destination = node.dest;
        if (destination != null && depth < 6) {
          entries.add(
            PdfOutlineEntry(
              title: node.title.trim(),
              // PdfDest.pageNumber is 1-based; sections use 0-based pages.
              pageIndex: destination.pageNumber - 1,
              depth: depth,
            ),
          );
        }
        visit(node.children, destination == null ? depth : depth + 1);
      }
    }

    visit(roots, 0);
    return entries;
  }
}
