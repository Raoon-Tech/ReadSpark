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

  /// Maximum accepted size for an import (§25 "límite de tamaño"; the plan
  /// does not specify a value, 100 MB is the project decision, RNF-06).
  static const int maxImportSizeBytes = 100 * 1024 * 1024;
}
