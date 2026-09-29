import 'package:drift/drift.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/database/daos/bookmark_dao.dart';
import 'package:readspark/domain/bookmarks/entities/bookmark.dart';
import 'package:readspark/domain/bookmarks/repositories/bookmark_repository.dart';

/// Drift implementation of [BookmarkRepository].
class BookmarkRepositoryImpl implements BookmarkRepository {
  BookmarkRepositoryImpl(AppDatabase db) : _dao = db.bookmarkDao;

  final BookmarkDao _dao;

  @override
  Future<Bookmark> create(Bookmark bookmark) async {
    await _dao.insert(
      BookmarksCompanion.insert(
        id: bookmark.id,
        documentId: bookmark.documentId,
        sectionId: Value(bookmark.sectionId),
        paragraphId: Value(bookmark.paragraphId),
        characterOffset: Value(bookmark.characterOffset),
        pageNumber: Value(bookmark.pageNumber),
        note: Value(bookmark.note),
        createdAt: bookmark.createdAt,
      ),
    );
    return bookmark;
  }

  @override
  Future<List<Bookmark>> getByDocument(String documentId) async {
    final rows = await _dao.byDocument(documentId);
    return [
      for (final row in rows)
        Bookmark(
          id: row.id,
          documentId: row.documentId,
          sectionId: row.sectionId,
          paragraphId: row.paragraphId,
          characterOffset: row.characterOffset,
          pageNumber: row.pageNumber,
          note: row.note,
          createdAt: row.createdAt,
        ),
    ];
  }

  @override
  Future<bool> delete(String bookmarkId) async {
    final removed = await _dao.deleteById(bookmarkId);
    return removed > 0;
  }
}
