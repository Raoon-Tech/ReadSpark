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
