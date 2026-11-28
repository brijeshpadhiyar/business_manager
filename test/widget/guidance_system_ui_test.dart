import 'dart:async';

import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/domain/repositories/guide_preferences_repository.dart';
import 'package:business_manager/features/guidance/domain/services/guide_voice_service.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_cubit.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_state.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:business_manager/features/guidance/presentation/widgets/first_time_welcome_card.dart';
import 'package:business_manager/features/guidance/presentation/widgets/guide_action_coach_banner.dart';
import 'package:business_manager/features/guidance/presentation/widgets/guide_spotlight_overlay.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/settings/presentation/pages/help_guidance_page.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _InMemoryGuideRepo implements GuidePreferencesRepository {
  GuideProgress _progress = const GuideProgress();

  @override
  GuideProgress loadProgress() => _progress;

  @override
  Future<void> saveProgress(GuideProgress progress) async {
    _progress = progress;
  }

  @override
  Future<void> resetProgress() async {
    _progress = const GuideProgress();
  }
}

final class _SilentVoiceService implements GuideVoiceService {
  final _speakingCtrl = StreamController<bool>.broadcast();
  final _missingCtrl = StreamController<bool>.broadcast();
  final List<String> spokenTexts = [];

  @override
  Stream<bool> get isSpeakingStream => _speakingCtrl.stream;

  @override
  Stream<bool> get voicePackMissingStream => _missingCtrl.stream;

  @override
  Future<bool> isLocaleAvailable(String localeCode) async => true;

  @override
  Future<void> setRate(GuideSpeechRate rate) async {}

  @override
  Future<void> speak(
    String text, {
    required String localeCode,
    GuideSpeechRate rate = GuideSpeechRate.normal,
  }) async {
    spokenTexts.add(text);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _speakingCtrl.close();
    await _missingCtrl.close();
  }
}

DashboardSnapshot _emptyDashboardSnapshot() => const DashboardSnapshot(
  businessNameEn: 'Business Manager',
  businessNameGu: 'બિઝનેસ મેનેજર',
  totalLots: 0,
  totalDesigns: 0,
  totalColours: 0,
  activeProcessesCount: 0,
  activeWorkersCount: 0,
  totalInitialStock: 0,
  availableGoodStock: 0,
  pendingWorkerStock: 0,
  damagedStock: 0,
  lostStock: 0,
  shortageStock: 0,
  totalEarnedLabourPaise: 0,
  totalAdvancePaymentsPaise: 0,
  totalAdvanceRefundsPaise: 0,
  totalRegularPaymentsPaise: 0,
  totalAdjustmentNetPaise: 0,
  totalOutstandingPayablePaise: 0,
  totalAdvanceCreditPaise: 0,
  processPendingList: [],
  recentActivity: [],
);

Widget _wrapTestApp({
  required Widget child,
  required GuideCubit guideCubit,
  LocaleCubit? localeCubit,
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<GuideCubit>.value(value: guideCubit),
      if (localeCubit != null)
        BlocProvider<LocaleCubit>.value(value: localeCubit),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.light(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: child,
    ),
  );
}

void main() {
  late _InMemoryGuideRepo repo;
  late _SilentVoiceService voice;
  late GuideCubit guideCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _InMemoryGuideRepo();
    voice = _SilentVoiceService();
    guideCubit = GuideCubit(repo, voice)..initialize();
  });

  tearDown(() async {
    await guideCubit.close();
    await voice.dispose();
  });

  testWidgets(
    'FirstTimeWelcomeCard renders for fresh workshop, toggles voice, and dismisses',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final localeCubit = LocaleCubit(prefs);

      await tester.pumpWidget(
        _wrapTestApp(
          guideCubit: guideCubit,
          localeCubit: localeCubit,
          child: Scaffold(
            body: SingleChildScrollView(
              child: FirstTimeWelcomeCard(snapshot: _emptyDashboardSnapshot()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Business Manager'), findsOneWidget);
      expect(find.text('Start Complete Training'), findsOneWidget);
      expect(find.text('Voice ON'), findsOneWidget);

      await tester.tap(find.text('Voice ON'));
      await tester.pumpAndSettle();
      expect(find.text('Voice OFF'), findsOneWidget);

      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Business Manager'), findsNothing);

      await localeCubit.close();
    },
  );

  testWidgets(
    'GuideSpotlightOverlay renders button-upper callout, transitions to Action Coach bar, and advances',
    (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrapTestApp(
          guideCubit: guideCubit,
          child: Scaffold(
            body: BlocBuilder<GuideCubit, GuideState>(
              builder: (context, state) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: GuideTarget(
                        id: GuideTargetId.stockIssueAction,
                        child: FilledButton(
                          onPressed: () {},
                          child: const Text('Issue Stock'),
                        ),
                      ),
                    ),
                    if (state.showSpotlightOverlay)
                      GuideSpotlightOverlay(state: state),
                    if (state.showActionCoachBanner)
                      GuideActionCoachBanner(state: state),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await guideCubit.startScreenTour(GuideScreenId.stock, localeCode: 'en');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Issue Stock Button'), findsOneWidget);
      expect(find.text('Try Now'), findsOneWidget);

      // Minimize to floating Action Coach banner.
      await tester.tap(find.text('Try Now'));
      await tester.pump();
      expect(find.text('Spotlight'), findsOneWidget);

      // Expand back to full spotlight overlay.
      await tester.tap(find.text('Spotlight'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Issue Stock Button'), findsOneWidget);

      // Advance to next step and then skip cleanly.
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Receive Return Button'), findsOneWidget);

      await tester.tap(find.byTooltip('Skip'));
      await tester.pump();
      expect(guideCubit.state.isActive, isFalse);
    },
  );

  testWidgets(
    'HelpGuidancePage displays 12-chapter roadmap, switches to 22 topics, and speaks aloud',
    (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrapTestApp(
          guideCubit: guideCubit,
          child: const HelpGuidancePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Interactive Training'), findsOneWidget);
      expect(find.text('Complete Guide (22)'), findsOneWidget);
      expect(find.text('0 of 12 chapters completed'), findsOneWidget);

      // Tap Listen on Chapter 1 to trigger TTS voice service.
      await tester.tap(find.text('Listen').first);
      await tester.pumpAndSettle();
      expect(voice.spokenTexts, isNotEmpty);

      // Switch to Complete Guide (22) tab.
      await tester.tap(find.text('Complete Guide (22)'));
      await tester.pumpAndSettle();
      expect(find.text('1. Getting Started with StitchFlow'), findsOneWidget);
    },
  );

  testWidgets(
    'HelpTopicDetailPage renders Audio Guide bar, Show Me on Screen, and What To Do Next',
    (tester) async {
      await tester.pumpWidget(
        _wrapTestApp(
          guideCubit: guideCubit,
          child: const HelpTopicDetailPage(topicId: 'issuing-stock'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Listen'), findsOneWidget);
      expect(find.text('Show Me on Screen'), findsOneWidget);

      await tester.tap(find.text('Listen'));
      await tester.pumpAndSettle();
      expect(voice.spokenTexts.length, greaterThanOrEqualTo(5));

      await tester.scrollUntilVisible(
        find.text('What To Do Next'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('What To Do Next'), findsOneWidget);
      expect(find.text('9. Receiving Returned Stock'), findsOneWidget);
    },
  );
}
