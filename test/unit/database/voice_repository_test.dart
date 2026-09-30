import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/repositories/voice_repository_impl.dart';
import 'package:readspark/domain/voices/entities/voice.dart';
import 'package:readspark/domain/voices/repositories/voice_repository.dart';

Voice _voice(String id, {String platform = 'android', bool isDefault = false}) {
  return Voice(
    id: id,
    name: 'Voice $id',
    locale: 'es-ES',
    platform: platform,
    provider: 'system',
    isDefault: isDefault,
  );
}

void main() {
  late AppDatabase db;
  late VoiceRepository repo;

  setUp(() {
    db = AppDatabase.inMemory();
    repo = VoiceRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('replaceForPlatform stores voices and getAll returns them', () async {
    await repo.replaceForPlatform('android', [_voice('v1'), _voice('v2')]);

    final voices = await repo.getAll(platform: 'android');
    expect(voices, hasLength(2));
    expect(voices.map((v) => v.id), containsAll(['v1', 'v2']));
    expect(voices.first.platform, 'android');
  });

  test('replaceForPlatform replaces the previous cache for that platform',
      () async {
    await repo.replaceForPlatform('android', [_voice('old')]);
    await repo.replaceForPlatform('android', [_voice('new')]);

    final voices = await repo.getAll(platform: 'android');
    expect(voices, hasLength(1));
    expect(voices.single.id, 'new');
  });

  test('platform caches are independent', () async {
    await repo.replaceForPlatform('android', [_voice('a1')]);
    await repo.replaceForPlatform('windows', [
      _voice('w1', platform: 'windows'),
    ]);

    expect(await repo.getAll(platform: 'android'), hasLength(1));
    expect(await repo.getAll(platform: 'windows'), hasLength(1));
    expect(await repo.getAll(), hasLength(2));
  });

  test('default flag roundtrips', () async {
    await repo.replaceForPlatform('android', [
      _voice('v1', isDefault: true),
    ]);

    final voices = await repo.getAll(platform: 'android');
    expect(voices.single.isDefault, isTrue);
  });
}
