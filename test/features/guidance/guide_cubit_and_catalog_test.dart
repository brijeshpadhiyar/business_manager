import 'dart:async';

import 'package:business_manager/features/guidance/domain/catalog/guide_catalog.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/domain/repositories/guide_preferences_repository.dart';
import 'package:business_manager/features/guidance/domain/services/guide_voice_service.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_cubit.dart';
import 'package:business_manager/features/settings/domain/help_topics.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeGuideRepository implements GuidePreferencesRepository {
  GuideProgress stored = const GuideProgress();
  int saveCount = 0;

  @override
  GuideProgress loadProgress() => stored;

  @override
  Future<void> saveProgress(GuideProgress progress) async {
    stored = progress;
    saveCount++;
  }

  @override
  Future<void> resetProgress() async {
    stored = const GuideProgress();
  }
}

final class _FakeVoiceService implements GuideVoiceService {
  final StreamController<bool> speakingCtrl =
      StreamController<bool>.broadcast();
  final StreamController<bool> missingPackCtrl =
      StreamController<bool>.broadcast();

  final List<(String text, String locale, GuideSpeechRate rate)> spokenLog = [];
  int stopCount = 0;
  GuideSpeechRate? lastRate;

  @override
  Stream<bool> get isSpeakingStream => speakingCtrl.stream;

  @override
  Stream<bool> get voicePackMissingStream => missingPackCtrl.stream;

  @override
  Future<bool> isLocaleAvailable(String localeCode) async => true;

  @override
  Future<void> setRate(GuideSpeechRate rate) async {
    lastRate = rate;
  }

  @override
  Future<void> speak(
    String text, {
    required String localeCode,
    GuideSpeechRate rate = GuideSpeechRate.normal,
  }) async {
    spokenLog.add((text, localeCode, rate));
    speakingCtrl.add(true);
    await Future<void>.delayed(Duration.zero);
    speakingCtrl.add(false);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    speakingCtrl.add(false);
  }

  @override
  Future<void> dispose() async {
    await speakingCtrl.close();
    await missingPackCtrl.close();
  }
}

void main() {
  group('GuideCatalog & GuideEntities', () {
    test('contains 9 ordered bilingual End-to-End chapters with valid steps', () {
      expect(GuideCatalog.chapters.length, 9);
      final seenStepIds = <String>{};
      for (var i = 0; i < GuideCatalog.chapters.length; i++) {
        final chapter = GuideCatalog.chapters[i];
        expect(chapter.order, i + 1);
        expect(chapter.titleEn.trim(), isNotEmpty);
        expect(chapter.titleGu.trim(), isNotEmpty);
        expect(chapter.summaryEn.trim(), isNotEmpty);
        expect(chapter.summaryGu.trim(), isNotEmpty);
        expect(chapter.nextStepLabelEn.trim(), isNotEmpty);
        expect(chapter.nextStepLabelGu.trim(), isNotEmpty);
        expect(chapter.steps, isNotEmpty);

        for (final step in chapter.steps) {
          expect(seenStepIds.add(step.id), isTrue, reason: 'Duplicate ${step.id}');
          expect(step.chapterId, chapter.id);
          expect(step.title('en'), isNotEmpty);
          expect(step.title('gu'), isNotEmpty);
          expect(step.actionDescription('en'), isNotEmpty);
          expect(step.actionDescription('gu'), isNotEmpty);
          expect(step.nextActionHint('en'), isNotEmpty);
          expect(step.nextActionHint('gu'), isNotEmpty);
          expect(step.speech('en'), isNotEmpty);
          expect(step.speech('gu'), isNotEmpty);
        }
      }
    });

    test('maps every HelpTopic in StitchFlowHelpCatalog to live action links', () {
      for (final topic in StitchFlowHelpCatalog.topics) {
        final link = GuideCatalog.helpTopicLinks[topic.id];
        expect(
          link,
          isNotNull,
          reason: 'Missing HelpTopicActionLink for ${topic.id}',
        );
        expect(GuideCatalog.chapterById(link!.chapterId), isNotNull);
        expect(GuideCatalog.screenTours.containsKey(link.liveScreenId), isTrue);
        if (link.nextTopicId != null) {
          expect(
            StitchFlowHelpCatalog.byId(link.nextTopicId!),
            isNotNull,
            reason: 'Invalid nextTopicId ${link.nextTopicId}',
          );
        }
      }
    });

    test('GuideScreenId.fromLocation resolves primary and detail routes', () {
      expect(GuideScreenId.fromLocation('/'), GuideScreenId.home);
      expect(GuideScreenId.fromLocation('/lots'), GuideScreenId.lots);
      expect(GuideScreenId.fromLocation('/lots/lot-123'), GuideScreenId.lotDetail);
      expect(GuideScreenId.fromLocation('/lots/new'), isNull);
      expect(GuideScreenId.fromLocation('/stock'), GuideScreenId.stock);
      expect(GuideScreenId.fromLocation('/workers'), GuideScreenId.workers);
      expect(
        GuideScreenId.fromLocation('/workers/w-1'),
        GuideScreenId.workerDetail,
      );
      expect(GuideScreenId.fromLocation('/processes'), GuideScreenId.processes);
      expect(GuideScreenId.fromLocation('/accounting'), GuideScreenId.accounting);
      expect(GuideScreenId.fromLocation('/reports'), GuideScreenId.reports);
      expect(GuideScreenId.fromLocation('/settings'), GuideScreenId.settings);
    });

    test('GuideProgress round-trips cleanly through JSON', () {
      const original = GuideProgress(
        welcomeDismissed: true,
        voiceEnabled: false,
        speechRate: GuideSpeechRate.fast,
        showNewScreenHints: false,
        completedChapterIds: {'dashboard-overview', 'processes-setup'},
        visitedScreenIds: {'home', 'lots'},
        lastChapterIndex: 3,
        journeyCompleted: true,
      );

      final restored = GuideProgress.fromJson(original.toJson());
      expect(restored.welcomeDismissed, isTrue);
      expect(restored.voiceEnabled, isFalse);
      expect(restored.speechRate, GuideSpeechRate.fast);
      expect(restored.showNewScreenHints, isFalse);
      expect(restored.completedChapterIds, original.completedChapterIds);
      expect(restored.visitedScreenIds, original.visitedScreenIds);
      expect(restored.lastChapterIndex, 3);
      expect(restored.journeyCompleted, isTrue);
    });
  });

  group('GuideCubit', () {
    late _FakeGuideRepository repo;
    late _FakeVoiceService voice;
    late GuideCubit cubit;

    setUp(() {
      repo = _FakeGuideRepository();
      voice = _FakeVoiceService();
      cubit = GuideCubit(repo, voice)..initialize();
    });

    tearDown(() async {
      await cubit.close();
      await voice.dispose();
    });

    test('starts End-to-End Journey, speaks in Gujarati, and completes all chapters', () async {
      await cubit.startEndToEndJourney(fromChapterIndex: 0, localeCode: 'gu');
      expect(cubit.state.mode, GuideMode.endToEndJourney);
      expect(cubit.state.isActive, isTrue);
      expect(cubit.state.progress.welcomeDismissed, isTrue);
      expect(voice.spokenLog, hasLength(1));
      expect(voice.spokenLog.first.$2, 'gu');

      // Step through the entire journey until completion.
      final totalSteps = GuideCatalog.allJourneySteps.length;
      for (var i = 0; i < totalSteps; i++) {
        await cubit.nextStep(localeCode: 'gu');
      }

      expect(cubit.state.isActive, isFalse);
      expect(cubit.state.mode, GuideMode.idle);
      expect(cubit.state.progress.journeyCompleted, isTrue);
      expect(
        cubit.state.progress.completedChapterIds.length,
        GuideCatalog.chapters.length,
      );
      expect(repo.stored.journeyCompleted, isTrue);
    });

    test('supports screen tours, minimize/expand coach bar, and voice toggles', () async {
      await cubit.startScreenTour(GuideScreenId.stock, localeCode: 'en');
      expect(cubit.state.mode, GuideMode.screenTour);
      expect(cubit.state.showSpotlightOverlay, isTrue);
      expect(cubit.state.progress.visitedScreenIds, contains(GuideScreenId.stock));

      cubit.minimizeToCoachBar();
      expect(cubit.state.showActionCoachBanner, isTrue);
      expect(cubit.state.showSpotlightOverlay, isFalse);

      cubit.expandFromCoachBar();
      expect(cubit.state.showSpotlightOverlay, isTrue);

      // Toggle voice OFF -> stops TTS and does not speak on next step.
      await cubit.toggleVoice(currentLocaleCode: 'en');
      expect(cubit.state.progress.voiceEnabled, isFalse);
      final spokenBeforeNext = voice.spokenLog.length;
      await cubit.nextStep(localeCode: 'en');
      expect(voice.spokenLog.length, spokenBeforeNext);

      // Cycle speed: normal -> fast -> slow.
      await cubit.cycleSpeechRate(currentLocaleCode: 'en');
      expect(cubit.state.progress.speechRate, GuideSpeechRate.fast);
      await cubit.cycleSpeechRate(currentLocaleCode: 'en');
      expect(cubit.state.progress.speechRate, GuideSpeechRate.slow);

      // Rewind back one step.
      expect(cubit.state.canGoBack, isTrue);
      await cubit.previousStep(localeCode: 'en');
      expect(cubit.state.currentStepIndex, 0);

      await cubit.skipTour();
      expect(cubit.state.isActive, isFalse);
    });

    test('speaks HelpTopic segments sequentially and resets cleanly', () async {
      await cubit.speakTopicSegments(
        topicId: 'issuing-stock',
        segments: const ['Segment 1', 'Segment 2', 'Segment 3'],
        localeCode: 'en',
      );
      expect(voice.spokenLog.map((e) => e.$1).toList(), [
        'Segment 1',
        'Segment 2',
        'Segment 3',
      ]);
      expect(cubit.state.activeTopicId, isNull);

      voice.missingPackCtrl.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.voicePackMissing, isTrue);

      await cubit.resetAllProgress();
      expect(cubit.state.progress.welcomeDismissed, isFalse);
      expect(cubit.state.progress.completedChapterIds, isEmpty);
    });
  });
}
