import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/core/constants/app_constants.dart';
import 'package:readspark/core/errors/import_exception.dart';
import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';
import 'package:readspark/domain/documents/importers/importer_registry.dart';
import 'package:readspark/domain/documents/repositories/document_file_port.dart';
import 'package:readspark/domain/documents/use_cases/delete_document.dart';
import 'package:readspark/domain/documents/use_cases/import_document.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeDocumentRepository documents;
  late FakeDocumentFilePort files;
  late FakeDocumentImporter importer;
  late ImportDocument import;

  setUp(() {
    documents = FakeDocumentRepository();
    files = FakeDocumentFilePort();
    importer = FakeDocumentImporter();
    import = ImportDocument(
      files,
      documents,
      ImporterRegistry([importer]),
    );
  });

  group('ImportDocument', () {
    test('parses and stores the document with title, format and size (RF-02)',
        () async {
      files.nextPick = const StoredDocumentFile(
        path: '/storage/ReadSpark/notes.md',
        fileName: 'notes.md',
        sizeBytes: 2048,
      );

      final result = await import();

      expect(result, isNotNull);
      final document = result!.document;
      expect(document.title, 'notes');
      expect(document.format, DocumentFormat.markdown);
      expect(document.filePath, '/storage/ReadSpark/notes.md');
      expect(document.fileSize, 2048);
      expect(document.createdAt, isNotNull);
      expect(document.addedAt, isNotNull);
      expect(document.totalCharacters, 10);
      expect(documents.documents.values.single.title, 'notes');
      expect(documents.contents[document.id]!.paragraphs.single.text,
          'Hola mundo');
      expect(importer.receivedFile!.path, '/storage/ReadSpark/notes.md');
    });

    test('returns null when the user cancels the picker', () async {
      files.nextPick = null;

      expect(await import(), isNull);
      expect(documents.documents, isEmpty);
      expect(importer.receivedFile, isNull);
    });

    test('extracts the title from a file with several dots', () async {
      files.nextPick = const StoredDocumentFile(
        path: '/storage/ReadSpark/my.report.final.txt',
        fileName: 'my.report.final.txt',
        sizeBytes: 10,
      );

      final result = await import();

      expect(result!.document.title, 'my.report.final');
      expect(result.document.format, DocumentFormat.txt);
    });

    test('detects format case-insensitively (RF-01)', () async {
      files.nextPick = const StoredDocumentFile(
        path: '/storage/ReadSpark/Report.DOCX',
        fileName: 'Report.DOCX',
        sizeBytes: 5,
      );

      final result = await import();

      expect(result!.document.format, DocumentFormat.docx);
    });

    test('rejects unsupported extensions with a friendly error (RF-73)',
        () async {
      files.nextPick = const StoredDocumentFile(
        path: '/storage/ReadSpark/image.png',
        fileName: 'image.png',
        sizeBytes: 5,
      );

      await expectLater(
        import(),
        throwsA(
          isA<ImportException>().having(
            (e) => e.errorCode,
            'errorCode',
            ImportErrorCode.unsupportedExtension,
          ),
        ),
      );
      expect(documents.documents, isEmpty);
      expect(files.deletedPaths, ['/storage/ReadSpark/image.png']);
      expect(importer.receivedFile, isNull);
    });

    test('rejects files above the size limit (RF-72)', () async {
      files.nextPick = StoredDocumentFile(
        path: '/storage/ReadSpark/huge.txt',
        fileName: 'huge.txt',
        sizeBytes: AppConstants.maxImportSizeBytes + 1,
      );

      await expectLater(
        import(),
        throwsA(
          isA<ImportException>().having(
            (e) => e.errorCode,
            'errorCode',
            ImportErrorCode.fileTooLarge,
          ),
        ),
      );
      expect(documents.documents, isEmpty);
      expect(files.deletedPaths, ['/storage/ReadSpark/huge.txt']);
      expect(importer.receivedFile, isNull);
    });

    test('cleans up the managed copy when parsing fails (RF-73)', () async {
      files.nextPick = const StoredDocumentFile(
        path: '/storage/ReadSpark/broken.docx',
        fileName: 'broken.docx',
        sizeBytes: 42,
      );
      importer.error = const ParserException(
        ParserErrorCode.corruptFile,
        'El archivo DOCX está dañado.',
      );

      await expectLater(
        import(),
        throwsA(
          isA<ParserException>().having(
            (e) => e.errorCode,
            'errorCode',
            ParserErrorCode.corruptFile,
          ),
        ),
      );
      expect(documents.documents, isEmpty);
      expect(files.deletedPaths, ['/storage/ReadSpark/broken.docx']);
    });

    test('maps unexpected parser crashes to a friendly error', () async {
      files.nextPick = const StoredDocumentFile(
        path: '/storage/ReadSpark/notes.md',
        fileName: 'notes.md',
        sizeBytes: 10,
      );
      importer.crash = StateError('boom');

      await expectLater(
        import(),
        throwsA(
          isA<ParserException>()
              .having((e) => e.errorCode, 'errorCode',
                  ParserErrorCode.readFailed)
              .having((e) => e.technicalDetail, 'technicalDetail',
                  contains('boom')),
        ),
      );
      expect(documents.documents, isEmpty);
      expect(files.deletedPaths, ['/storage/ReadSpark/notes.md']);
    });

    test('propagates non-blocking warnings (C7 scanned PDF)', () async {
      files.nextPick = const StoredDocumentFile(
        path: '/storage/ReadSpark/scan.pdf',
        fileName: 'scan.pdf',
        sizeBytes: 1000,
      );
      importer.result = ImportedDocument(
        content: FakeDocumentImporter.defaultContentFor(
          buildTestDocument('scan'),
        ),
        warning: ImportWarning.scannedPdf,
      );

      final result = await import();

      expect(result!.warning, ImportWarning.scannedPdf);
      expect(result.document.title, 'scan');
      expect(documents.documents, hasLength(1));
      expect(files.deletedPaths, isEmpty);
    });
  });

  group('DeleteDocument', () {
    test('removes the row and the stored copy (RF-06)', () async {
      await documents.create(
        buildTestDocument('d1', filePath: '/storage/ReadSpark/d1.txt'),
      );

      final removed = await DeleteDocument(documents, files)('d1');

      expect(removed, isTrue);
      expect(documents.documents, isEmpty);
      expect(files.deletedPaths, ['/storage/ReadSpark/d1.txt']);
    });

    test('returns false for an unknown document', () async {
      final removed = await DeleteDocument(documents, files)('missing');

      expect(removed, isFalse);
      expect(files.deletedPaths, isEmpty);
    });

    test('still succeeds when the stored copy cannot be deleted', () async {
      await documents.create(
        buildTestDocument('d1', filePath: '/storage/ReadSpark/d1.txt'),
      );
      files.throwOnDelete = true;

      final removed = await DeleteDocument(documents, files)('d1');

      expect(removed, isTrue);
      expect(documents.documents, isEmpty);
    });
  });
}
