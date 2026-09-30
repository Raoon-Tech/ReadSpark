import 'package:readspark/core/errors/import_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/repositories/document_file_port.dart';
import 'package:readspark/domain/documents/repositories/document_repository.dart';

/// Picks a supported file, stores a managed copy and registers the
/// document in the library (CU-01, RF-01/RF-02).
class ImportDocument {
  ImportDocument(this._files, this._documents);

  final DocumentFilePort _files;
  final DocumentRepository _documents;

  /// Returns the created [Document], or `null` when the user cancels.
  Future<Document?> call() async {
    final stored = await _files.pickAndStore();
    if (stored == null) return null;

    final extension = _extensionOf(stored.fileName);
    final format = DocumentFormat.fromExtension(extension);
    if (format == null) {
      throw const ImportException(
        ImportErrorCode.unsupportedExtension,
        'Formato no soportado. Usa PDF, DOCX, Markdown o TXT.',
      );
    }

    final now = DateTime.now();
    final document = Document(
      id: _generateId(now),
      title: _titleOf(stored.fileName),
      format: format,
      filePath: stored.path,
      fileSize: stored.sizeBytes,
      createdAt: now,
      updatedAt: now,
      addedAt: now,
    );

    await _documents.create(document);
    return document;
  }

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot).toLowerCase();
  }

  static String _titleOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot <= 0 ? fileName : fileName.substring(0, dot);
  }

  static String _generateId(DateTime now) {
    final stamp = now.microsecondsSinceEpoch.toRadixString(36);
    final suffix = now.hashCode.toRadixString(36);
    return 'doc_$stamp$suffix';
  }
}
