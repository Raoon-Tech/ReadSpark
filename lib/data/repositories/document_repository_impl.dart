import 'package:drift/drift.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/database/daos/document_dao.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/repositories/document_repository.dart';

/// Drift implementation of [DocumentRepository].
class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl(this._db) : _dao = _db.documentDao;

  final AppDatabase _db;
  final DocumentDao _dao;

  @override
  Future<Document> create(Document document) async {
    await _dao.insert(_documentToCompanion(document));
    return document;
  }

  @override
  Future<void> update(Document document) =>
      _dao.replace(_documentToCompanion(document));

  @override
  Future<bool> delete(String documentId) async {
    final removed = await _dao.deleteById(documentId);
    return removed > 0;
  }

  @override
  Future<Document?> getById(String documentId) async {
    final row = await _dao.getById(documentId);
    return row == null ? null : rowToEntity(row);
  }

  @override
  Future<List<Document>> getAll() async {
    final rows = await _dao.getAll();
    return [for (final row in rows) rowToEntity(row)];
  }

  @override
  Future<void> setFavorite(String documentId, bool favorite) =>
      _dao.setFavorite(documentId, favorite, DateTime.now());

  @override
  Future<void> touchLastOpened(String documentId, {DateTime? openedAt}) =>
      _dao.touchLastOpened(documentId, openedAt ?? DateTime.now());

  @override
  Future<void> saveContent(DocumentContent content) => _db.transaction(() async {
        await _dao.replace(_documentToCompanion(content.document));
        await _dao.clearContent(content.document.id);
        await _dao.insertSections([
          for (final section in content.sections)
            DocumentSectionRow(
              id: section.id,
              documentId: section.documentId,
              title: section.title,
              sortOrder: section.order,
              level: section.level,
            ),
        ]);
        await _dao.insertParagraphs([
          for (final paragraph in content.paragraphs)
            DocumentParagraphRow(
              id: paragraph.id,
              documentId: paragraph.documentId,
              sectionId: paragraph.sectionId,
              sortOrder: paragraph.order,
              body: paragraph.text,
              pageNumber: paragraph.pageNumber,
            ),
        ]);
      });

  @override
  Future<DocumentContent?> getContent(String documentId) => _db.transaction(
        () async {
          final row = await _dao.getById(documentId);
          if (row == null) return null;
          final sectionRows = await _dao.sectionsOf(documentId);
          final paragraphRows = await _dao.paragraphsOf(documentId);
          return DocumentContent(
            document: rowToEntity(row),
            sections: [
              for (final s in sectionRows)
                DocumentSection(
                  id: s.id,
                  documentId: s.documentId,
                  title: s.title,
                  order: s.sortOrder,
                  level: s.level,
                ),
            ],
            paragraphs: [
              for (final p in paragraphRows)
                DocumentParagraph(
                  id: p.id,
                  documentId: p.documentId,
                  sectionId: p.sectionId,
                  order: p.sortOrder,
                  text: p.body,
                  pageNumber: p.pageNumber,
                ),
            ],
          );
        },
      );

  /// Maps a database row to the domain entity.
  static Document rowToEntity(DocumentRow row) {
    return Document(
      id: row.id,
      title: row.title,
      author: row.author,
      format: DocumentFormat.tryParse(row.format) ?? DocumentFormat.txt,
      filePath: row.filePath,
      fileSize: row.fileSize,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastOpenedAt: row.lastOpenedAt,
      totalPages: row.totalPages,
      totalCharacters: row.totalCharacters,
      isFavorite: row.isFavorite,
      addedAt: row.addedAt,
      textExtractable: row.textExtractable,
    );
  }

  static DocumentsCompanion _documentToCompanion(Document document) {
    return DocumentsCompanion.insert(
      id: document.id,
      title: document.title,
      author: Value(document.author),
      format: document.format.storageValue,
      filePath: document.filePath,
      fileSize: document.fileSize,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
      lastOpenedAt: Value(document.lastOpenedAt),
      totalPages: Value(document.totalPages),
      totalCharacters: Value(document.totalCharacters),
      isFavorite: Value(document.isFavorite),
      addedAt: document.addedAt,
      textExtractable: Value(document.textExtractable),
    );
  }
}
