import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/data/parsers/markdown/markdown_importer.dart';
import 'package:readspark/domain/documents/entities/document.dart';

import '../../helpers/fakes.dart';

void main() {
  late Directory tempDir;
  final importer = MarkdownImporter();
  final base = buildTestDocument('m1', format: DocumentFormat.markdown);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('readspark_md');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<dynamic> parse(String source) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}doc.md');
    await file.writeAsString(source, flush: true);
    return importer.importDocument(file, base);
  }

  test('headings become sections with their depth (§16)', () async {
    final imported = await parse('''
Intro previa.

# Capítulo

Párrafo uno.

## Subsección

Párrafo dos.
''');

    final content = imported.content;
    expect(content.sections, hasLength(3));
    expect(content.sections[0].title, '');
    expect(content.sections[0].level, 0);
    expect(content.sections[1].title, 'Capítulo');
    expect(content.sections[1].level, 1);
    expect(content.sections[2].title, 'Subsección');
    expect(content.sections[2].level, 2);
    expect(content.paragraphs.map((p) => p.text), [
      'Intro previa.',
      'Párrafo uno.',
      'Párrafo dos.',
    ]);
    expect(content.paragraphs[0].sectionId, content.sections[0].id);
    expect(content.paragraphs[1].sectionId, content.sections[1].id);
    expect(content.paragraphs[2].sectionId, content.sections[2].id);
  });

  test('strips inline syntax noise for reading/TTS (§16)', () async {
    final imported = await parse(
      'Un **enfatizado**, *itálico*, `código` y '
      '[etiqueta](https://ejemplo.com).',
    );

    final text = imported.content.paragraphs.single.text;
    expect(text, contains('enfatizado'));
    expect(text, isNot(contains('**')));
    expect(text, isNot(contains('`')));
    expect(text, isNot(contains('](')));
    expect(text, contains('etiqueta'));
    expect(text, isNot(contains('https://ejemplo.com')));
  });

  test('lists become prefixed paragraphs (§16)', () async {
    final imported = await parse('''
- uno
- dos

1. primero
2. segundo
''');

    expect(imported.content.paragraphs.map((p) => p.text), [
      '• uno',
      '• dos',
      '1. primero',
      '2. segundo',
    ]);
  });

  test('code blocks and blockquotes keep their text', () async {
    final imported = await parse('''
> Cita textual.

```dart
void main() {}
```
''');

    expect(imported.content.paragraphs.map((p) => p.text), [
      'Cita textual.',
      'void main() {}',
    ]);
  });

  test('tables render as pipe-joined rows (GitHub extensions)', () async {
    final imported = await parse('''
| A | B |
|---|---|
| 1 | 2 |
''');

    expect(imported.content.paragraphs.map((p) => p.text), [
      'A | B',
      '1 | 2',
    ]);
  });

  test('nested list items are not duplicated into the parent item',
      () async {
    final imported = await parse('''
- padre
  - hijo
''');

    expect(imported.content.paragraphs.map((p) => p.text), [
      '• padre',
      '• hijo',
    ]);
  });
}
