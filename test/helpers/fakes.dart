import 'dart:async';

import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/repositories/document_file_port.dart';
import 'package:readspark/domain/documents/repositories/document_repository.dart';
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
    throw UnimplementedError();
  }

  @override
  Future<DocumentContent?> getContent(String documentId) async => null;
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
