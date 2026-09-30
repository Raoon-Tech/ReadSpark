import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/data/database/database.dart';

void main() {
  test('in-memory database opens and creates schema v1', () async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);

    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "ORDER BY name",
        )
        .get()
        .then((rows) => rows.map((r) => r.read<String>('name')).toList());

    expect(
      tables,
      containsAll([
        'documents',
        'document_sections',
        'document_paragraphs',
        'reading_progress',
        'bookmarks',
        'voices',
        'settings',
      ]),
    );
  });
}
