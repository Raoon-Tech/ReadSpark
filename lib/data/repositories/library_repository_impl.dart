import 'package:drift/drift.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/repositories/document_repository_impl.dart';
import 'package:readspark/domain/library/entities/library_item.dart';
import 'package:readspark/domain/library/repositories/library_repository.dart';

/// Library projection over `documents LEFT JOIN reading_progress`
/// (ADR-005). Emits on every change to either table.
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<LibraryItem>> watchItems() {
    final query = _db.select(_db.documents).join([
      leftOuterJoin(
        _db.readingProgress,
        _db.readingProgress.documentId.equalsExp(_db.documents.id),
      ),
    ]);

    return query.watch().map((rows) {
      return [
        for (final row in rows)
          LibraryItem(
            document: DocumentRepositoryImpl.rowToEntity(
              row.readTable(_db.documents),
            ),
            percentage: row.readTableOrNull(_db.readingProgress)?.percentage ??
                0,
            lastReadAt: row.readTableOrNull(_db.readingProgress)?.lastReadAt,
          ),
      ];
    });
  }
}
