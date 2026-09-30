import 'package:drift/drift.dart';

import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/database/daos/voice_dao.dart';
import 'package:readspark/domain/voices/entities/voice.dart';
import 'package:readspark/domain/voices/repositories/voice_repository.dart';

/// Drift implementation of [VoiceRepository].
class VoiceRepositoryImpl implements VoiceRepository {
  VoiceRepositoryImpl(AppDatabase db) : _dao = db.voiceDao;

  final VoiceDao _dao;

  @override
  Future<void> replaceForPlatform(String platform, List<Voice> voices) =>
      _dao.replaceForPlatform(
        platform,
        [
          for (final voice in voices)
            VoicesCompanion.insert(
              id: voice.id,
              name: voice.name,
              locale: voice.locale,
              provider: Value(voice.provider),
              platform: platform,
              isDefault: Value(voice.isDefault),
              lastSyncAt: Value(voice.lastSyncAt ?? DateTime.now()),
            ),
        ],
      );

  @override
  Future<List<Voice>> getAll({String? platform}) async {
    final rows = await _dao.getAll(platform: platform);
    return [
      for (final row in rows)
        Voice(
          id: row.id,
          name: row.name,
          locale: row.locale,
          platform: row.platform,
          provider: row.provider,
          isDefault: row.isDefault,
          lastSyncAt: row.lastSyncAt,
        ),
    ];
  }
}
