import 'dart:async';

import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/domain/services/guide_voice_service.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

/// Offline Text-to-Speech narration service powered by native platform voices
/// via `flutter_tts`.
///
/// - Follows the active app locale (`gu` -> `gu-IN`, `en` -> `en-IN`/`en-US`).
/// - Gracefully degrades to silent mode on unsupported platforms (e.g. Linux),
///   test bindings, or devices missing a Gujarati TTS voice pack.
@LazySingleton(as: GuideVoiceService)
final class FlutterTtsGuideVoiceService implements GuideVoiceService {
  FlutterTtsGuideVoiceService();

  FlutterTts? _tts;
  bool _initialized = false;
  bool _platformUnsupported = false;
  String? _activeLanguageTag;

  final StreamController<bool> _speakingCtrl =
      StreamController<bool>.broadcast();
  final StreamController<bool> _missingPackCtrl =
      StreamController<bool>.broadcast();

  bool get _isSupportedPlatform {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.linux || TargetPlatform.fuchsia => false,
    };
  }

  Future<FlutterTts?> _ensureTts() async {
    if (_platformUnsupported || !_isSupportedPlatform) {
      return null;
    }
    if (_initialized && _tts != null) return _tts;
    try {
      final tts = FlutterTts();
      tts.setStartHandler(() {
        if (!_speakingCtrl.isClosed) _speakingCtrl.add(true);
      });
      tts.setCompletionHandler(() {
        if (!_speakingCtrl.isClosed) _speakingCtrl.add(false);
      });
      tts.setCancelHandler(() {
        if (!_speakingCtrl.isClosed) _speakingCtrl.add(false);
      });
      tts.setErrorHandler((_) {
        if (!_speakingCtrl.isClosed) _speakingCtrl.add(false);
      });
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
      await tts.awaitSpeakCompletion(true);
      _tts = tts;
      _initialized = true;
      return tts;
    } on MissingPluginException {
      _platformUnsupported = true;
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<bool> get isSpeakingStream => _speakingCtrl.stream;

  @override
  Stream<bool> get voicePackMissingStream => _missingPackCtrl.stream;

  @override
  Future<bool> isLocaleAvailable(String localeCode) async {
    final tts = await _ensureTts();
    if (tts == null) return false;
    final candidates = _languageCandidates(localeCode);
    for (final tag in candidates) {
      try {
        final dynamic result = await tts.isLanguageAvailable(tag);
        if (result == true || result == 1) {
          return true;
        }
      } on MissingPluginException {
        _platformUnsupported = true;
        return false;
      } catch (_) {
        // Try next candidate tag.
      }
    }
    return false;
  }

  List<String> _languageCandidates(String localeCode) {
    if (localeCode == 'gu') {
      return const ['gu-IN', 'gu'];
    }
    return const ['en-IN', 'en-US', 'en-GB', 'en'];
  }

  @override
  Future<void> setRate(GuideSpeechRate rate) async {
    final tts = await _ensureTts();
    if (tts == null) return;
    try {
      await tts.setSpeechRate(kIsWeb ? rate.webRate : rate.nativeRate);
    } catch (_) {
      // Ignore platform rate errors.
    }
  }

  @override
  Future<void> speak(
    String text, {
    required String localeCode,
    GuideSpeechRate rate = GuideSpeechRate.normal,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final tts = await _ensureTts();
    if (tts == null) {
      if (!_speakingCtrl.isClosed) _speakingCtrl.add(false);
      return;
    }

    try {
      await tts.stop();
      await tts.setSpeechRate(kIsWeb ? rate.webRate : rate.nativeRate);

      final candidates = _languageCandidates(localeCode);
      String? resolvedTag;
      for (final tag in candidates) {
        try {
          final dynamic avail = await tts.isLanguageAvailable(tag);
          if (avail == true || avail == 1) {
            resolvedTag = tag;
            break;
          }
        } catch (_) {
          // On Web/Windows some engines don't implement isLanguageAvailable strictly.
          resolvedTag ??= tag;
        }
      }

      if (resolvedTag == null) {
        if (!_missingPackCtrl.isClosed) _missingPackCtrl.add(true);
        if (!_speakingCtrl.isClosed) _speakingCtrl.add(false);
        return;
      }

      if (!_missingPackCtrl.isClosed) _missingPackCtrl.add(false);
      if (_activeLanguageTag != resolvedTag) {
        await tts.setLanguage(resolvedTag);
        _activeLanguageTag = resolvedTag;
      }

      if (!_speakingCtrl.isClosed) _speakingCtrl.add(true);
      await tts.speak(trimmed);
    } on MissingPluginException {
      _platformUnsupported = true;
      if (!_speakingCtrl.isClosed) _speakingCtrl.add(false);
    } catch (_) {
      if (!_speakingCtrl.isClosed) _speakingCtrl.add(false);
    }
  }

  @override
  Future<void> stop() async {
    if (!_speakingCtrl.isClosed) _speakingCtrl.add(false);
    final tts = _tts;
    if (tts == null) return;
    try {
      await tts.stop();
    } catch (_) {
      // Ignore stop errors.
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _speakingCtrl.close();
    await _missingPackCtrl.close();
  }
}
