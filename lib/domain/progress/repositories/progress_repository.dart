import 'package:readspark/domain/progress/entities/reading_progress.dart';

/// Persistence contract for reading progress (§12).
abstract interface class ProgressRepository {
  /// Upserts the progress of a document (one row per document).
  Future<void> save(ReadingProgress progress);

  /// Progress of a document, or `null` if it has never been opened.
  Future<ReadingProgress?> getByDocument(String documentId);

  /// Removes the progress of a document.
  Future<void> delete(String documentId);
}
