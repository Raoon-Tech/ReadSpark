import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Well-known locations used by ReadSpark (all under app storage).
abstract final class AppPaths {
  static const String storageFolderName = 'ReadSpark';

  /// Directory holding managed copies of imported files and the database.
  static Future<Directory> storageDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, storageFolderName));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// SQLite database file (schema v1, `docs/database.md`).
  static Future<File> databaseFile() async {
    final dir = await storageDirectory();
    return File(p.join(dir.path, 'readspark.sqlite'));
  }
}
