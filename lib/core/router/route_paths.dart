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
}
