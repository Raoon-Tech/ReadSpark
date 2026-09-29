import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/repositories/document_repository_impl.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/repositories/document_repository.dart';

Document _doc(
  String id, {
  String title = 'Doc',
  DateTime? lastOpenedAt,
  int addedAtMs = 0,
}) {
  final t = DateTime.utc(2026, 1, 1).add(Duration(milliseconds: addedAtMs));
  return Document(
    id: id,
    title: title,
    format: DocumentFormat.pdf,
    filePath: '/tmp/$id.pdf',
    fileSize: 1024,
    createdAt: t,
    updatedAt: t,
    addedAt: t,
    lastOpenedAt: lastOpenedAt,
  );
}

void main() {
  late AppDatabase db;
  late DocumentRepository repo;

  setUp(() {
    db = AppDatabase.inMemory();
    repo = DocumentRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('create + getById roundtrips every column', () async {
    final original = _doc(
      'd1',
      title: 'Clean Code',
      lastOpenedAt: DateTime.utc(2026, 2, 1),
    ).copyWith(
      author: 'Martin',
      totalPages: 400,
      totalCharacters: 90000,
      isFavorite: true,
      textExtractable: false,
    );

    await repo.create(original);
    final loaded = await repo.getById('d1');

    expect(loaded, isNotNull);
    expect(loaded!.id, original.id);
    expect(loaded.title, original.title);
    expect(loaded.author, 'Martin');
    expect(loaded.format, DocumentFormat.pdf);
    expect(loaded.filePath, original.filePath);
    expect(loaded.fileSize, original.fileSize);
    expect(loaded.totalPages, 400);
    expect(loaded.totalCharacters, 90000);
    expect(loaded.isFavorite, isTrue);
    expect(
      loaded.lastOpenedAt!.millisecondsSinceEpoch,
      original.lastOpenedAt!.millisecondsSinceEpoch,
    );
    expect(loaded.textExtractable, isFalse);
    expect(
      loaded.createdAt.millisecondsSinceEpoch,
      original.createdAt.millisecondsSinceEpoch,
    );
  });

  test('update replaces the stored row', () async {
    await repo.create(_doc('d1', title: 'Old'));
    await repo.update(
      (await repo.getById('d1'))!.copyWith(title: 'New'),
    );

    expect((await repo.getById('d1'))!.title, 'New');
    expect(await repo.getAll(), hasLength(1));
  });

  test('getAll orders by lastOpenedAt desc with nulls last', () async {
    await repo.create(_doc('a', lastOpenedAt: DateTime.utc(2026, 1, 1)));
    await repo.create(_doc('b', lastOpenedAt: DateTime.utc(2026, 3, 1)));
    await repo.create(_doc('c'));

    final ids = [for (final d in await repo.getAll()) d.id];
    expect(ids, ['b', 'a', 'c']);
  });

  test('setFavorite and touchLastOpened persist', () async {
    await repo.create(_doc('d1'));

    await repo.setFavorite('d1', true);
    expect((await repo.getById('d1'))!.isFavorite, isTrue);

    final opened = DateTime.utc(2026, 5, 5, 12);
    await repo.touchLastOpened('d1', openedAt: opened);
    expect(
      (await repo.getById('d1'))!.lastOpenedAt!.millisecondsSinceEpoch,
      opened.millisecondsSinceEpoch,
    );
  });

  test('delete reports whether a row was removed', () async {
    await repo.create(_doc('d1'));

    expect(await repo.delete('d1'), isTrue);
    expect(await repo.getById('d1'), isNull);
    expect(await repo.delete('d1'), isFalse);
  });

  test('saveContent + getContent roundtrip sections and paragraphs',
      () async {
    final doc = _doc('d1', title: 'Book');
    await repo.create(doc);

    final content = DocumentContent(
      document: doc,
      sections: [
        const DocumentSection(
          id: 's1',
          documentId: 'd1',
          title: 'Chapter 1',
          order: 0,
          level: 0,
        ),
        const DocumentSection(
          id: 's2',
          documentId: 'd1',
          title: 'Section 1.1',
          order: 1,
          level: 1,
        ),
      ],
      paragraphs: [
        const DocumentParagraph(
          id: 'p1',
          documentId: 'd1',
          sectionId: 's1',
          order: 0,
          text: 'First paragraph',
          pageNumber: 1,
        ),
        const DocumentParagraph(
          id: 'p2',
          documentId: 'd1',
          sectionId: 's2',
          order: 1,
          text: 'Second paragraph',
          pageNumber: 2,
        ),
      ],
    );

    await repo.saveContent(content);
    final loaded = await repo.getContent('d1');

    expect(loaded, isNotNull);
    expect(loaded!.document.title, 'Book');
    expect(loaded.sections.map((s) => s.id), ['s1', 's2']);
    expect(loaded.sections[1].title, 'Section 1.1');
    expect(loaded.sections[1].level, 1);
    expect(loaded.paragraphs.map((p) => p.id), ['p1', 'p2']);
    expect(loaded.paragraphs[0].text, 'First paragraph');
    expect(loaded.paragraphs[1].pageNumber, 2);
    expect(loaded.paragraphs[0].sectionId, 's1');
  });

  test('saveContent replaces previously stored content', () async {
    final doc = _doc('d1');
    await repo.create(doc);

    await repo.saveContent(
      DocumentContent(
        document: doc,
        sections: const [
          DocumentSection(
            id: 'old-s',
            documentId: 'd1',
            title: 'Old',
            order: 0,
            level: 0,
          ),
        ],
        paragraphs: const [
          DocumentParagraph(
            id: 'old-p',
            documentId: 'd1',
            sectionId: 'old-s',
            order: 0,
            text: 'Old text',
          ),
        ],
      ),
    );
    await repo.saveContent(
      DocumentContent(
        document: doc.copyWith(title: 'Replaced'),
        sections: const [
          DocumentSection(
            id: 'new-s',
            documentId: 'd1',
            title: 'New',
            order: 0,
            level: 0,
          ),
        ],
        paragraphs: const [
          DocumentParagraph(
            id: 'new-p',
            documentId: 'd1',
            sectionId: 'new-s',
            order: 0,
            text: 'New text',
          ),
        ],
      ),
    );

    final loaded = await repo.getContent('d1');
    expect(loaded!.document.title, 'Replaced');
    expect(loaded.sections.map((s) => s.id), ['new-s']);
    expect(loaded.paragraphs.map((p) => p.id), ['new-p']);
  });

  test('deleting a document cascades to sections and paragraphs', () async {
    final doc = _doc('d1');
    await repo.create(doc);
    await repo.saveContent(
      DocumentContent(
        document: doc,
        sections: const [
          DocumentSection(
            id: 's1',
            documentId: 'd1',
            title: 'Ch',
            order: 0,
            level: 0,
          ),
        ],
        paragraphs: const [
          DocumentParagraph(
            id: 'p1',
            documentId: 'd1',
            sectionId: 's1',
            order: 0,
            text: 'Text',
          ),
        ],
      ),
    );

    await repo.delete('d1');

    final counts = await db
        .customSelect(
          'SELECT (SELECT COUNT(*) FROM document_sections) AS s, '
          '(SELECT COUNT(*) FROM document_paragraphs) AS p, '
          '(SELECT COUNT(*) FROM documents) AS d',
        )
        .getSingle();
    expect(counts.read<int>('s'), 0);
    expect(counts.read<int>('p'), 0);
    expect(counts.read<int>('d'), 0);
  });
}
