import 'package:drift/drift.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/database/tables.dart';

part 'document_dao.g.dart';

/// Data access for documents, sections and paragraphs.
@DriftAccessor(tables: [Documents, DocumentSections, DocumentParagraphs])
class DocumentDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentDaoMixin {
  DocumentDao(super.attachedDatabase);

  Future<void> insert(DocumentsCompanion entry) =>
      into(documents).insert(entry);

  Future<void> replace(DocumentsCompanion entry) =>
      into(documents).insertOnConflictUpdate(entry);

  Future<DocumentRow?> getById(String id) =>
      (select(documents)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<DocumentRow>> getAll() async {
    final query = select(documents)
      ..orderBy([
        (t) => OrderingTerm(
              expression: t.lastOpenedAt,
              mode: OrderingMode.desc,
            ),
        (t) => OrderingTerm(expression: t.addedAt, mode: OrderingMode.desc),
      ]);
    return query.get();
  }

  Future<int> deleteById(String id) =>
      (delete(documents)..where((t) => t.id.equals(id))).go();

  Future<void> setFavorite(String id, bool favorite, DateTime updatedAt) =>
      (update(documents)..where((t) => t.id.equals(id))).write(
        DocumentsCompanion(
          isFavorite: Value(favorite),
          updatedAt: Value(updatedAt),
        ),
      );

  Future<void> touchLastOpened(String id, DateTime openedAt) =>
      (update(documents)..where((t) => t.id.equals(id))).write(
        DocumentsCompanion(
          lastOpenedAt: Value(openedAt),
          updatedAt: Value(openedAt),
        ),
      );

  Future<List<DocumentSectionRow>> sectionsOf(String documentId) =>
      (select(documentSections)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();

  Future<List<DocumentParagraphRow>> paragraphsOf(String documentId) =>
      (select(documentParagraphs)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();

  Future<void> insertSections(List<DocumentSectionRow> rows) =>
      batch((b) => b.insertAll(documentSections, rows));

  Future<void> insertParagraphs(List<DocumentParagraphRow> rows) =>
      batch((b) => b.insertAll(documentParagraphs, rows));

  Future<void> clearContent(String documentId) async {
    await (delete(documentParagraphs)
          ..where((t) => t.documentId.equals(documentId)))
        .go();
    await (delete(documentSections)
          ..where((t) => t.documentId.equals(documentId)))
        .go();
  }
}
