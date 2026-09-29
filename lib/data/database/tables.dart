import 'package:drift/drift.dart';

/// Schema v1 — see docs/database.md. Never destroy a schema without a
/// versioned migration (§11).

@DataClassName('DocumentRow')
@TableIndex(name: 'idx_documents_last_opened', columns: {#lastOpenedAt})
@TableIndex(name: 'idx_documents_favorite', columns: {#isFavorite})
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get format => text()();
  TextColumn get filePath => text().unique()();
  IntColumn get fileSize => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  IntColumn get totalPages => integer().nullable()();
  IntColumn get totalCharacters => integer().withDefault(const Constant(0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get addedAt => dateTime()();
  BoolColumn get textExtractable =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DocumentSectionRow')
@TableIndex(name: 'idx_sections_document', columns: {#documentId})
class DocumentSections extends Table {
  TextColumn get id => text()();
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer()();
  IntColumn get level => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DocumentParagraphRow')
@TableIndex(name: 'idx_paragraphs_section', columns: {#sectionId})
@TableIndex(
  name: 'idx_paragraphs_document',
  columns: {#documentId, #sortOrder},
)
class DocumentParagraphs extends Table {
  TextColumn get id => text()();
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get sectionId =>
      text().references(DocumentSections, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer()();
  TextColumn get body => text().named('text')();
  IntColumn get pageNumber => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReadingProgressRow')
@TableIndex(name: 'idx_progress_document', columns: {#documentId})
class ReadingProgress extends Table {
  TextColumn get id => text()();
  TextColumn get documentId =>
      text().unique().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get sectionId =>
      text().nullable().references(DocumentSections, #id, onDelete: KeyAction.setNull)();
  TextColumn get paragraphId =>
      text().nullable().references(DocumentParagraphs, #id, onDelete: KeyAction.setNull)();
  IntColumn get characterOffset => integer().withDefault(const Constant(0))();
  IntColumn get pageNumber => integer().nullable()();
  RealColumn get percentage => real().withDefault(const Constant(0))();
  DateTimeColumn get lastReadAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BookmarkRow')
@TableIndex(name: 'idx_bookmarks_document', columns: {#documentId})
class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get sectionId => text().nullable()();
  TextColumn get paragraphId => text().nullable()();
  IntColumn get characterOffset => integer().withDefault(const Constant(0))();
  IntColumn get pageNumber => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('VoiceRow')
@TableIndex(name: 'idx_voices_platform', columns: {#platform})
class Voices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get locale => text()();
  TextColumn get provider => text().nullable()();
  TextColumn get platform => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
