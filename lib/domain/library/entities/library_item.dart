import 'package:readspark/domain/documents/entities/document.dart';

/// Read-model of the library: a [Document] joined with its reading
/// progress (ADR-005 — not a separate table).
class LibraryItem {
  const LibraryItem({
    required this.document,
    this.percentage = 0,
    this.lastReadAt,
  });

  final Document document;

  /// Reading progress in `0.0..1.0`; `0` when the document was never read.
  final double percentage;

  /// When the document was last read; `null` if it has no progress row.
  final DateTime? lastReadAt;

  /// Whether there is a progress row for this document.
  bool get hasProgress => lastReadAt != null;
}
