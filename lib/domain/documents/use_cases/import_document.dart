import 'dart:io';

import 'package:readspark/core/constants/app_constants.dart';
import 'package:readspark/core/errors/import_exception.dart';
import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';
import 'package:readspark/domain/documents/importers/importer_registry.dart';
import 'package:readspark/domain/documents/repositories/document_file_port.dart';
import 'package:readspark/domain/documents/repositories/document_repository.dart';

/// Outcome of a completed import (CU-01).
class ImportResult {
  const ImportResult({required this.document, this.warning});

  final Document document;

  /// Non-blocking warning to show alongside success (e.g. scanned PDF).
  final ImportWarning? warning;
}

/// Picks a supported file, stores a managed copy, parses it into the
/// common document model with the resolved importer (ADR-007) and persists
/// document + sections + paragraphs atomically (CU-01, RF-01/RF-02).
class ImportDocument {
  ImportDocument(this._files, this._documents, this._importers);

  final DocumentFilePort _files;
  final DocumentRepository _documents;
  final ImporterRegistry _importers;

  /// Returns the import outcome, or `null` when the user cancels.
  ///
  /// On any failure the managed copy is deleted (best effort) and a typed
  /// error with a friendly message is thrown (RF-73).
  Future<ImportResult?> call() async {
    final stored = await _files.pickAndStore();
    if (stored == null) return null;

    try {
      if (stored.sizeBytes > AppConstants.maxImportSizeBytes) {
        throw ImportException(
          ImportErrorCode.fileTooLarge,
          'El archivo supera el límite de '
          '${AppConstants.maxImportSizeBytes ~/ (1024 * 1024)} MB.',
        );
      }

      final extension = _extensionOf(stored.fileName);
      final format = DocumentFormat.fromExtension(extension);
      if (format == null) {
        throw const ImportException(
          ImportErrorCode.unsupportedExtension,
          'Formato no soportado. Usa PDF, DOCX, Markdown o TXT.',
        );
      }

      final now = DateTime.now();
      final base = Document(
        id: _generateId(now),
        title: _titleOf(stored.fileName),
        format: format,
        filePath: stored.path,
        fileSize: stored.sizeBytes,
        createdAt: now,
        updatedAt: now,
        addedAt: now,
      );

      final imported = await _importers
          .resolve(extension)
          .importDocument(File(stored.path), base);

      await _documents.saveContent(imported.content);
      return ImportResult(
        document: imported.content.document,
        warning: imported.warning,
      );
    } on ImportException {
      await _deleteQuietly(stored.path);
      rethrow;
    } on ParserException {
      await _deleteQuietly(stored.path);
      rethrow;
    } catch (error) {
      await _deleteQuietly(stored.path);
      throw ParserException(
        ParserErrorCode.readFailed,
        'No se pudo leer el archivo. Puede que esté dañado.',
        technicalDetail: '$error',
      );
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await _files.deleteStoredFile(path);
    } catch (_) {
      // Best effort: the orphan copy is harmless (delete is idempotent).
    }
  }

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot).toLowerCase();
  }

  static String _titleOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot <= 0 ? fileName : fileName.substring(0, dot);
  }

  static String _generateId(DateTime now) {
    final stamp = now.microsecondsSinceEpoch.toRadixString(36);
    final suffix = now.hashCode.toRadixString(36);
    return 'doc_$stamp$suffix';
  }
}
