/// A text-to-speech voice reported by the device (ADR-004: cached per
/// platform; the user's selection lives in settings).
class Voice {
  const Voice({
    required this.id,
    required this.name,
    required this.locale,
    required this.platform,
    this.provider,
    this.isDefault = false,
    this.lastSyncAt,
  });

  final String id;
  final String name;
  final String locale;

  /// 'android' | 'windows'
  final String platform;
  final String? provider;
  final bool isDefault;
  final DateTime? lastSyncAt;
}
