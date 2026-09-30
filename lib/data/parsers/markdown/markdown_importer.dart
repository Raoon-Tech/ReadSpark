import 'dart:io';

import 'package:markdown/markdown.dart' as md;

import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';

import '../parsed_content_builder.dart';

/// Markdown importer (§16): `package:markdown` AST → sections by headings,
/// paragraphs with inline syntax noise removed for reading/TTS (§16:
/// backticks, `#`, `[]()`, `**`). GitHub extensions: tables,
/// strikethrough, autolinks.
class MarkdownImporter implements DocumentImporter {
  const MarkdownImporter();

  static final _extensions = md.ExtensionSet.gitHubWeb;

  @override
  bool supports(String extension) {
    final normalized = extension.toLowerCase();
    return normalized == '.md' || normalized == '.markdown';
  }

  @override
  Future<ImportedDocument> importDocument(File file, Document base) async {
    final String source;
    try {
      source = await file.readAsString();
    } on FileSystemException {
      throw const ParserException(
        ParserErrorCode.readFailed,
        'No se pudo leer el archivo.',
      );
    } on FormatException {
      throw const ParserException(
        ParserErrorCode.corruptFile,
        'El archivo Markdown no es texto válido UTF-8.',
      );
    }

    final builder = ParsedContentBuilder(base);
    final nodes = md.Document(extensionSet: _extensions).parse(source);
    _walkBlocks(nodes, builder);
    return ImportedDocument(content: builder.build());
  }

  void _walkBlocks(List<md.Node> nodes, ParsedContentBuilder builder) {
    for (final node in nodes) {
      if (node is! md.Element) continue;
      final tag = node.tag;
      if (_isHeading(tag)) {
        builder.startSection(
          title: _inlineText(node),
          level: int.parse(tag.substring(1)),
        );
      } else if (tag == 'p') {
        builder.addParagraph(_inlineText(node));
      } else if (tag == 'ul' || tag == 'ol') {
        _addListItems(node, builder, ordered: tag == 'ol');
      } else if (tag == 'pre') {
        builder.addParagraph(node.textContent);
      } else if (tag == 'blockquote') {
        _walkBlocks(node.children ?? const [], builder);
      } else if (tag == 'table') {
        _addTableRows(node, builder);
      } else if (tag == 'hr' || tag == 'heading') {
        // Horizontal rules and raw heading extensions carry no content.
      } else if (node.children != null && node.children!.isNotEmpty) {
        // Unknown block (nested wrapper): recurse into block children, or
        // treat as a paragraph when it only holds inline content.
        final children = node.children!;
        final hasBlockChildren =
            children.whereType<md.Element>().any((child) => _isBlock(child.tag));
        if (hasBlockChildren) {
          _walkBlocks(children, builder);
        } else {
          builder.addParagraph(_inlineText(node));
        }
      }
    }
  }

  void _addListItems(md.Element list, ParsedContentBuilder builder,
      {required bool ordered}) {
    var index = 1;
    for (final child in list.children ?? const <md.Node>[]) {
      if (child is! md.Element || child.tag != 'li') continue;
      final text = StringBuffer();
      final nestedLists = <md.Element>[];
      for (final item in child.children ?? const <md.Node>[]) {
        if (item is md.Element && (item.tag == 'ul' || item.tag == 'ol')) {
          // Nested lists are emitted after their parent item.
          nestedLists.add(item);
          continue;
        }
        final inline = _inlineText(item).trim();
        if (inline.isEmpty) continue;
        if (text.isNotEmpty) text.write(' ');
        text.write(inline);
      }
      final content = text.toString().trim();
      if (content.isNotEmpty) {
        builder.addParagraph(ordered ? '$index. $content' : '• $content');
        index++;
      }
      for (final nested in nestedLists) {
        _walkBlocks([nested], builder);
      }
    }
  }

  void _addTableRows(md.Element table, ParsedContentBuilder builder) {
    for (final row in _descendantsWhere(table, (tag) => tag == 'tr')) {
      final cells = <String>[];
      for (final cell in row.children ?? const <md.Node>[]) {
        if (cell is! md.Element) continue;
        if (cell.tag != 'th' && cell.tag != 'td') continue;
        final text = _inlineText(cell).trim();
        if (text.isNotEmpty) cells.add(text);
      }
      if (cells.isNotEmpty) builder.addParagraph(cells.join(' | '));
    }
  }

  /// Depth-first collection of [md.Element]s matching [tagPredicate]
  /// (`md.Element` has no descendants accessor).
  List<md.Element> _descendantsWhere(
    md.Node root,
    bool Function(String tag) tagPredicate,
  ) {
    final matches = <md.Element>[];
    void visit(md.Node node) {
      if (node is! md.Element) return;
      if (tagPredicate(node.tag)) matches.add(node);
      for (final child in node.children ?? const <md.Node>[]) {
        visit(child);
      }
    }

    visit(root);
    return matches;
  }

  /// Renders inline content as plain reading text: links keep their label,
  /// emphasis/strong/del/code markers are dropped (§16 TTS normalization).
  String _inlineText(md.Node node) {
    if (node is md.Text) return node.text;
    if (node is! md.Element) return node.textContent;
    final tag = node.tag;
    if (tag == 'br') return '\n';
    if (tag == 'img') return node.attributes['alt'] ?? '';
    final children = node.children ?? const <md.Node>[];
    return children.map(_inlineText).join();
  }

  static bool _isHeading(String tag) =>
      tag.length == 2 && tag.startsWith('h') && _digit.contains(tag[1]);

  static const _digit = '1234567';

  static bool _isBlock(String tag) =>
      tag == 'p' ||
      _isHeading(tag) ||
      tag == 'ul' ||
      tag == 'ol' ||
      tag == 'pre' ||
      tag == 'blockquote' ||
      tag == 'table' ||
      tag == 'hr';
}
