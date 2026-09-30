import 'dart:io';

import 'package:readspark/domain/documents/entities/document.dart';

/// Warnings surfaced to the UI after a successful import without blocking
/// it (RF-73).
enum ImportWarning {
  /// The PDF has no extractable text (scanned document). Imported with
  /// empty content; OCR is out of the MVP scope (C7, Fase 11).
  scannedPdf,
}

/// Result of parsing one file with a [DocumentImporter]: the full
/// `DocumentModel` aggregate (ADR-001) plus non-blocking warnings.
class ImportedDocument {
  const ImportedDocument({required this.content, this.warning});

  final DocumentContent content;

  /// `null` when the import produced no warnings.
  final ImportWarning? warning;
}

/// Converts one stored file into the common document model (ADR-007).
///
/// Implementations live in `data/parsers`; the domain only sees this
/// interface, so adding a format (Fase 11) never touches the reader, the
/// ReaderEngine nor the TTS.
abstract interface class DocumentImporter {
  /// Lowercase extension with dot (`.pdf`, `.md`, ...).
  bool supports(String extension);

  /// Parses [file] into sections/paragraphs, filling metadata on a copy of
  /// [base] (author, pages, character count, extractability).
  ///
  /// Throws [ParserException] when the file cannot be parsed.
  Future<ImportedDocument> importDocument(File file, Document base);
}
