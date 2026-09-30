import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/data/parsers/pdf/pdf_structure_builder.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';

import '../../helpers/fakes.dart';

void main() {
  final base = buildTestDocument('p1', format: DocumentFormat.pdf);

  test('builds sections from the outline and pages into paragraphs (§14)',
      () {
    final imported = buildPdfContent(
      base: base,
      pageTexts: [
        'Primer capítulo con texto suficiente.',
        'Segundo capítulo con texto suficiente.',
        'Tercer capítulo con texto suficiente.',
      ],
      outline: const [
        PdfOutlineEntry(title: 'Capítulo 1', pageIndex: 0, depth: 0),
        PdfOutlineEntry(title: 'Capítulo 2', pageIndex: 1, depth: 0),
        PdfOutlineEntry(title: 'Subtema', pageIndex: 2, depth: 1),
      ],
    );

    final content = imported.content;
    expect(imported.warning, isNull);
    expect(content.document.textExtractable, isTrue);
    expect(content.document.totalPages, 3);

    expect(content.sections.map((s) => s.title),
        ['Capítulo 1', 'Capítulo 2', 'Subtema']);
    expect(content.sections.map((s) => s.level), [1, 1, 2]);

    expect(content.paragraphs, hasLength(3));
    expect(content.paragraphs.map((p) => p.pageNumber), [1, 2, 3]);
    expect(content.paragraphs[0].sectionId, content.sections[0].id);
    expect(content.paragraphs[1].sectionId, content.sections[1].id);
    expect(content.paragraphs[2].sectionId, content.sections[2].id);
  });

  test('pages before the first outline entry land in a root section', () {
    final imported = buildPdfContent(
      base: base,
      pageTexts: ['Portada con texto suficiente.', 'Capítulo con texto.'],
      outline: const [
        PdfOutlineEntry(title: 'Capítulo', pageIndex: 1, depth: 0),
      ],
    );

    final content = imported.content;
    expect(content.sections, hasLength(2));
    expect(content.sections[0].title, '');
    expect(content.sections[0].level, 0);
    expect(content.sections[1].title, 'Capítulo');
    expect(content.paragraphs[0].sectionId, content.sections[0].id);
    expect(content.paragraphs[1].sectionId, content.sections[1].id);
  });

  test('merges wrapped lines and splits blank-line blocks', () {
    final imported = buildPdfContent(
      base: base,
      pageTexts: [
        'Una línea que se\nparte en dos.\n\nOtro bloque\ndel PDF.',
      ],
      outline: const [],
    );

    expect(imported.content.paragraphs.map((p) => p.text), [
      'Una línea que se parte en dos.',
      'Otro bloque del PDF.',
    ]);
  });

  test('rejoins words soft-hyphenated across lines', () {
    final imported = buildPdfContent(
      base: base,
      pageTexts: ['inter-\nnacional con texto.'],
      outline: const [],
    );

    expect(imported.content.paragraphs.single.text,
        'internacional con texto.');
  });

  test('detects a scanned PDF: majority of pages without text (C7)', () {
    final imported = buildPdfContent(
      base: base,
      pageTexts: ['', '', ''],
      outline: const [],
    );

    expect(imported.warning, ImportWarning.scannedPdf);
    expect(imported.content.document.textExtractable, isFalse);
    expect(imported.content.paragraphs, isEmpty);
    expect(imported.content.sections, hasLength(1));
    expect(imported.content.document.totalPages, 3);
    expect(imported.content.document.totalCharacters, 0);
  });

  test('a single empty page counts as scanned too', () {
    final imported = buildPdfContent(
      base: base,
      pageTexts: [''],
      outline: const [],
    );

    expect(imported.warning, ImportWarning.scannedPdf);
  });

  test('pages with text keep the document extractable', () {
    final imported = buildPdfContent(
      base: base,
      pageTexts: [
        'Texto real de la primera página.',
        'Texto real de la segunda página.',
        '',
      ],
      outline: const [],
    );

    expect(imported.warning, isNull);
    expect(imported.content.document.textExtractable, isTrue);
    expect(imported.content.paragraphs, hasLength(2));
  });

  test('sorts outline entries by page and drops out-of-range ones', () {
    final imported = buildPdfContent(
      base: base,
      pageTexts: ['Página con texto suficiente.'],
      outline: const [
        PdfOutlineEntry(title: 'Lejano', pageIndex: 99, depth: 0),
        PdfOutlineEntry(title: 'Único', pageIndex: 0, depth: 0),
      ],
    );

    final content = imported.content;
    expect(content.sections.single.title, 'Único');
  });
}
