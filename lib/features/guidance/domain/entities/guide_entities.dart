/// Pure Dart domain models for the interactive System Guidance,
/// button-upper spotlight tours, end-to-end workshop Action Coach,
/// and offline Text-to-Speech (TTS) narration system.
library;

/// Active guidance mode.
enum GuideMode {
  /// No spotlight tour or journey currently active.
  idle,

  /// Multi-screen, 9-chapter end-to-end workshop training journey.
  endToEndJourney,

  /// Focused button-by-button spotlight tour for the current screen.
  screenTour,
}

/// Configurable TTS narration speed tiers.
enum GuideSpeechRate {
  slow,
  normal,
  fast;

  String get storageValue => name;

  static GuideSpeechRate fromStorage(String? value) {
    return switch (value) {
      'slow' => GuideSpeechRate.slow,
      'fast' => GuideSpeechRate.fast,
      _ => GuideSpeechRate.normal,
    };
  }

  GuideSpeechRate get next {
    return switch (this) {
      GuideSpeechRate.slow => GuideSpeechRate.normal,
      GuideSpeechRate.normal => GuideSpeechRate.fast,
      GuideSpeechRate.fast => GuideSpeechRate.slow,
    };
  }

  /// Native mobile/desktop `flutter_tts` rate value (0.0..1.0 scale).
  double get nativeRate => switch (this) {
    GuideSpeechRate.slow => 0.38,
    GuideSpeechRate.normal => 0.50,
    GuideSpeechRate.fast => 0.62,
  };

  /// Web Speech API rate multiplier.
  double get webRate => switch (this) {
    GuideSpeechRate.slow => 0.82,
    GuideSpeechRate.normal => 1.0,
    GuideSpeechRate.fast => 1.22,
  };
}

/// Canonical string target IDs registered by [GuideTarget] widgets across the app.
abstract final class GuideTargetId {
  // Global Shell & Navigation Chrome
  static const String navHome = 'nav_home';
  static const String navLots = 'nav_lots';
  static const String navStock = 'nav_stock';
  static const String navWorkers = 'nav_workers';
  static const String navSettings = 'nav_settings';
  static const String appBarSearch = 'app_bar_search';
  static const String appBarGuide = 'app_bar_guide';
  static const String appBarSync = 'app_bar_sync';

  // Dashboard
  static const String dashSetupChecklist = 'dash_setup_checklist';
  static const String dashQuickIssue = 'dash_quick_issue';
  static const String dashQuickReceive = 'dash_quick_receive';
  static const String dashQuickPayment = 'dash_quick_payment';
  static const String dashQuickNewLot = 'dash_quick_new_lot';
  static const String dashQuickInspect = 'dash_quick_inspect';
  static const String dashQuickAddWorker = 'dash_quick_add_worker';
  static const String dashTodayKpis = 'dash_today_kpis';
  static const String dashStockHealth = 'dash_stock_health';
  static const String dashFinanceHealth = 'dash_finance_health';

  // Processes
  static const String processNewAction = 'process_new_action';

  // Workers
  static const String workerNewAction = 'worker_new_action';
  static const String workerDetailAssignments = 'worker_detail_assignments';
  static const String workerDetailRates = 'worker_detail_rates';
  static const String workerDetailLedger = 'worker_detail_ledger';

  // Lots
  static const String lotNewAction = 'lot_new_action';
  static const String lotDetailAddDesign = 'lot_detail_add_design';
  static const String lotDetailRouting = 'lot_detail_routing';

  // Stock Movements
  static const String stockIssueAction = 'stock_issue_action';
  static const String stockReceiveAction = 'stock_receive_action';
  static const String stockRepairAction = 'stock_repair_action';
  static const String stockTabs = 'stock_tabs';

  // Accounting
  static const String accountingRecordPaymentAction =
      'accounting_record_payment_action';
  static const String accountingTabs = 'accounting_tabs';

  // Reports & History
  static const String reportsFilterBar = 'reports_filter_bar';
  static const String reportsCategories = 'reports_categories';
  static const String reportsExportAction = 'reports_export_action';

  // Settings & Business Profile
  static const String settingsAppearanceTile = 'settings_appearance_tile';
  static const String settingsBusinessProfileTile =
      'settings_business_profile_tile';
  static const String settingsStockLabourTile = 'settings_stock_labour_tile';
  static const String settingsSecurityTile = 'settings_security_tile';
  static const String settingsBackupTile = 'settings_backup_tile';
  static const String settingsHelpTile = 'settings_help_tile';
}

/// Canonical screen IDs mapped from GoRouter locations for per-screen tours
/// and first-visit screen hints.
abstract final class GuideScreenId {
  static const String home = 'home';
  static const String lots = 'lots';
  static const String lotDetail = 'lot_detail';
  static const String stock = 'stock';
  static const String workers = 'workers';
  static const String workerDetail = 'worker_detail';
  static const String processes = 'processes';
  static const String accounting = 'accounting';
  static const String reports = 'reports';
  static const String settings = 'settings';
  static const String businessProfile = 'business_profile';

  /// Maps a GoRouter [location] path to its canonical [GuideScreenId].
  static String? fromLocation(String location) {
    final path = location.split('?').first;
    if (path == '/' || path == '/dashboard') return home;
    if (path == '/lots') return lots;
    if (path.startsWith('/lots/') &&
        path != '/lots/new' &&
        !path.contains('/colours/') &&
        !path.endsWith('/routing') &&
        !path.endsWith('/history') &&
        !path.endsWith('/timeline')) {
      return lotDetail;
    }
    if (path == '/stock') return stock;
    if (path == '/workers') return workers;
    if (path.startsWith('/workers/') &&
        path != '/workers/new' &&
        !path.endsWith('/edit') &&
        !path.endsWith('/assignments') &&
        !path.contains('/rates') &&
        !path.endsWith('/ledger') &&
        !path.contains('/adjustments')) {
      return workerDetail;
    }
    if (path == '/processes') return processes;
    if (path == '/accounting') return accounting;
    if (path == '/reports') return reports;
    if (path == '/settings') return settings;
    if (path == '/settings/business-profile') return businessProfile;
    return null;
  }
}

/// A single spotlight / coaching instruction step.
final class GuideStep {
  const GuideStep({
    required this.id,
    required this.chapterId,
    required this.screenId,
    required this.routePath,
    required this.titleEn,
    required this.titleGu,
    required this.actionDescriptionEn,
    required this.actionDescriptionGu,
    required this.nextActionHintEn,
    required this.nextActionHintGu,
    required this.speechEn,
    required this.speechGu,
    this.targetId,
    this.primaryTabIndex,
    this.allowTargetTap = true,
    this.isInteractiveAction = false,
  });

  final String id;
  final String chapterId;
  final String screenId;
  final String routePath;
  final String? targetId;
  final int? primaryTabIndex;
  final bool allowTargetTap;
  final bool isInteractiveAction;

  final String titleEn;
  final String titleGu;
  final String actionDescriptionEn;
  final String actionDescriptionGu;
  final String nextActionHintEn;
  final String nextActionHintGu;
  final String speechEn;
  final String speechGu;

  String title(String localeCode) => localeCode == 'gu' ? titleGu : titleEn;

  String actionDescription(String localeCode) =>
      localeCode == 'gu' ? actionDescriptionGu : actionDescriptionEn;

  String nextActionHint(String localeCode) =>
      localeCode == 'gu' ? nextActionHintGu : nextActionHintEn;

  String speech(String localeCode) => localeCode == 'gu' ? speechGu : speechEn;
}

/// One of the 9 End-to-End Workshop Training Chapters.
final class GuideChapter {
  const GuideChapter({
    required this.id,
    required this.order,
    required this.screenId,
    required this.routePath,
    required this.iconKey,
    required this.titleEn,
    required this.titleGu,
    required this.summaryEn,
    required this.summaryGu,
    required this.nextStepLabelEn,
    required this.nextStepLabelGu,
    required this.steps,
    this.primaryTabIndex,
    this.relatedHelpTopicIds = const <String>[],
  });

  final String id;
  final int order;
  final String screenId;
  final String routePath;
  final int? primaryTabIndex;
  final String iconKey;
  final String titleEn;
  final String titleGu;
  final String summaryEn;
  final String summaryGu;
  final String nextStepLabelEn;
  final String nextStepLabelGu;
  final List<GuideStep> steps;
  final List<String> relatedHelpTopicIds;

  String title(String localeCode) => localeCode == 'gu' ? titleGu : titleEn;

  String summary(String localeCode) =>
      localeCode == 'gu' ? summaryGu : summaryEn;

  String nextStepLabel(String localeCode) =>
      localeCode == 'gu' ? nextStepLabelGu : nextStepLabelEn;
}

/// Link metadata connecting a static HelpTopic in `StitchFlowHelpCatalog` to
/// a live interactive screen tour and the next recommended workflow topic.
final class HelpTopicActionLink {
  const HelpTopicActionLink({
    required this.topicId,
    required this.chapterId,
    required this.liveRoutePath,
    required this.liveScreenId,
    this.nextTopicId,
    this.primaryTabIndex,
  });

  final String topicId;
  final String chapterId;
  final String liveRoutePath;
  final String liveScreenId;
  final String? nextTopicId;
  final int? primaryTabIndex;
}

/// Persisted local guidance preferences & training completion progress.
final class GuideProgress {
  const GuideProgress({
    this.welcomeDismissed = false,
    this.voiceEnabled = true,
    this.speechRate = GuideSpeechRate.normal,
    this.showNewScreenHints = true,
    this.completedChapterIds = const <String>{},
    this.visitedScreenIds = const <String>{},
    this.lastChapterIndex = 0,
    this.journeyCompleted = false,
  });

  final bool welcomeDismissed;
  final bool voiceEnabled;
  final GuideSpeechRate speechRate;
  final bool showNewScreenHints;
  final Set<String> completedChapterIds;
  final Set<String> visitedScreenIds;
  final int lastChapterIndex;
  final bool journeyCompleted;

  GuideProgress copyWith({
    bool? welcomeDismissed,
    bool? voiceEnabled,
    GuideSpeechRate? speechRate,
    bool? showNewScreenHints,
    Set<String>? completedChapterIds,
    Set<String>? visitedScreenIds,
    int? lastChapterIndex,
    bool? journeyCompleted,
  }) {
    return GuideProgress(
      welcomeDismissed: welcomeDismissed ?? this.welcomeDismissed,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      speechRate: speechRate ?? this.speechRate,
      showNewScreenHints: showNewScreenHints ?? this.showNewScreenHints,
      completedChapterIds: completedChapterIds ?? this.completedChapterIds,
      visitedScreenIds: visitedScreenIds ?? this.visitedScreenIds,
      lastChapterIndex: lastChapterIndex ?? this.lastChapterIndex,
      journeyCompleted: journeyCompleted ?? this.journeyCompleted,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'welcomeDismissed': welcomeDismissed,
    'voiceEnabled': voiceEnabled,
    'speechRate': speechRate.storageValue,
    'showNewScreenHints': showNewScreenHints,
    'completedChapterIds': completedChapterIds.toList(),
    'visitedScreenIds': visitedScreenIds.toList(),
    'lastChapterIndex': lastChapterIndex,
    'journeyCompleted': journeyCompleted,
  };

  factory GuideProgress.fromJson(Map<String, Object?> json) {
    Set<String> readSet(String key) {
      final raw = json[key];
      if (raw is List) {
        return raw.whereType<String>().toSet();
      }
      return <String>{};
    }

    return GuideProgress(
      welcomeDismissed: json['welcomeDismissed'] == true,
      voiceEnabled: json['voiceEnabled'] != false,
      speechRate: GuideSpeechRate.fromStorage(json['speechRate'] as String?),
      showNewScreenHints: json['showNewScreenHints'] != false,
      completedChapterIds: readSet('completedChapterIds'),
      visitedScreenIds: readSet('visitedScreenIds'),
      lastChapterIndex: (json['lastChapterIndex'] as num?)?.toInt() ?? 0,
      journeyCompleted: json['journeyCompleted'] == true,
    );
  }
}
