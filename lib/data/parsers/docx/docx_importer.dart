import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';

import '../parsed_content_builder.dart';

/// DOCX importer (§15): unzips with `archive`, parses `word/document.xml`
/// with `xml`, and maps `Heading1..N` styles / outline levels to sections,
/// keeping the semantic reading order (headings, paragraphs, list items,
/// table rows). `docProps/core.xml` provides the author. No stable pages →
/// `pageNumber = null`.
class DocxImporter implements DocumentImporter {
  const DocxImporter();

  @override
  bool supports(String extension) => extension.toLowerCase() == '.docx';

  @override
  Future<ImportedDocument> importDocument(File file, Document base) async {
    final Archive archive;
    final List<int> documentXml;
    List<int>? coreXml;
    try {
      final bytes = await file.readAsBytes();
      archive = ZipDecoder().decodeBytes(bytes);
      documentXml = _requiredBytes(archive, 'word/document.xml');
      coreXml = _optionalBytes(archive, 'docProps/core.xml');
    } on ArchiveException {
      throw const ParserException(
        ParserErrorCode.corruptFile,
        'El archivo DOCX está dañado o no es un ZIP válido.',
      );
    } on FileSystemException {
      throw const ParserException(
        ParserErrorCode.readFailed,
        'No se pudo leer el archivo.',
      );
    }

    final XmlElement document;
    try {
      document = XmlDocument.parse(
        utf8.decode(documentXml, allowMalformed: true),
      ).rootElement;
    } on XmlException {
      throw const ParserException(
        ParserErrorCode.corruptFile,
        'El contenido del DOCX no se pudo interpretar.',
      );
    }

    final builder = ParsedContentBuilder(base)
      ..author = _authorOf(coreXml);

    // All <w:p> in document order (paragraphs and table cell paragraphs).
    final paragraphs = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'p')
        .toList(growable: false);

    for (final paragraph in paragraphs) {
      final headingLevel = _headingLevelOf(paragraph);
      final text = _textOf(paragraph);
      if (headingLevel != null) {
        builder.startSection(title: text, level: headingLevel);
      } else if (text.isNotEmpty) {
        final prefix = _isListItem(paragraph) ? '• ' : '';
        builder.addParagraph('$prefix$text');
      }
    }

    return ImportedDocument(content: builder.build());
  }

  /// Heading level `1..6`, or `null` when the paragraph is not a heading.
  /// Detected via `w:outlineLvl` (preferred) or `w:pStyle` Heading1..6.
  int? _headingLevelOf(XmlElement paragraph) {
    final pPr = _child(paragraph, 'pPr');
    if (pPr == null) return null;
    final outlineRaw = _attribute(_child(pPr, 'outlineLvl'), 'val');
    if (outlineRaw != null) {
      final level = int.tryParse(outlineRaw.trim());
      // outlineLvl is 0-based (0 = top level); 9 means "body text".
      if (level != null && level >= 0 && level <= 5) return level + 1;
    }
    final styleRaw = _attribute(_child(pPr, 'pStyle'), 'val');
    if (styleRaw == null) return null;
    final match = RegExp(r'^heading\s*([1-6])$', caseSensitive: false)
        .firstMatch(styleRaw.trim());
    return match == null ? null : int.parse(match.group(1)!);
  }

  bool _isListItem(XmlElement paragraph) {
    final pPr = _child(paragraph, 'pPr');
    return pPr != null && _child(pPr, 'numPr') != null;
  }

  /// Concatenates run text with tabs/newlines mapped for reading (§15).
  String _textOf(XmlElement paragraph) {
    final buffer = StringBuffer();
    for (final node in paragraph.descendants) {
      if (node is! XmlElement) continue;
      switch (node.name.local) {
        case 't':
          buffer.write(node.innerText);
        case 'tab':
          buffer.write(' ');
        case 'br':
          buffer.write('\n');
      }
    }
    return buffer.toString().replaceAll('\n', ' ').trim();
  }

  String? _authorOf(List<int>? coreXml) {
    if (coreXml == null) return null;
    try {
      final root = XmlDocument.parse(
        utf8.decode(coreXml, allowMalformed: true),
      ).rootElement;
      for (final element in root.descendants.whereType<XmlElement>()) {
        if (element.name.local == 'creator') {
          final value = element.innerText.trim();
          if (value.isNotEmpty) return value;
        }
      }
    } on XmlException {
      // Metadata is optional; ignore malformed core.xml.
    }
    return null;
  }

  static XmlElement? _child(XmlElement parent, String localName) {
    for (final child in parent.childElements) {
      if (child.name.local == localName) return child;
    }
    return null;
  }

  static String? _attribute(XmlElement? element, String localName) {
    if (element == null) return null;
    for (final attribute in element.attributes) {
      if (attribute.name.local == localName) return attribute.value;
    }
    return null;
  }

  static List<int> _requiredBytes(Archive archive, String name) {
    final entry = archive.findFile(name);
    if (entry == null) {
      throw const ParserException(
        ParserErrorCode.corruptFile,
        'El archivo DOCX está incompleto.',
      );
    }
    return entry.content;
  }

  static List<int>? _optionalBytes(Archive archive, String name) =>
      archive.findFile(name)?.content;
}
