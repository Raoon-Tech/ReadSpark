import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/settings/entities/app_settings.dart';
import 'package:readspark/presentation/app/providers.dart';
import 'package:readspark/presentation/reader/reader_screen.dart';

import '../helpers/fakes.dart';

class _Harness {
  _Harness(this.documents, this.settings);

  final FakeDocumentRepository documents;
  final FakeSettingsRepository settings;
}

Future<_Harness> _pumpReader(
  WidgetTester tester, {
  String documentId = 'd1',
}) async {
  final documents = FakeDocumentRepository();
  final settings = FakeSettingsRepository();
  documents.contents['d1'] = buildReaderContent('d1');
  documents.documents['d1'] = documents.contents['d1']!.document;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(documents),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: MaterialApp(
        home: ReaderScreen(
          documentId: documentId,
          documentTitle: 'Reader doc',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(documents, settings);
}

void main() {
  testWidgets('renders the document content (RF-10)', (tester) async {
    await _pumpReader(tester);

    expect(find.text('Reader doc'), findsOneWidget);
    expect(find.text('Section A'), findsOneWidget);
    expect(find.text('First paragraph of A'), findsOneWidget);
    expect(find.text('Second paragraph where algo busca algo'), findsOneWidget);
    expect(find.textContaining('1/2 · Section A'), findsWidgets);
    expect(find.byTooltip('Sección siguiente'), findsOneWidget);
  });

  testWidgets('section arrows navigate and update the label (RF-11)',
      (tester) async {
    await _pumpReader(tester);

    expect(find.textContaining('1/2 · Section A'), findsWidgets);

    await tester.tap(find.byTooltip('Sección siguiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2/2 · Section B'), findsWidgets);

    await tester.tap(find.byTooltip('Sección anterior'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1/2 · Section A'), findsWidgets);
  });

  testWidgets('arrow keys navigate sections (RF-11, §24)', (tester) async {
    await _pumpReader(tester);
    expect(find.textContaining('1/2 · Section A'), findsWidgets);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(find.textContaining('2/2 · Section B'), findsWidgets);
  });

  testWidgets('search reports match count and highlights (RF-12)',
      (tester) async {
    await _pumpReader(tester);

    await tester.tap(find.byTooltip('Buscar en el documento'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'busca');
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('Second paragraph where algo busca algo'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Sin resultados'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar búsqueda'));
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsNothing);
    expect(find.text('Sin resultados'), findsNothing);
  });

  testWidgets('font size buttons persist the scale (RF-13)', (tester) async {
    final harness = await _pumpReader(tester);

    await tester.tap(find.byTooltip('Aumentar tamaño de texto'));
    await tester.pumpAndSettle();

    expect(
      harness.settings.rawSaves,
      [ {AppSettings.keyFontScale: '1.1'} ],
    );
    final text =
        tester.widget<Text>(find.text('First paragraph of A'));
    expect(text.style?.fontSize, closeTo(16 * 1.1, 0.001));
  });

  testWidgets('theme button cycles system → light → dark (RF-13)',
      (tester) async {
    final harness = await _pumpReader(tester);

    expect(find.byIcon(Icons.brightness_auto), findsOneWidget);

    await tester.tap(find.byTooltip('Tema: system (tocar para cambiar)'));
    await tester.pumpAndSettle();

    expect(
      harness.settings.rawSaves,
      [ {AppSettings.keyTheme: 'light'} ],
    );
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });

  testWidgets('shows an error view when the content is missing',
      (tester) async {
    await _pumpReader(tester, documentId: 'missing');

    expect(find.text('No se pudo abrir el documento'), findsOneWidget);
    expect(find.textContaining('Vuelve a la biblioteca'), findsOneWidget);
  });

  testWidgets('shows the scanned-PDF view for unextractable PDFs (C7)',
      (tester) async {
    final documents = FakeDocumentRepository();
    final settings = FakeSettingsRepository();
    documents.documents['s1'] = buildTestDocument('s1', format: DocumentFormat.pdf)
        .copyWith(textExtractable: false);
    documents.contents['s1'] = DocumentContent(
      document: documents.documents['s1']!,
      sections: const [],
      paragraphs: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentRepositoryProvider.overrideWithValue(documents),
          settingsRepositoryProvider.overrideWithValue(settings),
        ],
        child: const MaterialApp(home: ReaderScreen(documentId: 's1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PDF escaneado'), findsOneWidget);
    expect(find.textContaining('parece estar escaneado'), findsOneWidget);
  });
}
