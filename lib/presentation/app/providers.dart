/// Single composition point (architecture.md §2, rule 4): UI code only
/// sees the providers of domain types declared here. The startup wiring
/// (database path resolution) lives in `bootstrap.dart`.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/datasources/document_file_data_source.dart';
import 'package:readspark/data/repositories/document_repository_impl.dart';
import 'package:readspark/data/repositories/library_repository_impl.dart';
import 'package:readspark/domain/documents/repositories/document_file_port.dart';
import 'package:readspark/domain/documents/repositories/document_repository.dart';
import 'package:readspark/domain/documents/use_cases/delete_document.dart';
import 'package:readspark/domain/documents/use_cases/import_document.dart';
import 'package:readspark/domain/library/repositories/library_repository.dart';

final appDatabaseFileProvider = Provider<File>(
  (ref) => throw UnimplementedError(
    'appDatabaseFileProvider must be overridden at startup',
  ),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open(ref.watch(appDatabaseFileProvider));
  ref.onDispose(database.close);
  return database;
});

final documentFilePortProvider = Provider<DocumentFilePort>(
  (ref) => DocumentFileDataSource(),
);

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final importDocumentProvider = Provider<ImportDocument>(
  (ref) => ImportDocument(
    ref.watch(documentFilePortProvider),
    ref.watch(documentRepositoryProvider),
  ),
);

final deleteDocumentProvider = Provider<DeleteDocument>(
  (ref) => DeleteDocument(
    ref.watch(documentRepositoryProvider),
    ref.watch(documentFilePortProvider),
  ),
);
