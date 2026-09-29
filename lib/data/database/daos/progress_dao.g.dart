// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_dao.dart';

// ignore_for_file: type=lint
mixin _$ProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentsTable get documents => attachedDatabase.documents;
  $DocumentSectionsTable get documentSections =>
      attachedDatabase.documentSections;
  $DocumentParagraphsTable get documentParagraphs =>
      attachedDatabase.documentParagraphs;
  $ReadingProgressTable get readingProgress => attachedDatabase.readingProgress;
  ProgressDaoManager get managers => ProgressDaoManager(this);
}

class ProgressDaoManager {
  final _$ProgressDaoMixin _db;
  ProgressDaoManager(this._db);
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
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(
        _db.attachedDatabase,
        _db.readingProgress,
      );
}
