/// Application-wide constants.
abstract final class AppConstants {
  /// Display name of the application.
  static const String appName = 'ReadSpark';

  /// File extensions accepted by the import flow (RF-01) and the
  /// importer registry of Phase 4 (§13).
  static const List<String> supportedExtensions = [
    '.pdf',
    '.docx',
    '.md',
    '.markdown',
    '.txt',
  ];
}
