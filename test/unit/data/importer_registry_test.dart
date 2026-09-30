import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/data/parsers/docx/docx_importer.dart';
import 'package:readspark/data/parsers/markdown/markdown_importer.dart';
import 'package:readspark/data/parsers/pdf/pdf_importer.dart';
import 'package:readspark/data/parsers/txt/txt_importer.dart';
import 'package:readspark/domain/documents/importers/importer_registry.dart';

void main() {
  final registry = ImporterRegistry(const [
    PdfImporter(),
    DocxImporter(),
    MarkdownImporter(),
    TxtImporter(),
  ]);

  test('resolves every supported extension (ADR-007)', () {
    expect(registry.resolve('.pdf'), isA<PdfImporter>());
    expect(registry.resolve('.docx'), isA<DocxImporter>());
    expect(registry.resolve('.md'), isA<MarkdownImporter>());
    expect(registry.resolve('.markdown'), isA<MarkdownImporter>());
    expect(registry.resolve('.txt'), isA<TxtImporter>());
  });

  test('is case-insensitive', () {
    expect(registry.resolve('.PDF'), isA<PdfImporter>());
    expect(registry.resolve('.DocX'), isA<DocxImporter>());
  });

  test('throws a friendly ParserException for unknown extensions', () {
    expect(
      () => registry.resolve('.epub'),
      throwsA(
        isA<ParserException>().having(
          (e) => e.errorCode,
          'errorCode',
          ParserErrorCode.unsupportedFormat,
        ),
      ),
    );
  });
}
