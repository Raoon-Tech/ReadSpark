import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:readspark/data/database/daos/bookmark_dao.dart';
import 'package:readspark/data/database/daos/document_dao.dart';
import 'package:readspark/data/database/daos/progress_dao.dart';
import 'package:readspark/data/database/daos/settings_dao.dart';
import 'package:readspark/data/database/daos/voice_dao.dart';
import 'package:readspark/data/database/tables.dart';

part 'database.g.dart';

/// SQLite application database (schema v1 — docs/database.md).
///
/// Migrations are versioned (§11): bump [schemaVersion] and add a step via
/// `drift_dev schema steps` for every schema change. Never destructively
/// modify the schema without a migration.
@DriftDatabase(
  tables: [
    Documents,
    DocumentSections,
    DocumentParagraphs,
    ReadingProgress,
    Bookmarks,
    Voices,
    Settings,
  ],
  daos: [
    DocumentDao,
    ProgressDao,
    BookmarkDao,
    SettingsDao,
    VoiceDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Database backed by [file] (application runtime).
  AppDatabase.open(File file) : super(NativeDatabase(file));

  /// In-memory database for tests.
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
