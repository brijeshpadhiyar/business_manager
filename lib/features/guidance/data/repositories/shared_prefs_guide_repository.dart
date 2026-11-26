import 'dart:convert';

import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/domain/repositories/guide_preferences_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-only persistence for interactive training progress and voice
/// preferences via [SharedPreferences].
@LazySingleton(as: GuidePreferencesRepository)
final class SharedPrefsGuideRepository implements GuidePreferencesRepository {
  SharedPrefsGuideRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String storageKey = 'stitchflow_guide_progress_v1';

  @override
  GuideProgress loadProgress() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const GuideProgress();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return GuideProgress.fromJson(decoded);
      }
      if (decoded is Map) {
        return GuideProgress.fromJson(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (_) {
      return const GuideProgress();
    }
    return const GuideProgress();
  }

  @override
  Future<void> saveProgress(GuideProgress progress) async {
    await _prefs.setString(storageKey, jsonEncode(progress.toJson()));
  }

  @override
  Future<void> resetProgress() async {
    await _prefs.remove(storageKey);
  }
}
