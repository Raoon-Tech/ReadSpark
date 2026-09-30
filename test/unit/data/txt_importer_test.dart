import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/data/parsers/txt/txt_importer.dart';

import '../../helpers/fakes.dart';

void main() {
  late Directory tempDir;
  final importer = TxtImporter();
  final base = buildTestDocument('t1', format: DocumentFormat.txt);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('readspark_txt');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<File> write(String name, List<int> bytes) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  test('splits paragraphs on blank lines and joins wrapped lines (§17)',
      () async {
    final file = await write(
      'a.txt',
      utf8.encode('Primera línea que\nsigue.\n\nSegunda parágrafo.'),
    );

    final imported = await importer.importDocument(file, base);

    final content = imported.content;
    expect(content.sections.single.level, 0);
    expect(content.sections.single.title, '');
    expect(content.paragraphs, hasLength(2));
    expect(content.paragraphs[0].text, 'Primera línea que sigue.');
    expect(content.paragraphs[1].text, 'Segunda parágrafo.');
    expect(content.document.totalCharacters,
        content.paragraphs.fold<int>(0, (s, p) => s + p.text.length));
  });

  test('handles UTF-8 with BOM and CRLF line endings', () async {
    final file = await write(
      'b.txt',
      [0xEF, 0xBB, 0xBF, ...utf8.encode('Hola\r\nMundo\r\n\r\nÁrea é ñ.')],
    );

    final imported = await importer.importDocument(file, base);

    expect(imported.content.paragraphs, hasLength(2));
    expect(imported.content.paragraphs[0].text, 'Hola Mundo');
    expect(imported.content.paragraphs[1].text, 'Área é ñ.');
  });

  test('falls back to Latin-1 when the bytes are not UTF-8 (§17)', () async {
    // 0xE9 = 'é' in Latin-1; invalid as UTF-8.
    final file = await write('latin.txt', [0x63, 0x61, 0x66, 0xE9]);

    final imported = await importer.importDocument(file, base);

    expect(imported.content.paragraphs.single.text, 'café');
  });

  test('imports an empty file as a root section without paragraphs',
      () async {
    final file = await write('empty.txt', utf8.encode(''));

    final imported = await importer.importDocument(file, base);

    expect(imported.content.sections, hasLength(1));
    expect(imported.content.paragraphs, isEmpty);
    expect(imported.content.document.totalCharacters, 0);
  });

  test('supports CR-only line endings', () async {
    final file = await write('cr.txt', utf8.encode('uno\rdos\r\r tres'));

    final imported = await importer.importDocument(file, base);

    expect(imported.content.paragraphs.map((p) => p.text),
        ['uno dos', 'tres']);
  });

  test('throws a friendly ParserException when the file is missing', () async {
    final missing = File('${tempDir.path}${Platform.pathSeparator}no.txt');

    await expectLater(
      importer.importDocument(missing, base),
      throwsA(
        isA<ParserException>().having(
          (e) => e.errorCode,
          'errorCode',
          ParserErrorCode.readFailed,
        ),
      ),
    );
  });
}
