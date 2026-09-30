import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';

/// Resolves the importer for a file extension (ADR-007): a list of
/// [DocumentImporter]s instead of chained `if (extension == ...)` blocks.
/// Adding EPUB/HTML/ODT (Fase 11) = registering a new class here.
class ImporterRegistry {
  ImporterRegistry(Iterable<DocumentImporter> importers)
      : _importers = List.unmodifiable(importers);

  final List<DocumentImporter> _importers;

  /// The importer for [extension] (lowercase, with dot). Throws
  /// [ParserException] when no importer supports the extension.
  DocumentImporter resolve(String extension) {
    final normalized = extension.toLowerCase();
    for (final importer in _importers) {
      if (importer.supports(normalized)) return importer;
    }
    throw const ParserException(
      ParserErrorCode.unsupportedFormat,
      'Formato no soportado. Usa PDF, DOCX, Markdown o TXT.',
    );
  }
}
