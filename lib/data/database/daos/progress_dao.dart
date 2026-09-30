import 'package:drift/drift.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/database/tables.dart';

part 'progress_dao.g.dart';

/// Data access for reading progress. One row per document (upsert).
@DriftAccessor(tables: [ReadingProgress])
class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.attachedDatabase);

  Future<void> upsert(ReadingProgressCompanion entry) =>
      into(readingProgress).insertOnConflictUpdate(entry);

  Future<ReadingProgressRow?> getByDocument(String documentId) =>
      (select(readingProgress)..where((t) => t.documentId.equals(documentId)))
          .getSingleOrNull();

  Future<int> deleteByDocument(String documentId) =>
      (delete(readingProgress)..where((t) => t.documentId.equals(documentId)))
          .go();
}
