import 'package:drift/drift.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/database/tables.dart';

part 'settings_dao.g.dart';

/// Data access for the settings key-value table.
@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Future<String?> get(String key) async {
    final row = await (select(settings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<Map<String, String>> getAll() async {
    final rows = await select(settings).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<void> setAll(Map<String, String> values, DateTime updatedAt) =>
      batch((b) {
        for (final entry in values.entries) {
          b.insert(
            settings,
            SettingsCompanion.insert(
              key: entry.key,
              value: entry.value,
              updatedAt: updatedAt,
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
}
