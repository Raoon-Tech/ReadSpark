/// Error codes for the import flow. The [code] is for logs; the
/// [message] is a friendly, user-facing text (RF-73, §29).
enum ImportErrorCode {
  unsupportedExtension('unsupported_extension'),
  pickFailed('pick_failed'),
  readFailed('read_failed'),
  copyFailed('copy_failed'),
  invalidPath('invalid_path');

  const ImportErrorCode(this.code);

  /// Loggable, non-localized identifier.
  final String code;
}

/// Typed error raised by the import/delete-file flow (§29).
class ImportException implements Exception {
  const ImportException(this.errorCode, this.message);

  final ImportErrorCode errorCode;

  /// Friendly message safe to show in the UI.
  final String message;

  @override
  String toString() => 'ImportException(${errorCode.code}): $message';
}
