abstract final class RoutePaths {
  static const String home = '/';
  static const String showcase = '/showcase';
  static const String lotDetailPattern = '/lots/:id';

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

  // Milestone 6 — Stock Movements
  static const String stockMovements = '/stock';
  static const String stockIssuePath = '/stock/issue';
  static const String stockReturnPattern = '/stock/return/:issueId';
  static const String stockRepair = '/stock/repair';

  // Milestone 7 — Labour, Worker Ledger & Payments
  static const String accounting = '/accounting';
  static const String workerLedgerPattern = '/workers/:id/ledger';
  static const String paymentCreatePath = '/payments/new';
  static const String workerAdjustmentCreatePattern =
      '/workers/:id/adjustments/new';

  // Milestone 8 — Backup & Restore
  static const String backupRestore = '/backup';

  // Milestone 9 — Reports
  static const String reports = '/reports';

  static String lotDetail(String lotId) => '/lots/$lotId';
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

  static String stockIssue({String? designColourId}) {
    return designColourId != null
        ? '$stockIssuePath?designColourId=$designColourId'
        : stockIssuePath;
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
}
