/// Result of picking a file and copying it into app storage.
class StoredDocumentFile {
  const StoredDocumentFile({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
  });

  /// Absolute path of the stored copy (inside app storage).
  final String path;

  /// Original file name, including its extension.
  final String fileName;

  final int sizeBytes;
}

/// Port for user-facing file operations (§9 `data` implements it).
///
/// The original file in the user's file system is never moved or modified
/// (§4 "Persistencia de archivos"); only a managed copy is created.
abstract interface class DocumentFilePort {
  /// Opens the native picker, validates the extension (RF-01, RF-72) and
  /// copies the file into app storage. Returns `null` if the user cancels.
  /// Throws [ImportException] on validation or I/O errors.
  Future<StoredDocumentFile?> pickAndStore();

  /// Deletes a previously stored copy. Paths outside app storage are
  /// rejected with [ImportException] (anti path-traversal, RF-72).
  Future<void> deleteStoredFile(String path);
}
