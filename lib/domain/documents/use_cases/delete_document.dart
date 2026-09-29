import 'package:readspark/domain/documents/repositories/document_file_port.dart';
import 'package:readspark/domain/documents/repositories/document_repository.dart';

/// Removes a document from the library and its managed file copy
/// (RF-06). The user's original file is never touched.
class DeleteDocument {
  DeleteDocument(this._documents, this._files);

  final DocumentRepository _documents;
  final DocumentFilePort _files;

  /// Returns `true` if a document was removed.
  Future<bool> call(String documentId) async {
    final document = await _documents.getById(documentId);
    if (document == null) return false;

    final removed = await _documents.delete(documentId);
    if (removed) {
      await _deleteCopy(document.filePath);
    }
    return removed;
  }

  /// Best effort: the row is already gone, so a failing file deletion
  /// (missing file, path outside app storage) must not surface as an error.
  Future<void> _deleteCopy(String path) async {
    try {
      await _files.deleteStoredFile(path);
    } catch (_) {
      // Ignore — the library entry is already removed.
    }
  }
}
