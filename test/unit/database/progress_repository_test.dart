import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/repositories/document_repository_impl.dart';
import 'package:readspark/data/repositories/progress_repository_impl.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/progress/entities/reading_progress.dart';
import 'package:readspark/domain/progress/repositories/progress_repository.dart';

ReadingProgress _progress(
  String id,
  String documentId, {
  int offset = 0,
  double percentage = 0,
}) {
  return ReadingProgress(
    id: id,
    documentId: documentId,
    characterOffset: offset,
    percentage: percentage,
    lastReadAt: DateTime.utc(2026, 3, 1),
  );
}

void main() {
  late AppDatabase db;
  late ProgressRepository repo;

  setUp(() async {
    db = AppDatabase.inMemory();
    repo = ProgressRepositoryImpl(db);
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

  test('save then getByDocument roundtrips', () async {
    await repo.save(_progress('p1', 'd1', offset: 120, percentage: 0.25));

    final loaded = await repo.getByDocument('d1');
    expect(loaded, isNotNull);
    expect(loaded!.id, 'p1');
    expect(loaded.characterOffset, 120);
    expect(loaded.percentage, 0.25);
  });

  test('saving again for the same document keeps exactly one row', () async {
    await repo.save(_progress('p1', 'd1', offset: 10));
    await repo.save(
      _progress('p2', 'd1', offset: 99, percentage: 0.5)
          .copyWith(lastReadAt: DateTime.utc(2026, 3, 2)),
    );

    final rows = await db
        .customSelect('SELECT id, character_offset FROM reading_progress')
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.read<int>('character_offset'), 99);

    final loaded = await repo.getByDocument('d1');
    expect(loaded!.characterOffset, 99);
  });

  test('unknown document returns null and delete is a no-op', () async {
    expect(await repo.getByDocument('missing'), isNull);
    await repo.delete('missing');
  });

  test('delete removes the progress row', () async {
    await repo.save(_progress('p1', 'd1'));
    await repo.delete('d1');

    expect(await repo.getByDocument('d1'), isNull);
  });
}
