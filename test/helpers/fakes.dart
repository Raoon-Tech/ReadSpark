import 'dart:async';
import 'dart:io';

import 'package:readspark/core/errors/import_exception.dart';
import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';
import 'package:readspark/domain/documents/repositories/document_file_port.dart';
import 'package:readspark/domain/documents/repositories/document_repository.dart';
import 'package:readspark/domain/documents/use_cases/import_document.dart';
import 'package:readspark/domain/library/entities/library_item.dart';
import 'package:readspark/domain/library/repositories/library_repository.dart';
import 'package:readspark/domain/settings/entities/app_settings.dart';
import 'package:readspark/domain/settings/repositories/settings_repository.dart';

/// Builds a [Document] with sensible defaults for tests.
Document buildTestDocument(
  String id, {
  String? title,
  DocumentFormat format = DocumentFormat.txt,
  String? filePath,
  int fileSize = 1024,
  bool isFavorite = false,
  DateTime? lastOpenedAt,
  DateTime? addedAt,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Document(
    id: id,
    title: title ?? 'Document $id',
    format: format,
    filePath: filePath ?? '/storage/ReadSpark/$id.txt',
    fileSize: fileSize,
    createdAt: now,
    updatedAt: now,
    addedAt: addedAt ?? now,
    lastOpenedAt: lastOpenedAt,
    isFavorite: isFavorite,
  );
}

/// In-memory [DocumentRepository] recording every call.
class FakeDocumentRepository implements DocumentRepository {
  final Map<String, Document> documents = {};
  final List<String> calls = [];

  @override
  Future<Document> create(Document document) async {
    calls.add('create:${document.id}');
    documents[document.id] = document;
    return document;
  }

  @override
  Future<void> update(Document document) async {
    calls.add('update:${document.id}');
    documents[document.id] = document;
  }

  @override
  Future<bool> delete(String documentId) async {
    calls.add('delete:$documentId');
    return documents.remove(documentId) != null;
  }

  @override
  Future<Document?> getById(String documentId) async => documents[documentId];

  @override
  Future<List<Document>> getAll() async => documents.values.toList();

  @override
  Future<void> setFavorite(String documentId, bool favorite) async {
    calls.add('setFavorite:$documentId:$favorite');
    final document = documents[documentId];
    if (document != null) {
      documents[documentId] = document.copyWith(isFavorite: favorite);
    }
  }

  @override
  Future<void> touchLastOpened(String documentId, {DateTime? openedAt}) async {
    calls.add('touchLastOpened:$documentId');
    final document = documents[documentId];
    if (document != null) {
      documents[documentId] =
          document.copyWith(lastOpenedAt: openedAt ?? DateTime.now());
    }
  }

  @override
  Future<void> saveContent(DocumentContent content) async {
    calls.add('saveContent:${content.document.id}');
    documents[content.document.id] = content.document;
    contents[content.document.id] = content;
  }

  @override
  Future<DocumentContent?> getContent(String documentId) async =>
      contents[documentId];

  final Map<String, DocumentContent> contents = {};
}

/// Stream-backed [LibraryRepository]; tests push snapshots with [emit].
class FakeLibraryRepository implements LibraryRepository {
  final List<List<LibraryItem>> emissions = [];
  final StreamController<List<LibraryItem>> _controller =
      StreamController<List<LibraryItem>>.broadcast(sync: true);

  void emit(List<LibraryItem> items) {
    emissions.add(items);
    _controller.add(items);
  }

  @override
  Stream<List<LibraryItem>> watchItems() => _controller.stream;

  void dispose() => _controller.close();
}

/// Configurable [DocumentFilePort].
class FakeDocumentFilePort implements DocumentFilePort {
  StoredDocumentFile? nextPick;
  bool throwOnDelete = false;
  final List<String> deletedPaths = [];

  @override
  Future<StoredDocumentFile?> pickAndStore() async => nextPick;

  @override
  Future<void> deleteStoredFile(String path) async {
    if (throwOnDelete) {
      throw StateError('delete failed');
    }
    deletedPaths.add(path);
  }
}

/// Configurable [DocumentImporter] for use-case tests: returns
/// [result], throws [error], and records the arguments it received.
class FakeDocumentImporter implements DocumentImporter {
  ImportedDocument? result;
  ParserException? error;
  Object? crash;
  File? receivedFile;
  Document? receivedBase;
  bool acceptsEverything = true;

  @override
  bool supports(String extension) => acceptsEverything;

  @override
  Future<ImportedDocument> importDocument(File file, Document base) async {
    receivedFile = file;
    receivedBase = base;
    if (crash != null) throw crash!;
    if (error != null) throw error!;
    final provided = result;
    if (provided == null) {
      return ImportedDocument(content: defaultContentFor(base));
    }
    // Real importers enrich the document created by the use case; mirror
    // that by re-basing the provided content on [base].
    final content = provided.content;
    return ImportedDocument(
      content: DocumentContent(
        document: base.copyWith(
          author: content.document.author,
          totalPages: content.document.totalPages,
          totalCharacters: content.document.totalCharacters,
          textExtractable: content.document.textExtractable,
        ),
        sections: content.sections,
        paragraphs: content.paragraphs,
      ),
      warning: provided.warning,
    );
  }

  /// A one-section, one-paragraph document (`'Hola mundo'`, 10 chars).
  static DocumentContent defaultContentFor(Document base) {
    final section = DocumentSection(
      id: 'sec_${base.id}_0',
      documentId: base.id,
      title: '',
      order: 0,
      level: 0,
    );
    final paragraph = DocumentParagraph(
      id: 'par_${base.id}_0',
      documentId: base.id,
      sectionId: section.id,
      order: 0,
      text: 'Hola mundo',
    );
    return DocumentContent(
      document: base.copyWith(totalCharacters: 10),
      sections: [section],
      paragraphs: [paragraph],
    );
  }
}

/// Fake [ImportDocument] use case for widget tests.
class FakeImportDocument implements ImportDocument {
  ImportResult? nextResult;
  ImportException? nextError;
  ParserException? nextParserError;
  int callCount = 0;

  @override
  Future<ImportResult?> call() async {
    callCount++;
    if (nextError != null) throw nextError!;
    if (nextParserError != null) throw nextParserError!;
    return nextResult;
  }
}

/// In-memory [SettingsRepository]; [rawSaves] records every `setAll` write
/// so tests can assert that font scale / theme changes are persisted (RF-13).
class FakeSettingsRepository implements SettingsRepository {
  final Map<String, String> values = {};
  final List<Map<String, String>> rawSaves = [];

  @override
  Future<AppSettings> load() async => AppSettings.fromKeyValue(values);

  @override
  Future<void> save(AppSettings settings) async {
    values
      ..clear()
      ..addAll(settings.toKeyValue());
  }

  @override
  Future<Map<String, String>> getAll() async => Map.of(values);

  @override
  Future<void> setAll(Map<String, String> entries) async {
    rawSaves.add(Map.of(entries));
    values.addAll(entries);
  }
}

/// Builds a multi-section [DocumentContent] for reader tests:
/// sections `Section A`/`Section B` with paragraphs (B holds `'busca X'`).
DocumentContent buildReaderContent(String documentId) {
  final sectionA = DocumentSection(
    id: 'sec_${documentId}_0',
    documentId: documentId,
    title: 'Section A',
    order: 0,
    level: 0,
  );
  final sectionB = DocumentSection(
    id: 'sec_${documentId}_1',
    documentId: documentId,
    title: 'Section B',
    order: 1,
    level: 0,
  );
  final paragraphs = <DocumentParagraph>[
    DocumentParagraph(
      id: 'par_${documentId}_0',
      documentId: documentId,
      sectionId: sectionA.id,
      order: 0,
      text: 'First paragraph of A',
    ),
    DocumentParagraph(
      id: 'par_${documentId}_1',
      documentId: documentId,
      sectionId: sectionB.id,
      order: 1,
      text: 'Second paragraph where algo busca algo',
      pageNumber: 2,
    ),
    DocumentParagraph(
      id: 'par_${documentId}_2',
      documentId: documentId,
      sectionId: sectionB.id,
      order: 2,
      text: 'Third paragraph on page 3',
      pageNumber: 3,
    ),
  ];
  return DocumentContent(
    document: buildTestDocument(documentId, title: 'Reader doc').copyWith(
      totalCharacters: paragraphs.fold<int>(
        0,
        (sum, paragraph) => sum + paragraph.text.length,
      ),
      totalPages: 4,
    ),
    sections: [sectionA, sectionB],
    paragraphs: paragraphs,
  );
}
