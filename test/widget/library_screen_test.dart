import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';
import 'package:readspark/domain/documents/use_cases/import_document.dart';
import 'package:readspark/domain/library/entities/library_item.dart';
import 'package:readspark/presentation/app/app.dart';
import 'package:readspark/presentation/app/providers.dart';

import '../helpers/fakes.dart';

class _Harness {
  _Harness(this.library, this.documents, this.files, this.importer);

  final FakeLibraryRepository library;
  final FakeDocumentRepository documents;
  final FakeDocumentFilePort files;
  final FakeImportDocument importer;
}

Future<_Harness> _pumpLibrary(WidgetTester tester) async {
  final library = FakeLibraryRepository();
  final documents = FakeDocumentRepository();
  final files = FakeDocumentFilePort();
  final importer = FakeImportDocument();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(library),
        documentRepositoryProvider.overrideWithValue(documents),
        documentFilePortProvider.overrideWithValue(files),
        importDocumentProvider.overrideWithValue(importer),
      ],
      child: const ReadSparkApp(),
    ),
  );
  await tester.pump();
  return _Harness(library, documents, files, importer);
}

LibraryItem _item(String id, String title, {bool favorite = false}) {
  final readAt = DateTime.utc(2026, 6, 1);
  return LibraryItem(
    document: buildTestDocument(
      id,
      title: title,
      format: DocumentFormat.pdf,
      fileSize: 2048,
      isFavorite: favorite,
      lastOpenedAt: readAt,
    ),
    percentage: 0.4,
    lastReadAt: readAt,
  );
}

void main() {
  testWidgets('shows the empty library state', (tester) async {
    final harness = await _pumpLibrary(tester);
    harness.library.emit([]);
    await tester.pump();

    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Tu biblioteca está vacía'), findsOneWidget);
    expect(find.textContaining('sin conexión'), findsOneWidget);
  });

  testWidgets('renders each document with format and progress (RF-03)',
      (tester) async {
    final harness = await _pumpLibrary(tester);
    harness.library.emit([
      _item('d1', 'Clean Code'),
      _item('d2', 'The Pragmatic Programmer'),
    ]);
    await tester.pump();

    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('The Pragmatic Programmer'), findsOneWidget);
    expect(find.textContaining('PDF'), findsNWidgets(2));
    expect(find.textContaining('40% leído'), findsNWidgets(2));
  });

  testWidgets('search filters by title (RF-05)', (tester) async {
    final harness = await _pumpLibrary(tester);
    harness.library.emit([
      _item('d1', 'Clean Code'),
      _item('d2', 'Refactoring'),
    ]);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'refact');
    await tester.pump();

    expect(find.text('Refactoring'), findsOneWidget);
    expect(find.text('Clean Code'), findsNothing);
  });

  testWidgets('tapping the star toggles the favorite (RF-07)',
      (tester) async {
    final harness = await _pumpLibrary(tester);
    harness.library.emit([_item('d1', 'Clean Code')]);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();

    expect(harness.documents.calls, contains('setFavorite:d1:true'));
  });

  testWidgets('tapping a tile opens it and marks it as last opened',
      (tester) async {
    final harness = await _pumpLibrary(tester);
    harness.library.emit([_item('d1', 'Clean Code')]);
    await tester.pump();

    await tester.tap(find.text('Clean Code'));
    await tester.pumpAndSettle();

    expect(harness.documents.calls, contains('touchLastOpened:d1'));
    expect(find.textContaining('Fase 5'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation, then removes row and file (RF-06)',
      (tester) async {
    final harness = await _pumpLibrary(tester);
    harness.library.emit([_item('d1', 'Clean Code')]);
    harness.documents.documents['d1'] =
        harness.library.emissions.single.first.document;
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar documento'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(harness.documents.documents, isEmpty);
    expect(harness.files.deletedPaths, ['/storage/ReadSpark/d1.txt']);
  });

  testWidgets('import button reports the picked file (RF-01/RF-02)',
      (tester) async {
    final harness = await _pumpLibrary(tester);
    harness.library.emit([]);
    harness.importer.nextResult = ImportResult(
      document: buildTestDocument('n1', title: 'notes'),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Importar documento'));
    await tester.pumpAndSettle();

    expect(harness.importer.callCount, 1);
    expect(
      find.text('«notes» añadido a la biblioteca'),
      findsOneWidget,
    );
  });

  testWidgets('import shows the scanned-PDF warning after success (C7)',
      (tester) async {
    final harness = await _pumpLibrary(tester);
    harness.library.emit([]);
    harness.importer.nextResult = ImportResult(
      document: buildTestDocument('s1', title: 'escaneo'),
      warning: ImportWarning.scannedPdf,
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Importar documento'));
    await tester.pumpAndSettle();

    expect(find.text('«escaneo» añadido a la biblioteca'), findsOneWidget);

    // ScaffoldMessenger queues the warning behind the success message:
    // let the first snackbar expire, then finish the transition.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.textContaining('parece estar escaneado'), findsOneWidget);
  });

  testWidgets('import shows a friendly message when parsing fails (RF-73)',
      (tester) async {
    final harness = await _pumpLibrary(tester);
    harness.library.emit([]);
    harness.importer.nextParserError = const ParserException(
      ParserErrorCode.corruptFile,
      'El archivo DOCX está dañado.',
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Importar documento'));
    await tester.pumpAndSettle();

    expect(
      find.text('El archivo DOCX está dañado.'),
      findsOneWidget,
    );
    // The button is usable again after the error.
    expect(
      tester.widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .onPressed,
      isNotNull,
    );
  });
}
