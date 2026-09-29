import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/repositories/bookmark_repository_impl.dart';
import 'package:readspark/data/repositories/document_repository_impl.dart';
import 'package:readspark/domain/bookmarks/entities/bookmark.dart';
import 'package:readspark/domain/bookmarks/repositories/bookmark_repository.dart';
import 'package:readspark/domain/documents/entities/document.dart';

Bookmark _bookmark(
  String id,
  String documentId, {
  int offset = 0,
  DateTime? createdAt,
}) {
  return Bookmark(
    id: id,
    documentId: documentId,
    characterOffset: offset,
    createdAt: createdAt ?? DateTime.utc(2026, 3, 1),
  );
}

void main() {
  late AppDatabase db;
  late BookmarkRepository repo;

  setUp(() async {
    db = AppDatabase.inMemory();
    repo = BookmarkRepositoryImpl(db);
    await DocumentRepositoryImpl(db).create(
      Document(
        id: 'd1',
        title: 'Doc',
        format: DocumentFormat.txt,
        filePath: '/tmp/d1.txt',
        fileSize: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        addedAt: DateTime.utc(2026, 1, 1),
      ),
    );
  });

  tearDown(() => db.close());

  test('create + getByDocument roundtrips', () async {
    final bookmark = Bookmark(
      id: 'b1',
      documentId: 'd1',
      characterOffset: 500,
      createdAt: DateTime.utc(2026, 4, 1),
      note: 'Important bit',
      pageNumber: 12,
    );

    await repo.create(bookmark);
    final loaded = await repo.getByDocument('d1');

    expect(loaded, hasLength(1));
    expect(loaded.single.id, 'b1');
    expect(loaded.single.characterOffset, 500);
    expect(loaded.single.note, 'Important bit');
    expect(loaded.single.pageNumber, 12);
    expect(
      loaded.single.createdAt.millisecondsSinceEpoch,
      DateTime.utc(2026, 4, 1).millisecondsSinceEpoch,
    );
  });

  test('bookmarks are ordered by createdAt', () async {
    await repo.create(_bookmark('b2', 'd1', createdAt: DateTime.utc(2026, 2)));
    await repo.create(_bookmark('b1', 'd1', createdAt: DateTime.utc(2026, 1)));
    await repo.create(_bookmark('b3', 'd1', createdAt: DateTime.utc(2026, 3)));

    final ids = [for (final b in await repo.getByDocument('d1')) b.id];
    expect(ids, ['b1', 'b2', 'b3']);
  });

  test('delete reports whether a bookmark was removed', () async {
    await repo.create(_bookmark('b1', 'd1'));

    expect(await repo.delete('b1'), isTrue);
    expect(await repo.getByDocument('d1'), isEmpty);
    expect(await repo.delete('b1'), isFalse);
  });

  test('foreign key requires an existing document', () async {
    expect(
      () => repo.create(_bookmark('b1', 'missing-doc')),
      throwsA(isA<Exception>()),
    );
  });
}
