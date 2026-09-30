// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentsTable get documents => attachedDatabase.documents;
  $DocumentSectionsTable get documentSections =>
      attachedDatabase.documentSections;
  $DocumentParagraphsTable get documentParagraphs =>
      attachedDatabase.documentParagraphs;
  DocumentDaoManager get managers => DocumentDaoManager(this);
}

class DocumentDaoManager {
  final _$DocumentDaoMixin _db;
  DocumentDaoManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db.attachedDatabase, _db.documents);
  $$DocumentSectionsTableTableManager get documentSections =>
      $$DocumentSectionsTableTableManager(
        _db.attachedDatabase,
        _db.documentSections,
      );
  $$DocumentParagraphsTableTableManager get documentParagraphs =>
      $$DocumentParagraphsTableTableManager(
        _db.attachedDatabase,
        _db.documentParagraphs,
      );
}
