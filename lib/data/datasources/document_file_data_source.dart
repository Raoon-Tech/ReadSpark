import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'package:readspark/core/constants/app_constants.dart';
import 'package:readspark/core/errors/import_exception.dart';
import 'package:readspark/data/datasources/app_paths.dart';
import 'package:readspark/domain/documents/repositories/document_file_port.dart';

/// Native file picking + managed copies of imported documents (RF-01,
/// RF-72). The user's original file is never moved or modified.
class DocumentFileDataSource implements DocumentFilePort {
  DocumentFileDataSource({Future<Directory> Function()? storage})
      : _storage = storage ?? AppPaths.storageDirectory;

  final Future<Directory> Function() _storage;

  @override
  Future<StoredDocumentFile?> pickAndStore() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        for (final extension in AppConstants.supportedExtensions)
          extension.substring(1),
      ],
    );
    if (picked.isEmpty) return null;

    final file = picked.single;
    final sourcePath = file.path;
    if (sourcePath == null) {
      throw const ImportException(
        ImportErrorCode.pickFailed,
        'No se pudo acceder al archivo seleccionado.',
      );
    }
    if (!AppConstants.supportedExtensions.contains(
      p.extension(file.name).toLowerCase(),
    )) {
      throw const ImportException(
        ImportErrorCode.unsupportedExtension,
        'Formato no soportado. Usa PDF, DOCX, Markdown o TXT.',
      );
    }
    final sourceSize = await _lengthOf(file);
    if (sourceSize != null && sourceSize > AppConstants.maxImportSizeBytes) {
      throw ImportException(
        ImportErrorCode.fileTooLarge,
        'El archivo supera el límite de '
        '${AppConstants.maxImportSizeBytes ~/ (1024 * 1024)} MB.',
      );
    }
    if (!File(sourcePath).existsSync()) {
      throw const ImportException(
        ImportErrorCode.readFailed,
        'No se pudo leer el archivo seleccionado.',
      );
    }

    try {
      final directory = await _storage();
      final target = await _uniqueTarget(directory, file.name);
      final copied = await File(sourcePath).copy(target.path);
      final size = await copied.length();
      return StoredDocumentFile(
        path: copied.path,
        fileName: file.name,
        sizeBytes: size,
      );
    } on FileSystemException {
      throw const ImportException(
        ImportErrorCode.copyFailed,
        'No se pudo guardar una copia del archivo.',
      );
    }
  }

  @override
  Future<void> deleteStoredFile(String path) async {
    final directory = await _storage();
    final normalized = p.normalize(p.absolute(path));
    if (!p.isWithin(directory.path, normalized) &&
        !p.equals(directory.path, normalized)) {
      throw const ImportException(
        ImportErrorCode.invalidPath,
        'Ruta fuera del almacenamiento de la aplicación.',
      );
    }

    final file = File(normalized);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Best-effort source size for the pre-copy limit check (§25); `null`
  /// when the platform cannot report it without reading the file.
  Future<int?> _lengthOf(PlatformFile file) async {
    try {
      return await file.xFile.length();
    } catch (_) {
      return null;
    }
  }

  /// Copies to a non-existing target, appending `-1`, `-2`, ... on clashes.
  Future<File> _uniqueTarget(Directory directory, String fileName) async {
    final sanitized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    var candidate = File(p.join(directory.path, sanitized));
    var counter = 1;
    while (await candidate.exists()) {
      final name = p.basenameWithoutExtension(sanitized);
      final extension = p.extension(sanitized);
      candidate = File(p.join(directory.path, '$name-$counter$extension'));
      counter++;
    }
    return candidate;
  }
}
