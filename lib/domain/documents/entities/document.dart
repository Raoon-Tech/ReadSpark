/// Document formats supported by the MVP (§13 of the master plan).
enum DocumentFormat {
  pdf('pdf'),
  docx('docx'),
  markdown('markdown'),
  txt('txt');

  const DocumentFormat(this.storageValue);

  /// Value persisted in the `documents.format` column.
  final String storageValue;

  /// Parses a stored value; returns `null` for unknown formats.
  static DocumentFormat? tryParse(String raw) {
    for (final format in values) {
      if (format.storageValue == raw) return format;
    }
    return null;
  }

  /// Maps a file extension (with dot) to its format, or `null`.
  static DocumentFormat? fromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return DocumentFormat.pdf;
      case '.docx':
        return DocumentFormat.docx;
      case '.md':
      case '.markdown':
        return DocumentFormat.markdown;
      case '.txt':
        return DocumentFormat.txt;
      default:
        return null;
    }
  }
}

/// Aggregate root of the document model (ADR-001): a document imported from
/// the file system, identified independently of its format.
class Document {
  const Document({
    required this.id,
    required this.title,
    required this.format,
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    required this.addedAt,
    this.author,
    this.lastOpenedAt,
    this.totalPages,
    this.totalCharacters = 0,
    this.isFavorite = false,
    this.textExtractable = true,
  });

  final String id;
  final String title;
  final String? author;
  final DocumentFormat format;
  final String filePath;
  final int fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOpenedAt;
  final int? totalPages;
  final int totalCharacters;
  final bool isFavorite;
  final DateTime addedAt;
  final bool textExtractable;

  Document copyWith({
    String? title,
    String? author,
    DateTime? updatedAt,
    DateTime? lastOpenedAt,
    int? totalPages,
    int? totalCharacters,
    bool? isFavorite,
    bool? textExtractable,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      format: format,
      filePath: filePath,
      fileSize: fileSize,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      totalPages: totalPages ?? this.totalPages,
      totalCharacters: totalCharacters ?? this.totalCharacters,
      isFavorite: isFavorite ?? this.isFavorite,
      addedAt: addedAt,
      textExtractable: textExtractable ?? this.textExtractable,
    );
  }
}

/// Hierarchical block of a document (chapters/headings). `level` 0 is the
/// root; 1..6 map to heading depth.
class DocumentSection {
  const DocumentSection({
    required this.id,
    required this.documentId,
    required this.title,
    required this.order,
    required this.level,
  });

  final String id;
  final String documentId;
  final String title;
  final int order;
  final int level;
}

/// Reading unit of a document. Progress is stored at this level plus a
/// character offset (§12).
class DocumentParagraph {
  const DocumentParagraph({
    required this.id,
    required this.documentId,
    required this.sectionId,
    required this.order,
    required this.text,
    this.pageNumber,
  });

  final String id;
  final String documentId;
  final String sectionId;
  final int order;
  final String text;

  /// Auxiliary data only; `null` for docx/markdown/txt (§12).
  final int? pageNumber;
}

/// Aggregate returned by importers: document + sections + paragraphs.
/// This *is* the "DocumentModel" of §3.3 — there is no parallel structure
/// (ADR-001).
class DocumentContent {
  const DocumentContent({
    required this.document,
    required this.sections,
    required this.paragraphs,
  });

  final Document document;
  final List<DocumentSection> sections;
  final List<DocumentParagraph> paragraphs;
}
