import 'package:readspark/domain/bookmarks/entities/bookmark.dart';

/// Persistence contract for bookmarks (§30 Fase 8; table exists since v1).
abstract interface class BookmarkRepository {
  Future<Bookmark> create(Bookmark bookmark);

  Future<List<Bookmark>> getByDocument(String documentId);

  Future<bool> delete(String bookmarkId);
}
