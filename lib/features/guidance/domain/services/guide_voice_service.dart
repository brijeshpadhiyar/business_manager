import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';

/// Pure Dart abstraction over offline Text-to-Speech narration.
abstract interface class GuideVoiceService {
  /// Emits `true` while voice narration is speaking, `false` when idle/stopped.
  Stream<bool> get isSpeakingStream;

  /// Emits `true` if the requested locale voice pack (e.g. Gujarati `gu-IN`)
  /// is not installed on the user's device.
  Stream<bool> get voicePackMissingStream;

  /// Speaks [text] in the requested app language (`'en'` or `'gu'`).
  Future<void> speak(
    String text, {
    required String localeCode,
    GuideSpeechRate rate = GuideSpeechRate.normal,
  });

  /// Immediately stops any ongoing narration.
  Future<void> stop();

  /// Updates the active speaking speed.
  Future<void> setRate(GuideSpeechRate rate);

  /// Checks whether the platform TTS engine supports [localeCode].
  Future<bool> isLocaleAvailable(String localeCode);

  /// Releases underlying platform listeners.
  Future<void> dispose();
}
