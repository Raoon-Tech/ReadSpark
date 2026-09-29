import 'package:drift/drift.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/database/daos/progress_dao.dart';
import 'package:readspark/domain/progress/entities/reading_progress.dart';
import 'package:readspark/domain/progress/repositories/progress_repository.dart';

/// Drift implementation of [ProgressRepository].
///
/// Upsert semantics keep exactly one row per document (unique index on
/// `document_id`), which backs the "continue reading" flow (§12).
class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._db) : _dao = _db.progressDao;

  final AppDatabase _db;
  final ProgressDao _dao;

  @override
  Future<void> save(ReadingProgress progress) => _db.transaction(() async {
        final existing = await _dao.getByDocument(progress.documentId);
        if (existing == null) {
          await _dao.upsert(_toCompanion(progress));
        } else {
          await _dao.upsert(
            _toCompanion(progress).copyWith(id: Value(existing.id)),
          );
        }
      });

  @override
  Future<ReadingProgress?> getByDocument(String documentId) async {
    final row = await _dao.getByDocument(documentId);
    return row == null ? null : rowToEntity(row);
  }

  @override
  Future<void> delete(String documentId) => _dao.deleteByDocument(documentId);

  static ReadingProgress rowToEntity(ReadingProgressRow row) {
    return ReadingProgress(
      id: row.id,
      documentId: row.documentId,
      sectionId: row.sectionId,
      paragraphId: row.paragraphId,
      characterOffset: row.characterOffset,
      pageNumber: row.pageNumber,
      percentage: row.percentage,
      lastReadAt: row.lastReadAt,
    );
  }

  static ReadingProgressCompanion _toCompanion(ReadingProgress progress) {
    return ReadingProgressCompanion.insert(
      id: progress.id,
      documentId: progress.documentId,
      sectionId: Value(progress.sectionId),
      paragraphId: Value(progress.paragraphId),
      characterOffset: Value(progress.characterOffset),
      pageNumber: Value(progress.pageNumber),
      percentage: Value(progress.percentage),
      lastReadAt: progress.lastReadAt,
    );
  }
}
