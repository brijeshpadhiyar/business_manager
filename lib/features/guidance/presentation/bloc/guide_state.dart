import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';

/// Immutable UI state managed by [GuideCubit].
final class GuideState {
  const GuideState({
    this.initialized = false,
    this.mode = GuideMode.idle,
    this.steps = const <GuideStep>[],
    this.currentStepIndex = 0,
    this.isMinimizedToCoachBar = false,
    this.isSpeaking = false,
    this.voicePackMissing = false,
    this.currentLocation = '/',
    this.progress = const GuideProgress(),
    this.activeTopicId,
    this.activeTopicSegmentIndex,
  });

  final bool initialized;
  final GuideMode mode;
  final List<GuideStep> steps;
  final int currentStepIndex;
  final bool isMinimizedToCoachBar;
  final bool isSpeaking;
  final bool voicePackMissing;
  final String currentLocation;
  final GuideProgress progress;

  /// Non-null while narrating a [HelpTopic] step-by-step in [HelpTopicDetailPage].
  final String? activeTopicId;
  final int? activeTopicSegmentIndex;

  bool get isActive => mode != GuideMode.idle && steps.isNotEmpty;

  bool get showSpotlightOverlay => isActive && !isMinimizedToCoachBar;

  bool get showActionCoachBanner => isActive && isMinimizedToCoachBar;

  GuideStep? get currentStep {
    if (!isActive) return null;
    if (currentStepIndex < 0 || currentStepIndex >= steps.length) return null;
    return steps[currentStepIndex];
  }

  bool get canGoBack => isActive && currentStepIndex > 0;

  bool get isLastStep => isActive && currentStepIndex >= steps.length - 1;

  int get completedChaptersCount => progress.completedChapterIds.length;

  /// True when the current [screenId] has not been visited/dismissed yet and
  /// the user has new-screen hints enabled.
  bool shouldShowHintForScreen(String screenId) {
    if (!initialized || isActive || !progress.showNewScreenHints) return false;
    return !progress.visitedScreenIds.contains(screenId);
  }

  GuideState copyWith({
    bool? initialized,
    GuideMode? mode,
    List<GuideStep>? steps,
    int? currentStepIndex,
    bool? isMinimizedToCoachBar,
    bool? isSpeaking,
    bool? voicePackMissing,
    String? currentLocation,
    GuideProgress? progress,
    String? activeTopicId,
    int? activeTopicSegmentIndex,
    bool clearActiveTopic = false,
  }) {
    return GuideState(
      initialized: initialized ?? this.initialized,
      mode: mode ?? this.mode,
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isMinimizedToCoachBar:
          isMinimizedToCoachBar ?? this.isMinimizedToCoachBar,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      voicePackMissing: voicePackMissing ?? this.voicePackMissing,
      currentLocation: currentLocation ?? this.currentLocation,
      progress: progress ?? this.progress,
      activeTopicId: clearActiveTopic
          ? null
          : (activeTopicId ?? this.activeTopicId),
      activeTopicSegmentIndex: clearActiveTopic
          ? null
          : (activeTopicSegmentIndex ?? this.activeTopicSegmentIndex),
    );
  }
}
