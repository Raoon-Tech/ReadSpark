/// Error codes for the document parsers (§13–§17). The [code] is for logs;
/// the [message] is a friendly, user-facing text (RF-73, §29).
enum ParserErrorCode {
  unsupportedFormat('unsupported_format'),
  corruptFile('corrupt_file'),
  emptyFile('empty_file'),
  readFailed('read_failed');

  const ParserErrorCode(this.code);

  /// Loggable, non-localized identifier.
  final String code;
}

/// Typed error raised by document parsers (ADR-007). The import flow
/// cleans up the managed copy before rethrowing so the library never keeps
/// a broken record (CU-01, RF-73).
class ParserException implements Exception {
  const ParserException(this.errorCode, this.message, {this.technicalDetail});

  final ParserErrorCode errorCode;

  /// Friendly message safe to show in the UI.
  final String message;

  /// Technical detail for logs; never shown to the user.
  final String? technicalDetail;

  @override
  String toString() =>
      'ParserException(${errorCode.code}): $message'
      '${technicalDetail == null ? '' : ' ($technicalDetail)'}';
}
