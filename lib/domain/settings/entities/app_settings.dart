/// User preferences persisted as key-value pairs in the `settings` table
/// (§19, §11).
class AppSettings {
  const AppSettings({
    this.ttsVoiceId,
    this.ttsLanguage,
    this.ttsRate = 1.0,
    this.ttsPitch = 1.0,
    this.theme = 'system',
    this.fontScale = 1.0,
    this.speakCode = false,
    this.speakUrls = false,
    this.speakSymbols = false,
  });

  static const String keyTtsVoiceId = 'tts_voice_id';
  static const String keyTtsLanguage = 'tts_language';
  static const String keyTtsRate = 'tts_rate';
  static const String keyTtsPitch = 'tts_pitch';
  static const String keyTheme = 'theme';
  static const String keyFontScale = 'font_size_scale';
  static const String keySpeakCode = 'speak_code';
  static const String keySpeakUrls = 'speak_urls';
  static const String keySpeakSymbols = 'speak_symbols';

  final String? ttsVoiceId;
  final String? ttsLanguage;
  final double ttsRate;
  final double ttsPitch;

  /// 'system' | 'light' | 'dark'
  final String theme;
  final double fontScale;
  final bool speakCode;
  final bool speakUrls;
  final bool speakSymbols;

  /// Rebuilds the typed settings from the raw key-value map of the database.
  /// Unknown or malformed values fall back to defaults.
  factory AppSettings.fromKeyValue(Map<String, String> values) {
    return AppSettings(
      ttsVoiceId: values[keyTtsVoiceId],
      ttsLanguage: values[keyTtsLanguage],
      ttsRate: _readDouble(values[keyTtsRate], 1.0),
      ttsPitch: _readDouble(values[keyTtsPitch], 1.0),
      theme: values[keyTheme] ?? 'system',
      fontScale: _readDouble(values[keyFontScale], 1.0),
      speakCode: _readBool(values[keySpeakCode], false),
      speakUrls: _readBool(values[keySpeakUrls], false),
      speakSymbols: _readBool(values[keySpeakSymbols], false),
    );
  }

  /// Serializes to the key-value map consumed by the `settings` table.
  Map<String, String> toKeyValue() {
    return {
      keyTtsVoiceId: ?ttsVoiceId,
      keyTtsLanguage: ?ttsLanguage,
      keyTtsRate: ttsRate.toString(),
      keyTtsPitch: ttsPitch.toString(),
      keyTheme: theme,
      keyFontScale: fontScale.toString(),
      keySpeakCode: speakCode.toString(),
      keySpeakUrls: speakUrls.toString(),
      keySpeakSymbols: speakSymbols.toString(),
    };
  }

  static double _readDouble(String? raw, double fallback) {
    if (raw == null) return fallback;
    return double.tryParse(raw) ?? fallback;
  }

  static bool _readBool(String? raw, bool fallback) {
    if (raw == null) return fallback;
    return raw == 'true';
  }
}
