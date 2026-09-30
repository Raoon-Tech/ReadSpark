import 'package:readspark/domain/settings/entities/app_settings.dart';

/// Persistence contract for user settings (§19).
abstract interface class SettingsRepository {
  /// Typed view of all persisted settings (defaults for missing keys).
  Future<AppSettings> load();

  /// Persists [settings] (only non-null values are written).
  Future<void> save(AppSettings settings);

  /// Raw key-value access (used by tests and migrations).
  Future<Map<String, String>> getAll();

  Future<void> setAll(Map<String, String> values);
}
