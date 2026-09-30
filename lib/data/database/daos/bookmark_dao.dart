import 'package:drift/drift.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/database/tables.dart';

part 'bookmark_dao.g.dart';

/// Data access for bookmarks.
@DriftAccessor(tables: [Bookmarks])
class BookmarkDao extends DatabaseAccessor<AppDatabase> with _$BookmarkDaoMixin {
  BookmarkDao(super.attachedDatabase);

  Future<void> insert(BookmarksCompanion entry) => into(bookmarks).insert(entry);

  Future<List<BookmarkRow>> byDocument(String documentId) async {
    final query = select(bookmarks)
      ..where((t) => t.documentId.equals(documentId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.get();
  }

  Future<int> deleteById(String id) =>
      (delete(bookmarks)..where((t) => t.id.equals(id))).go();
}
