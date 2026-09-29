import 'package:readspark/domain/documents/entities/document.dart';

/// Persistence contract for documents and their content (§9, §30 Fase 2).
abstract interface class DocumentRepository {
  /// Inserts a new document (metadata only).
  Future<Document> create(Document document);

  /// Replaces the metadata of an existing document.
  Future<void> update(Document document);

  /// Deletes a document, its sections, paragraphs, progress and bookmarks
  /// (cascade). Returns `true` if a document was removed.
  Future<bool> delete(String documentId);

  Future<Document?> getById(String documentId);

  /// All documents ordered by `lastOpenedAt` (nulls last), then `addedAt`.
  Future<List<Document>> getAll();

  Future<void> setFavorite(String documentId, bool favorite);

  /// Updates `lastOpenedAt` to [openedAt] (defaults to now).
  Future<void> touchLastOpened(String documentId, {DateTime? openedAt});

  /// Stores document + sections + paragraphs atomically (used by importers).
  Future<void> saveContent(DocumentContent content);

  /// Loads the full content tree of a document, or `null` if missing.
  Future<DocumentContent?> getContent(String documentId);
}
