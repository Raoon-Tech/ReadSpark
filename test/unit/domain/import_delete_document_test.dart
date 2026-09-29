import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/core/errors/import_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/repositories/document_file_port.dart';
import 'package:readspark/domain/documents/use_cases/delete_document.dart';
import 'package:readspark/domain/documents/use_cases/import_document.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeDocumentRepository documents;
  late FakeDocumentFilePort files;
  late ImportDocument import;

  setUp(() {
    documents = FakeDocumentRepository();
    files = FakeDocumentFilePort();
    import = ImportDocument(files, documents);
  });

  group('ImportDocument', () {
    test('registers the document with title, format, path and size (RF-02)',
        () async {
      files.nextPick = const StoredDocumentFile(
        path: '/storage/ReadSpark/notes.md',
        fileName: 'notes.md',
        sizeBytes: 2048,
      );

      final document = await import();

      expect(document, isNotNull);
      expect(document!.title, 'notes');
      expect(document.format, DocumentFormat.markdown);
      expect(document.filePath, '/storage/ReadSpark/notes.md');
      expect(document.fileSize, 2048);
      expect(document.createdAt, isNotNull);
      expect(document.addedAt, isNotNull);
      expect(documents.documents.values.single.title, 'notes');
    });

    test('returns null when the user cancels the picker', () async {
      files.nextPick = null;

      expect(await import(), isNull);
      expect(documents.documents, isEmpty);
    });

    test('extracts the title from a file with several dots', () async {
      files.nextPick = const StoredDocumentFile(
        path: '/storage/ReadSpark/my.report.final.txt',
        fileName: 'my.report.final.txt',
        sizeBytes: 10,
      );

      final document = await import();

      expect(document!.title, 'my.report.final');
      expect(document.format, DocumentFormat.txt);
    });

    test('detects format case-insensitively (RF-01)', () async {
      files.nextPick = const StoredDocumentFile(
        path: '/storage/ReadSpark/Report.DOCX',
        fileName: 'Report.DOCX',
        sizeBytes: 5,
      );

      final document = await import();

      expect(document!.format, DocumentFormat.docx);
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
