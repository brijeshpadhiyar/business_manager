/// The 5 local offline Android notification categories in StitchFlow V1.2.
enum NotificationCategory {
  pendingWork(1001, 'sf_pending_work'),
  workerSettlement(1002, 'sf_worker_settlement'),
  dailySummary(1003, 'sf_daily_summary'),
  backupReminder(1004, 'sf_backup_reminder'),
  businessAlerts(1005, 'sf_business_alerts');

  const NotificationCategory(this.notificationId, this.channelId);

  final int notificationId;
  final String channelId;
}

/// Android notification permission state.
enum NotificationPermissionStatus { granted, denied, notRequested, unsupported }

/// User-configurable local reminder preferences stored per flavor in SharedPreferences.
final class NotificationSettings {
  const NotificationSettings({
    this.masterEnabled = true,
    this.pendingWorkEnabled = true,
    this.pendingWorkDaysThreshold = 3,
    this.pendingWorkHour = 10,
    this.pendingWorkMinute = 0,
    this.workerSettlementEnabled = true,
    this.workerSettlementWeekday = DateTime.saturday,
    this.workerSettlementHour = 18,
    this.workerSettlementMinute = 0,
    this.workerSettlementMinPaise = 50000, // ₹500
    this.dailySummaryEnabled = true,
    this.dailySummaryHour = 20,
    this.dailySummaryMinute = 0,
    this.dailySummarySkipQuietDays = true,
    this.backupReminderEnabled = true,
    this.backupReminderIntervalDays = 7,
    this.backupReminderHour = 20,
    this.backupReminderMinute = 30,
    this.businessAlertsEnabled = true,
    this.damagedAlertThreshold = 20,
    this.overdueAlertDays = 14,
  });

  final bool masterEnabled;
  final bool pendingWorkEnabled;
  final int pendingWorkDaysThreshold;
  final int pendingWorkHour;
  final int pendingWorkMinute;

  final bool workerSettlementEnabled;
  final int workerSettlementWeekday; // 1 = Mon ... 7 = Sun
  final int workerSettlementHour;
  final int workerSettlementMinute;
  final int workerSettlementMinPaise;

  final bool dailySummaryEnabled;
  final int dailySummaryHour;
  final int dailySummaryMinute;
  final bool dailySummarySkipQuietDays;

  final bool backupReminderEnabled;
  final int backupReminderIntervalDays;
  final int backupReminderHour;
  final int backupReminderMinute;

  final bool businessAlertsEnabled;
  final int damagedAlertThreshold;
  final int overdueAlertDays;

  NotificationSettings copyWith({
    bool? masterEnabled,
    bool? pendingWorkEnabled,
    int? pendingWorkDaysThreshold,
    int? pendingWorkHour,
    int? pendingWorkMinute,
    bool? workerSettlementEnabled,
    int? workerSettlementWeekday,
    int? workerSettlementHour,
    int? workerSettlementMinute,
    int? workerSettlementMinPaise,
    bool? dailySummaryEnabled,
    int? dailySummaryHour,
    int? dailySummaryMinute,
    bool? dailySummarySkipQuietDays,
    bool? backupReminderEnabled,
    int? backupReminderIntervalDays,
    int? backupReminderHour,
    int? backupReminderMinute,
    bool? businessAlertsEnabled,
    int? damagedAlertThreshold,
    int? overdueAlertDays,
  }) {
    return NotificationSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      pendingWorkEnabled: pendingWorkEnabled ?? this.pendingWorkEnabled,
      pendingWorkDaysThreshold:
          pendingWorkDaysThreshold ?? this.pendingWorkDaysThreshold,
      pendingWorkHour: pendingWorkHour ?? this.pendingWorkHour,
      pendingWorkMinute: pendingWorkMinute ?? this.pendingWorkMinute,
      workerSettlementEnabled:
          workerSettlementEnabled ?? this.workerSettlementEnabled,
      workerSettlementWeekday:
          workerSettlementWeekday ?? this.workerSettlementWeekday,
      workerSettlementHour: workerSettlementHour ?? this.workerSettlementHour,
      workerSettlementMinute:
          workerSettlementMinute ?? this.workerSettlementMinute,
      workerSettlementMinPaise:
          workerSettlementMinPaise ?? this.workerSettlementMinPaise,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      dailySummaryHour: dailySummaryHour ?? this.dailySummaryHour,
      dailySummaryMinute: dailySummaryMinute ?? this.dailySummaryMinute,
      dailySummarySkipQuietDays:
          dailySummarySkipQuietDays ?? this.dailySummarySkipQuietDays,
      backupReminderEnabled:
          backupReminderEnabled ?? this.backupReminderEnabled,
      backupReminderIntervalDays:
          backupReminderIntervalDays ?? this.backupReminderIntervalDays,
      backupReminderHour: backupReminderHour ?? this.backupReminderHour,
      backupReminderMinute: backupReminderMinute ?? this.backupReminderMinute,
      businessAlertsEnabled:
          businessAlertsEnabled ?? this.businessAlertsEnabled,
      damagedAlertThreshold:
          damagedAlertThreshold ?? this.damagedAlertThreshold,
      overdueAlertDays: overdueAlertDays ?? this.overdueAlertDays,
    );
  }
}

/// Deterministic scheduled or immediate local notification emitted by [NotificationPlanCalculator].
final class PlannedLocalNotification {
  const PlannedLocalNotification({
    required this.id,
    required this.category,
    required this.channelId,
    required this.scheduledAtUtcMillis,
    required this.title,
    required this.body,
    required this.payloadRoute,
    this.isImmediateAlert = false,
    this.privacyPrivate = false,
  });

  final int id;
  final NotificationCategory category;
  final String channelId;
  final int scheduledAtUtcMillis;
  final String title;
  final String body;
  final String payloadRoute;
  final bool isImmediateAlert;
  final bool privacyPrivate;
}

/// Complete reconciliation plan: exact notifications to schedule/fire + exact IDs to cancel.
final class NotificationSyncPlan {
  const NotificationSyncPlan({
    required this.planned,
    required this.idsToCancel,
    required this.digest,
    this.firedAlertCooldownKey,
  });

  final List<PlannedLocalNotification> planned;
  final Set<int> idsToCancel;
  final String digest;
  final String? firedAlertCooldownKey;
}
