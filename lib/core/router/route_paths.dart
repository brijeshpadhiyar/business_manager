abstract final class RoutePaths {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String lots = '/lots';
  static const String workers = '/workers';
  static const String designsColours = '/designs-colours';
  static const String lotCreate = '/lots/new';
  static const String lotDetailPattern = '/lots/:id';
  static const String lotColourDetailPattern = '/lots/:id/colours/:colourId';
  static const String lotRoutingPattern = '/lots/:id/routing';

  // Processes & Inventory standalone routes (clean back navigation from Dashboard/Settings)
  static const String processes = '/processes';
  static const String inventory = '/inventory';

  // Milestone 5 — Processes, Workers, Assignments & Historical Rates
  static const String processCreate = '/processes/new';
  static const String processDetailPattern = '/processes/:id';
  static const String processEditPattern = '/processes/:id/edit';

  static const String workerCreate = '/workers/new';
  static const String workerDetailPattern = '/workers/:id';
  static const String workerEditPattern = '/workers/:id/edit';
  static const String workerAssignmentsPattern = '/workers/:id/assignments';
  static const String workerRatesPattern = '/workers/:id/rates';
  static const String workerRateCreatePattern = '/workers/:id/rates/new';
  static const String workerRateEditPattern = '/workers/:id/rates/:rateId/edit';

  // Stock Movements & Redesigned Issue / Return Workflows
  static const String stockMovements = '/stock';
  static const String stockIssuePath = '/stock/issue';
  static const String stockReturnPicker = '/stock/return';
  static const String stockReturnPattern = '/stock/return/:issueId';
  static const String stockRepair = '/stock/repair';

  // Milestone 7 — Labour, Worker Ledger & Payments
  static const String accounting = '/accounting';
  static const String workerLedgerPattern = '/workers/:id/ledger';
  static const String paymentCreatePath = '/payments/new';
  static const String workerAdjustmentCreatePattern =
      '/workers/:id/adjustments/new';

  // Milestone 8 — Backup & Restore (kept as alias alongside Settings)
  static const String backupRestore = '/backup';

  // Milestone 9 — Reports
  static const String reports = '/reports';

  // V1.1 — Centralized Settings & Help Hub
  static const String settings = '/settings';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsBusinessProfile = '/settings/business-profile';
  static const String settingsStockLabour = '/settings/stock-labour';
  static const String settingsSecurity = '/settings/security';
  static const String settingsSecurityPinSetup = '/settings/security/pin-setup';
  static const String settingsSecurityPinChange =
      '/settings/security/pin-change';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsBackup = '/settings/backup';
  static const String settingsHelp = '/settings/help';
  static const String settingsHelpTopicPattern = '/settings/help/:topicId';
  static const String settingsAbout = '/settings/about';

  // V1.5 — Cloud Auth (Google + Phone OTP) & Offline-First Sync Center
  static const String authLogin = '/auth/login';
  static const String settingsAccount = '/settings/account';
  static const String settingsSync = '/settings/sync';
  static const String settingsDataHealth = '/settings/data-health';
  static const String settingsTeam = '/settings/team';
  static const String settingsSyncConflicts = '/settings/sync/conflicts';

  // V1.2 — Daily Production Summary
  static const String dailySummary = '/daily-summary';

  // V1.4 — Complete Production History, Lot Tracking, QC Inspection & Ledger
  static const String productionHistory = '/history';
  static const String lotHistoryPattern = '/lots/:id/history';
  static const String lotTimelinePattern = '/lots/:id/timeline';
  static const String workerProductionHistory = '/history/workers';
  static const String processProductionHistory = '/history/processes';
  static const String inspectionQueue = '/stock/inspections';
  static const String productionTransactionDetailPattern =
      '/history/tx/:kind/:id';

  static String lotDetail(String lotId) => '/lots/$lotId';
  static String lotHistory(String lotId) => '/lots/$lotId/history';
  static String lotTimeline(String lotId) => '/lots/$lotId/timeline';
  static String productionTransactionDetail(String kindSegment, String id) =>
      '/history/tx/${Uri.encodeComponent(kindSegment)}/${Uri.encodeComponent(id)}';
  static String lotColourDetail(String lotId, String colourId) =>
      '/lots/$lotId/colours/$colourId';
  static String lotRouting(String lotId, {String? designColourId}) {
    final base = '/lots/$lotId/routing';
    return designColourId != null
        ? '$base?colourId=${Uri.encodeQueryComponent(designColourId)}'
        : base;
  }

  static String processDetail(String processId) => '/processes/$processId';
  static String processEdit(String processId) => '/processes/$processId/edit';

  static String workerDetail(String workerId) => '/workers/$workerId';
  static String workerEdit(String workerId) => '/workers/$workerId/edit';
  static String workerAssignments(String workerId) =>
      '/workers/$workerId/assignments';

  static String workerRates(String workerId, {String? processId}) {
    final base = '/workers/$workerId/rates';
    return processId != null ? '$base?processId=$processId' : base;
  }

  static String workerRateCreate(String workerId, {String? processId}) {
    final base = '/workers/$workerId/rates/new';
    return processId != null ? '$base?processId=$processId' : base;
  }

  static String workerRateEdit(String workerId, String rateId) =>
      '/workers/$workerId/rates/$rateId/edit';

  static String stockIssue({
    String? designColourId,
    String? processId,
    String? workerId,
  }) {
    final params = <String, String>{};
    if (designColourId != null) params['designColourId'] = designColourId;
    if (processId != null) params['processId'] = processId;
    if (workerId != null) params['workerId'] = workerId;
    if (params.isEmpty) return stockIssuePath;
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$stockIssuePath?$qs';
  }

  static String stockReturnPickerFiltered({
    String? workerId,
    String? processId,
    String? lotId,
  }) {
    final params = <String, String>{};
    if (workerId != null) params['workerId'] = workerId;
    if (processId != null) params['processId'] = processId;
    if (lotId != null) params['lotId'] = lotId;
    if (params.isEmpty) return stockReturnPicker;
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$stockReturnPicker?$qs';
  }

  static String stockReturn(String issueId) => '/stock/return/$issueId';

  static String workerLedger(String workerId) => '/workers/$workerId/ledger';

  static String paymentCreate({String? workerId}) {
    return workerId != null
        ? '$paymentCreatePath?workerId=$workerId'
        : paymentCreatePath;
  }

  static String workerAdjustmentCreate(String workerId) =>
      '/workers/$workerId/adjustments/new';

  // V1.9 — Parties / Buyers, Dispatch Challans, Buyer Returns & Party Khata
  static const String parties = '/parties';
  static const String partyCreate = '/parties/new';
  static const String partyDetailPattern = '/parties/:id';
  static const String partyEditPattern = '/parties/:id/edit';
  static const String partyReturnPattern = '/parties/:id/return';
  static const String partyPaymentPattern = '/parties/:id/payment';
  static const String dispatchCreatePath = '/dispatch/new';
  static const String dispatchDetailPattern = '/dispatch/:id';

  static String partyDetail(String partyId) => '/parties/$partyId';
  static String partyEdit(String partyId) => '/parties/$partyId/edit';
  static String partyReturn(String partyId, {String? challanId}) =>
      challanId != null
          ? '/parties/$partyId/return?challanId=${Uri.encodeQueryComponent(challanId)}'
          : '/parties/$partyId/return';
  static String partyPayment(String partyId) => '/parties/$partyId/payment';
  static String dispatchCreate({String? partyId, String? lotId}) {
    final params = <String, String>{};
    if (partyId != null) params['partyId'] = partyId;
    if (lotId != null) params['lotId'] = lotId;
    if (params.isEmpty) return dispatchCreatePath;
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$dispatchCreatePath?$qs';
  }
  static String dispatchDetail(String challanId) => '/dispatch/$challanId';

  // V2.1 — Workshop Expenses & Unified Cash/Bank Book
  static const String cashbook = '/cashbook';
  static const String expenseCreate = '/cashbook/expense/new';
  static const String cashbookTransferCreate = '/cashbook/transfer/new';

  static String settingsHelpTopic(String topicId) => '/settings/help/$topicId';
}
