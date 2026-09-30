import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/data/parsers/docx/docx_importer.dart';

import '../../helpers/fakes.dart';

const _documentXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Capítulo uno</w:t></w:r></w:p>
    <w:p><w:r><w:t>Intro del capítulo.</w:t></w:r></w:p>
    <w:p><w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr><w:r><w:t>Primer ítem</w:t></w:r></w:p>
    <w:p><w:pPr><w:outlineLvl w:val="1"/></w:pPr><w:r><w:t>Subtítulo</w:t></w:r></w:p>
    <w:tbl><w:tr><w:tc><w:p><w:r><w:t>Celda A</w:t></w:r></w:p></w:tc><w:tc><w:p><w:r><w:t>Celda B</w:t></w:r></w:p></w:tc></w:tr></w:tbl>
  </w:body>
</w:document>
''';

const _coreXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties
    xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
    xmlns:dc="http://purl.org/dc/elements/1.1/">
  <dc:creator>Gabriel García Márquez</dc:creator>
</cp:coreProperties>
''';

void main() {
  late Directory tempDir;
  final importer = DocxImporter();
  final base = buildTestDocument('x1', format: DocumentFormat.docx);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('readspark_docx');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<File> writeDocx({String? documentXml, bool includeCore = true}) async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile.bytes(
        'word/document.xml',
        utf8.encode(documentXml ?? _documentXml),
      ),
    );
    if (includeCore) {
      archive.addFile(
        ArchiveFile.bytes('docProps/core.xml', utf8.encode(_coreXml)),
      );
    }
    final file = File('${tempDir.path}${Platform.pathSeparator}doc.docx');
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
    return file;
  }

  test('extracts headings, paragraphs, list items and tables (§15)',
      () async {
    final file = await writeDocx();

    final imported = await importer.importDocument(file, base);
    final content = imported.content;

    expect(content.document.author, 'Gabriel García Márquez');
    expect(content.sections, hasLength(2));
    expect(content.sections[0].title, 'Capítulo uno');
    expect(content.sections[0].level, 1);
    expect(content.sections[1].title, 'Subtítulo');
    expect(content.sections[1].level, 2);

    expect(content.paragraphs.map((p) => p.text), [
      'Intro del capítulo.',
      '• Primer ítem',
      'Celda A',
      'Celda B',
    ]);
    expect(content.paragraphs[0].sectionId, content.sections[0].id);
    expect(content.paragraphs.every((p) => p.pageNumber == null), isTrue);
    expect(content.document.totalPages, isNull);
  });

  test('falls back to HeadingN styles and computes total characters',
      () async {
    final file = await writeDocx(
      documentXml: '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:pPr><w:pStyle w:val="heading 2"/></w:pPr><w:r><w:t>Título</w:t></w:r></w:p>
    <w:p><w:r><w:t>Texto</w:t></w:r></w:p>
  </w:body>
</w:document>
''',
      includeCore: false,
    );

    final imported = await importer.importDocument(file, base);

    expect(imported.content.sections.single.title, 'Título');
    expect(imported.content.sections.single.level, 2);
    expect(imported.content.document.author, isNull);
    expect(imported.content.document.totalCharacters,
        'Texto'.length);
  });

  test('rejects files that are not valid ZIP archives (RF-73)', () async {
    final file = File('${tempDir.path}${Platform.pathSeparator}bad.docx');
    await file.writeAsBytes(utf8.encode('esto no es un zip'), flush: true);

    await expectLater(
      importer.importDocument(file, base),
      throwsA(
        isA<ParserException>().having(
          (e) => e.errorCode,
          'errorCode',
          ParserErrorCode.corruptFile,
        ),
      ),
    );
  });

  test('rejects archives without word/document.xml (RF-73)', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('foo.txt', utf8.encode('x')));
    final file = File('${tempDir.path}${Platform.pathSeparator}no.docx');
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);

    await expectLater(
      importer.importDocument(file, base),
      throwsA(isA<ParserException>()),
    );
  });
}
