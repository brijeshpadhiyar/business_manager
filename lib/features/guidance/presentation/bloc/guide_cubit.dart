import 'dart:async';

import 'package:business_manager/features/guidance/domain/catalog/guide_catalog.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/domain/repositories/guide_preferences_repository.dart';
import 'package:business_manager/features/guidance/domain/services/guide_voice_service.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Coordinates first-time onboarding, multi-screen End-to-End Action Coach,
/// per-screen button-upper spotlights, offline TTS voice narration, and
/// step-highlighted User Guide playback.
@lazySingleton
final class GuideCubit extends Cubit<GuideState> {
  GuideCubit(this._repository, this._voiceService) : super(const GuideState()) {
    _speakingSub = _voiceService.isSpeakingStream.listen((speaking) {
      if (!isClosed) {
        emit(state.copyWith(isSpeaking: speaking));
      }
    });
    _missingPackSub = _voiceService.voicePackMissingStream.listen((missing) {
      if (!isClosed) {
        emit(state.copyWith(voicePackMissing: missing));
      }
    });
  }

  final GuidePreferencesRepository _repository;
  final GuideVoiceService _voiceService;

  StreamSubscription<bool>? _speakingSub;
  StreamSubscription<bool>? _missingPackSub;
  int _topicPlaybackNonce = 0;

  void initialize() {
    if (state.initialized) return;
    final progress = _repository.loadProgress();
    emit(state.copyWith(initialized: true, progress: progress));
  }

  void updateRouteLocation(String location) {
    if (location == state.currentLocation) return;
    emit(state.copyWith(currentLocation: location));
  }

  /// Starts or resumes the full 9-chapter End-to-End Workshop Training Journey.
  Future<void> startEndToEndJourney({
    int? fromChapterIndex,
    String? chapterId,
    required String localeCode,
  }) async {
    _topicPlaybackNonce++;
    final allSteps = GuideCatalog.allJourneySteps;
    if (allSteps.isEmpty) return;

    var startIndex = 0;
    if (chapterId != null) {
      final idx = allSteps.indexWhere((s) => s.chapterId == chapterId);
      if (idx >= 0) startIndex = idx;
    } else if (fromChapterIndex != null) {
      final safeChapter = fromChapterIndex.clamp(
        0,
        GuideCatalog.chapters.length - 1,
      );
      final targetChapterId = GuideCatalog.chapters[safeChapter].id;
      final idx = allSteps.indexWhere((s) => s.chapterId == targetChapterId);
      if (idx >= 0) startIndex = idx;
    }

    final updatedProgress = state.progress.copyWith(welcomeDismissed: true);
    await _persist(updatedProgress);

    emit(
      state.copyWith(
        mode: GuideMode.endToEndJourney,
        steps: allSteps,
        currentStepIndex: startIndex,
        isMinimizedToCoachBar: false,
        progress: updatedProgress,
        clearActiveTopic: true,
      ),
    );
    await _speakCurrentIfEnabled(localeCode);
  }

  /// Starts a focused button-by-button spotlight tour for a single screen.
  Future<void> startScreenTour(
    String screenId, {
    required String localeCode,
  }) async {
    _topicPlaybackNonce++;
    final steps = GuideCatalog.stepsForScreen(screenId);
    if (steps.isEmpty) return;

    final updatedVisited = {...state.progress.visitedScreenIds, screenId};
    final updatedProgress = state.progress.copyWith(
      welcomeDismissed: true,
      visitedScreenIds: updatedVisited,
    );
    await _persist(updatedProgress);

    emit(
      state.copyWith(
        mode: GuideMode.screenTour,
        steps: steps,
        currentStepIndex: 0,
        isMinimizedToCoachBar: false,
        progress: updatedProgress,
        clearActiveTopic: true,
      ),
    );
    await _speakCurrentIfEnabled(localeCode);
  }

  /// Advances to the next step, marking completed chapters as the user finishes
  /// their final step.
  Future<void> nextStep({required String localeCode}) async {
    if (!state.isActive) return;

    final current = state.currentStep;
    final nextIndex = state.currentStepIndex + 1;
    var updatedProgress = state.progress;

    if (current != null) {
      final isEndOfChapter =
          nextIndex >= state.steps.length ||
          state.steps[nextIndex].chapterId != current.chapterId;
      if (isEndOfChapter) {
        final nextCompleted = {
          ...updatedProgress.completedChapterIds,
          current.chapterId,
        };
        final nextChapterIdx = nextIndex < state.steps.length
            ? GuideCatalog.chapterIndexById(state.steps[nextIndex].chapterId)
            : GuideCatalog.chapters.length - 1;
        updatedProgress = updatedProgress.copyWith(
          completedChapterIds: nextCompleted,
          visitedScreenIds: {
            ...updatedProgress.visitedScreenIds,
            current.screenId,
          },
          lastChapterIndex: nextChapterIdx,
          journeyCompleted:
              state.mode == GuideMode.endToEndJourney &&
              nextIndex >= state.steps.length,
        );
        await _persist(updatedProgress);
      }
    }

    if (nextIndex >= state.steps.length) {
      await _voiceService.stop();
      emit(
        state.copyWith(
          mode: GuideMode.idle,
          steps: const <GuideStep>[],
          currentStepIndex: 0,
          isMinimizedToCoachBar: false,
          progress: updatedProgress,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        currentStepIndex: nextIndex,
        isMinimizedToCoachBar: false,
        progress: updatedProgress,
      ),
    );
    await _speakCurrentIfEnabled(localeCode);
  }

  /// Moves back one step inside the active tour or journey.
  Future<void> previousStep({required String localeCode}) async {
    if (!state.canGoBack) return;
    emit(
      state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
        isMinimizedToCoachBar: false,
      ),
    );
    await _speakCurrentIfEnabled(localeCode);
  }

  /// Closes any active spotlight tour or Action Coach banner immediately.
  Future<void> skipTour() async {
    _topicPlaybackNonce++;
    await _voiceService.stop();
    emit(
      state.copyWith(
        mode: GuideMode.idle,
        steps: const <GuideStep>[],
        currentStepIndex: 0,
        isMinimizedToCoachBar: false,
      ),
    );
  }

  /// Minimizes the full spotlight scrim into a compact floating "What To Do Next"
  /// Action Coach bar so the user can freely type/interact with the screen.
  void minimizeToCoachBar() {
    if (!state.isActive) return;
    emit(state.copyWith(isMinimizedToCoachBar: true));
  }

  /// Restores the full spotlight bubble from the compact Action Coach bar.
  void expandFromCoachBar() {
    if (!state.isActive) return;
    emit(state.copyWith(isMinimizedToCoachBar: false));
  }

  /// Dismisses the First-Time Welcome Card permanently (user can still replay
  /// training anytime from `?` or Settings).
  Future<void> dismissWelcome() async {
    final updated = state.progress.copyWith(welcomeDismissed: true);
    await _persist(updated);
    emit(state.copyWith(progress: updated));
  }

  /// Marks a screen's first-visit hint as seen so it does not re-appear.
  Future<void> markScreenHintDismissed(String screenId) async {
    if (state.progress.visitedScreenIds.contains(screenId)) return;
    final updated = state.progress.copyWith(
      visitedScreenIds: {...state.progress.visitedScreenIds, screenId},
    );
    await _persist(updated);
    emit(state.copyWith(progress: updated));
  }

  /// Toggles automatic voice narration ON / OFF.
  Future<void> toggleVoice({String? currentLocaleCode}) async {
    final nextEnabled = !state.progress.voiceEnabled;
    final updated = state.progress.copyWith(voiceEnabled: nextEnabled);
    await _persist(updated);
    emit(state.copyWith(progress: updated));
    if (!nextEnabled) {
      _topicPlaybackNonce++;
      await _voiceService.stop();
      emit(state.copyWith(clearActiveTopic: true));
    } else if (state.isActive && currentLocaleCode != null) {
      await _speakCurrentIfEnabled(currentLocaleCode);
    }
  }

  /// Cycles TTS speed Slow -> Normal -> Fast -> Slow.
  Future<void> cycleSpeechRate({String? currentLocaleCode}) async {
    await setSpeechRate(
      state.progress.speechRate.next,
      currentLocaleCode: currentLocaleCode,
    );
  }

  Future<void> setSpeechRate(
    GuideSpeechRate rate, {
    String? currentLocaleCode,
  }) async {
    final updated = state.progress.copyWith(speechRate: rate);
    await _persist(updated);
    await _voiceService.setRate(rate);
    emit(state.copyWith(progress: updated));
    if (state.isActive && updated.voiceEnabled && currentLocaleCode != null) {
      await _speakCurrentIfEnabled(currentLocaleCode);
    }
  }

  Future<void> toggleNewScreenHints() async {
    final updated = state.progress.copyWith(
      showNewScreenHints: !state.progress.showNewScreenHints,
    );
    await _persist(updated);
    emit(state.copyWith(progress: updated));
  }

  /// Replays voice narration for the currently highlighted spotlight step.
  Future<void> replayCurrentStepVoice(String localeCode) async {
    final step = state.currentStep;
    if (step == null) return;
    await _voiceService.speak(
      step.speech(localeCode),
      localeCode: localeCode,
      rate: state.progress.speechRate,
    );
  }

  /// Reads a Help Topic's segments sequentially (When to Use -> Step 1..N ->
  /// Example), updating [activeTopicSegmentIndex] so the UI highlights the
  /// active card while speaking.
  Future<void> speakTopicSegments({
    required String topicId,
    required List<String> segments,
    required String localeCode,
  }) async {
    final nonce = ++_topicPlaybackNonce;
    await _voiceService.stop();
    if (segments.isEmpty) return;

    for (var i = 0; i < segments.length; i++) {
      if (isClosed || nonce != _topicPlaybackNonce) return;
      emit(state.copyWith(activeTopicId: topicId, activeTopicSegmentIndex: i));
      await _voiceService.speak(
        segments[i],
        localeCode: localeCode,
        rate: state.progress.speechRate,
      );
    }

    if (!isClosed && nonce == _topicPlaybackNonce) {
      emit(state.copyWith(clearActiveTopic: true));
    }
  }

  /// Stops any active Help Topic or spotlight narration.
  Future<void> stopVoice() async {
    _topicPlaybackNonce++;
    await _voiceService.stop();
    if (!isClosed) {
      emit(state.copyWith(clearActiveTopic: true));
    }
  }

  /// Resets all onboarding/training progress so a user can re-experience
  /// first-time training from scratch.
  Future<void> resetAllProgress() async {
    _topicPlaybackNonce++;
    await _voiceService.stop();
    await _repository.resetProgress();
    emit(
      state.copyWith(
        mode: GuideMode.idle,
        steps: const <GuideStep>[],
        currentStepIndex: 0,
        isMinimizedToCoachBar: false,
        progress: const GuideProgress(),
        clearActiveTopic: true,
      ),
    );
  }

  Future<void> _speakCurrentIfEnabled(String localeCode) async {
    if (!state.progress.voiceEnabled) return;
    final step = state.currentStep;
    if (step == null) return;
    await _voiceService.speak(
      step.speech(localeCode),
      localeCode: localeCode,
      rate: state.progress.speechRate,
    );
  }

  Future<void> _persist(GuideProgress progress) async {
    await _repository.saveProgress(progress);
  }

  @override
  Future<void> close() async {
    _topicPlaybackNonce++;
    await _speakingSub?.cancel();
    await _missingPackSub?.cancel();
    await _voiceService.stop();
    return super.close();
  }
}
