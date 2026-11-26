import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';

/// Abstract local persistence contract for guidance preferences & training progress.
abstract interface class GuidePreferencesRepository {
  GuideProgress loadProgress();

  Future<void> saveProgress(GuideProgress progress);

  Future<void> resetProgress();
}
