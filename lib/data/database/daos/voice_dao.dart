import 'package:drift/drift.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/database/tables.dart';

part 'voice_dao.g.dart';

/// Data access for the device voice cache (ADR-004).
@DriftAccessor(tables: [Voices])
class VoiceDao extends DatabaseAccessor<AppDatabase> with _$VoiceDaoMixin {
  VoiceDao(super.attachedDatabase);

  /// Replaces every cached voice of [platform] with [rows].
  Future<void> replaceForPlatform(
    String platform,
    List<VoicesCompanion> rows,
  ) =>
      transaction(() async {
        await (delete(voices)..where((t) => t.platform.equals(platform))).go();
        await batch((b) => b.insertAll(voices, rows));
      });

  Future<List<VoiceRow>> getAll({String? platform}) async {
    final query = select(voices);
    if (platform != null) {
      query.where((t) => t.platform.equals(platform));
    }
    query.orderBy([(t) => OrderingTerm(expression: t.locale)]);
    return query.get();
  }
}
