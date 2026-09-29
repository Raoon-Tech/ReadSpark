import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/repositories/settings_repository_impl.dart';
import 'package:readspark/domain/settings/entities/app_settings.dart';
import 'package:readspark/domain/settings/repositories/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = AppDatabase.inMemory();
    repo = SettingsRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('empty database loads defaults', () async {
    final settings = await repo.load();

    expect(settings.ttsVoiceId, isNull);
    expect(settings.ttsRate, 1.0);
    expect(settings.ttsPitch, 1.0);
    expect(settings.theme, 'system');
    expect(settings.fontScale, 1.0);
    expect(settings.speakCode, isFalse);
  });

  test('save + load roundtrips every setting', () async {
    const settings = AppSettings(
      ttsVoiceId: 'voice-1',
      ttsLanguage: 'es-ES',
      ttsRate: 1.5,
      ttsPitch: 0.8,
      theme: 'dark',
      fontScale: 1.25,
      speakCode: true,
      speakUrls: true,
      speakSymbols: true,
    );

    await repo.save(settings);
    final loaded = await repo.load();

    expect(loaded.ttsVoiceId, 'voice-1');
    expect(loaded.ttsLanguage, 'es-ES');
    expect(loaded.ttsRate, 1.5);
    expect(loaded.ttsPitch, 0.8);
    expect(loaded.theme, 'dark');
    expect(loaded.fontScale, 1.25);
    expect(loaded.speakCode, isTrue);
    expect(loaded.speakUrls, isTrue);
    expect(loaded.speakSymbols, isTrue);
  });

  test('re-saving updates keys without duplicating rows', () async {
    await repo.save(const AppSettings(theme: 'light'));
    await repo.save(const AppSettings(theme: 'dark'));

    // Every save serializes the full default key set (null voice keys are
    // omitted): 7 rows, upserted by primary key.
    final rows = await db
        .customSelect('SELECT COUNT(*) AS c FROM settings')
        .getSingle();
    expect(rows.read<int>('c'), 7);
    expect((await repo.load()).theme, 'dark');
  });

  test('getAll returns raw key-value pairs', () async {
    await repo.setAll({'custom_key': 'custom_value'});

    expect(await repo.getAll(), {'custom_key': 'custom_value'});
  });
}
