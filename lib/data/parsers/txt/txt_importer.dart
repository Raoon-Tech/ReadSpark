import 'dart:convert';
import 'dart:io';

import 'package:readspark/core/errors/parser_exception.dart';
import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/documents/importers/document_importer.dart';

import '../parsed_content_builder.dart';

/// TXT importer (§17): Dart stdlib only. Detects UTF-8 (with optional BOM),
/// falls back to Latin-1, normalizes `\r\n`/`\r` line endings and splits
/// paragraphs on blank lines. Files are read as a stream so large documents
/// do not load fully into memory (RNF-06).
class TxtImporter implements DocumentImporter {
  const TxtImporter();

  @override
  bool supports(String extension) => extension.toLowerCase() == '.txt';

  @override
  Future<ImportedDocument> importDocument(File file, Document base) async {
    final builder = ParsedContentBuilder(base);
    var paragraph = StringBuffer();

    void flush() {
      if (paragraph.isNotEmpty) {
        builder.addParagraph(paragraph.toString());
        paragraph = StringBuffer();
      }
    }

    Future<void> consume(Stream<String> lines) async {
      await for (final line in lines) {
        final normalized = _stripBom(line);
        if (normalized.trim().isEmpty) {
          flush();
        } else {
          if (paragraph.isNotEmpty) paragraph.write(' ');
          paragraph.write(normalized.trim());
        }
      }
    }

    try {
      try {
        await consume(
          file.openRead().transform(utf8.decoder).transform(const LineSplitter()),
        );
      } on FormatException {
        // Not valid UTF-8: start over with Latin-1 (§17).
        paragraph = StringBuffer();
        await consume(
          file
              .openRead()
              .transform(latin1.decoder)
              .transform(const LineSplitter()),
        );
      }
      flush();
    } on FileSystemException {
      throw ParserException(
        ParserErrorCode.readFailed,
        'No se pudo leer el archivo.',
        technicalDetail: 'txt: ${file.path}',
      );
    }
    return ImportedDocument(content: builder.build());
  }

  static String _stripBom(String line) {
    if (line.startsWith('\uFEFF')) return line.substring(1);
    // Latin-1 decoding of an UTF-8 BOM.
    if (line.startsWith('ï»¿')) return line.substring(3);
    return line;
  }
}
