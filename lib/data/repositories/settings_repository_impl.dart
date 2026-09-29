import 'package:readspark/data/database/database.dart';
import 'package:readspark/data/database/daos/settings_dao.dart';
import 'package:readspark/domain/settings/entities/app_settings.dart';
import 'package:readspark/domain/settings/repositories/settings_repository.dart';

/// Drift implementation of [SettingsRepository].
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(AppDatabase db) : _dao = db.settingsDao;

  final SettingsDao _dao;

  @override
  Future<AppSettings> load() async {
    final values = await _dao.getAll();
    return AppSettings.fromKeyValue(values);
  }

  @override
  Future<void> save(AppSettings settings) =>
      _dao.setAll(settings.toKeyValue(), DateTime.now());

  @override
  Future<Map<String, String>> getAll() => _dao.getAll();

  @override
  Future<void> setAll(Map<String, String> values) =>
      _dao.setAll(values, DateTime.now());
}
