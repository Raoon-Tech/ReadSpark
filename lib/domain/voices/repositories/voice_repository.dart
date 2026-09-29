import 'package:readspark/domain/voices/entities/voice.dart';

/// Persistence contract for the device voice cache (ADR-004).
abstract interface class VoiceRepository {
  /// Replaces the cached voices of [platform] with [voices].
  Future<void> replaceForPlatform(String platform, List<Voice> voices);

  /// All cached voices, optionally filtered by platform.
  Future<List<Voice>> getAll({String? platform});
}
