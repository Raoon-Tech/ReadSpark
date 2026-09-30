import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/repositories/document_repository_impl.dart';
import 'package:readspark/data/repositories/library_repository_impl.dart';
import 'package:readspark/data/repositories/progress_repository_impl.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/library/repositories/library_repository.dart';
import 'package:readspark/domain/progress/entities/reading_progress.dart';

import '../../helpers/fakes.dart';

void main() {
  late AppDatabase db;
  late LibraryRepository repo;
  late DocumentRepositoryImpl documents;

  setUp(() {
    db = AppDatabase.inMemory();
    repo = LibraryRepositoryImpl(db);
    documents = DocumentRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('watchItems emits an empty library on an empty database', () async {
    expect(await repo.watchItems().first, isEmpty);
  });

  test('projects document plus progress percentage (ADR-005)', () async {
    await documents.create(
      buildTestDocument('d1', title: 'Book', format: DocumentFormat.pdf),
    );
    await ProgressRepositoryImpl(db).save(
      ReadingProgress(
        id: 'p1',
        documentId: 'd1',
        characterOffset: 10,
        percentage: 0.42,
        lastReadAt: _fixedDate,
      ),
    );

    final items = await repo.watchItems().first;

    expect(items, hasLength(1));
    expect(items.single.document.title, 'Book');
    expect(items.single.percentage, 0.42);
    expect(items.single.hasProgress, isTrue);
    expect(
      items.single.lastReadAt!.millisecondsSinceEpoch,
      _fixedDate.millisecondsSinceEpoch,
    );
  });

  test('items without progress have percentage 0 and no lastReadAt', () async {
    await documents.create(buildTestDocument('d1'));

    final items = await repo.watchItems().first;

    expect(items.single.percentage, 0);
    expect(items.single.lastReadAt, isNull);
    expect(items.single.hasProgress, isFalse);
  });

  test('emits again after a document is deleted', () async {
    await documents.create(buildTestDocument('d1'));
    expect(await repo.watchItems().first, hasLength(1));

    await documents.delete('d1');

    expect(await repo.watchItems().first, isEmpty);
  });
}

final _fixedDate = DateTime.utc(2026, 3, 1);
