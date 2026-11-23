import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/notifications/domain/entities/notification_entities.dart';
import 'package:business_manager/features/reports/domain/calculators/workshop_daily_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:timezone/timezone.dart' as tz;

/// Pure-Dart deterministic local notification planner for StitchFlow V1.2.
///
/// Guarantees:
/// - Schedules strictly in `Asia/Kolkata` (IST).
/// - Deterministic notification IDs (`1001..1005`) prevent duplicate spam.
/// - Cancels reminders automatically when underlying work/payments are settled.
/// - Redacts Rupee amounts and worker names on lock screens whenever App Lock PIN is ON.
/// - Enforces strict route allowlist for notification tap deep links.
final class NotificationPlanCalculator {
  const NotificationPlanCalculator();

  static const int _cooldown24hMs = 24 * 60 * 60 * 1000;
  static const int _millisPerDay = 86400000;

  /// Strict allowlist of routes permitted from notification tap payloads.
  static const Set<String> allowedDeepLinkRoutes = {
    RoutePaths.stockReturnPicker,
    RoutePaths.stockRepair,
    RoutePaths.accounting,
    RoutePaths.dailySummary,
    RoutePaths.settingsBackup,
  };

  static bool isAllowedDeepLinkRoute(String? route) {
    if (route == null || route.isEmpty) return false;
    return allowedDeepLinkRoutes.contains(route);
  }

  NotificationSyncPlan computePlan({
    required NotificationSettings settings,
    required int nowUtcMillis,
    required String localeCode,
    required bool isAppLockEnabled,
    required List<OpenIssueSummary> openIssues,
    required List<WorkerFinancialSummary> workerFinancials,
    required bool hasActivityToday,
    required int todayIssuedQty,
    required int todayReturnedGoodQty,
    required int totalDamagedQty,
    required int? lastBackupExportUtcMillis,
    int? lastAlertFiredAtUtcMillis,
    String? lastAlertCooldownKey,
  }) {
    final allIds = {
      for (final c in NotificationCategory.values) c.notificationId,
    };
    if (!settings.masterEnabled) {
      return NotificationSyncPlan(
        planned: const [],
        idsToCancel: allIds,
        digest: 'MASTER_OFF',
      );
    }

    final isGu = localeCode == 'gu';
    final planned = <PlannedLocalNotification>[];
    final idsToCancel = <int>{};
    String? firedAlertKey;

    // -------------------------------------------------------------------------
    // 1001: Pending Work Reminder (Daily @ configured IST time)
    // -------------------------------------------------------------------------
    if (!settings.pendingWorkEnabled) {
      idsToCancel.add(NotificationCategory.pendingWork.notificationId);
    } else {
      final overdue = openIssues.where((issue) {
        final age = WorkshopDailyCalculator.pendingAgeDays(
          issue.issueView.movement.transactionAt,
          nowUtcMillis,
        );
        return age >= settings.pendingWorkDaysThreshold;
      }).toList();

      if (overdue.isEmpty) {
        idsToCancel.add(NotificationCategory.pendingWork.notificationId);
      } else {
        final totalPendingPcs = overdue.fold<int>(
          0,
          (s, i) => s + i.remainingPending,
        );
        final nextUtc = _nextDailyIstOccurrence(
          nowUtcMillis: nowUtcMillis,
          hour: settings.pendingWorkHour,
          minute: settings.pendingWorkMinute,
        );
        final title = isGu
            ? 'બાકી કામની યાદ અપાવણી'
            : 'Pending Workshop Returns';
        final body = isAppLockEnabled
            ? (isGu
                  ? '${overdue.length} બાકી ઇશ્યૂ ${settings.pendingWorkDaysThreshold}+ દિવસથી પેન્ડિંગ છે.'
                  : '${overdue.length} pending workshop returns need follow-up.')
            : (isGu
                  ? '${overdue.length} ઇશ્યૂ ($totalPendingPcs પીસ) ${settings.pendingWorkDaysThreshold}+ દિવસથી બાકી છે.'
                  : '${overdue.length} open issues ($totalPendingPcs pcs) have been pending ${settings.pendingWorkDaysThreshold}+ days.');

        planned.add(
          PlannedLocalNotification(
            id: NotificationCategory.pendingWork.notificationId,
            category: NotificationCategory.pendingWork,
            channelId: NotificationCategory.pendingWork.channelId,
            scheduledAtUtcMillis: nextUtc,
            title: title,
            body: body,
            payloadRoute: RoutePaths.stockReturnPicker,
            privacyPrivate: isAppLockEnabled,
          ),
        );
      }
    }

    // -------------------------------------------------------------------------
    // 1002: Worker Settlement Reminder (Weekly @ configured weekday & IST time)
    // -------------------------------------------------------------------------
    if (!settings.workerSettlementEnabled) {
      idsToCancel.add(NotificationCategory.workerSettlement.notificationId);
    } else {
      final dueWorkers = workerFinancials
          .where(
            (w) =>
                w.outstandingPayablePaise >= settings.workerSettlementMinPaise,
          )
          .toList();

      if (dueWorkers.isEmpty) {
        idsToCancel.add(NotificationCategory.workerSettlement.notificationId);
      } else {
        final totalDuePaise = dueWorkers.fold<int>(
          0,
          (s, w) => s + w.outstandingPayablePaise,
        );
        final nextUtc = _nextWeeklyIstOccurrence(
          nowUtcMillis: nowUtcMillis,
          weekday: settings.workerSettlementWeekday,
          hour: settings.workerSettlementHour,
          minute: settings.workerSettlementMinute,
        );
        final title = isGu
            ? 'કારીગર હિસાબ ચુકવણી યાદ'
            : 'Worker Settlement Reminder';
        final body = isAppLockEnabled
            ? (isGu
                  ? '${dueWorkers.length} કારીગરોના બાકી હિસાબ તપાસવાના બાકી છે.'
                  : '${dueWorkers.length} workers have pending settlements to review.')
            : (isGu
                  ? '${dueWorkers.length} કારીગરોનું કુલ ${MoneyFormatter.formatPaise(totalDuePaise)} બાકી છે.'
                  : '${dueWorkers.length} workers have ${MoneyFormatter.formatPaise(totalDuePaise)} outstanding payable.');

        planned.add(
          PlannedLocalNotification(
            id: NotificationCategory.workerSettlement.notificationId,
            category: NotificationCategory.workerSettlement,
            channelId: NotificationCategory.workerSettlement.channelId,
            scheduledAtUtcMillis: nextUtc,
            title: title,
            body: body,
            payloadRoute: RoutePaths.accounting,
            privacyPrivate: isAppLockEnabled,
          ),
        );
      }
    }

    // -------------------------------------------------------------------------
    // 1003: Daily Workshop Summary (Daily @ configured IST evening time)
    // -------------------------------------------------------------------------
    if (!settings.dailySummaryEnabled ||
        (settings.dailySummarySkipQuietDays && !hasActivityToday)) {
      idsToCancel.add(NotificationCategory.dailySummary.notificationId);
    } else {
      final nextUtc = _nextDailyIstOccurrence(
        nowUtcMillis: nowUtcMillis,
        hour: settings.dailySummaryHour,
        minute: settings.dailySummaryMinute,
      );
      final title = isGu ? 'આજનો વર્કશોપ સારાંશ' : 'Daily Workshop Summary';
      final body = isAppLockEnabled
          ? (isGu
                ? 'આજની વર્કશોપ પ્રવૃત્તિનો સારાંશ જોવા માટે ટેપ કરો.'
                : 'Tap to review today\'s workshop production summary.')
          : (isGu
                ? 'આજે ઇશ્યુ: $todayIssuedQty પીસ • સારા પરત: $todayReturnedGoodQty પીસ.'
                : 'Today: $todayIssuedQty pcs issued • $todayReturnedGoodQty pcs good returned.');

      planned.add(
        PlannedLocalNotification(
          id: NotificationCategory.dailySummary.notificationId,
          category: NotificationCategory.dailySummary,
          channelId: NotificationCategory.dailySummary.channelId,
          scheduledAtUtcMillis: nextUtc,
          title: title,
          body: body,
          payloadRoute: RoutePaths.dailySummary,
          privacyPrivate: isAppLockEnabled,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 1004: Backup Reminder (Every N days from latest BACKUP_EXPORT)
    // -------------------------------------------------------------------------
    if (!settings.backupReminderEnabled) {
      idsToCancel.add(NotificationCategory.backupReminder.notificationId);
    } else {
      final intervalMs = settings.backupReminderIntervalDays * _millisPerDay;
      final dueBaseUtc =
          (lastBackupExportUtcMillis ?? nowUtcMillis) + intervalMs;
      final dueIst = IstDateTimeHelper.fromUtcMillisToIst(dueBaseUtc);
      var scheduledUtc = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: dueIst.year,
        month: dueIst.month,
        day: dueIst.day,
        hour: settings.backupReminderHour,
        minute: settings.backupReminderMinute,
      );
      if (scheduledUtc <= nowUtcMillis) {
        // Backup is overdue: schedule at next reminder time today or tomorrow
        scheduledUtc = _nextDailyIstOccurrence(
          nowUtcMillis: nowUtcMillis,
          hour: settings.backupReminderHour,
          minute: settings.backupReminderMinute,
        );
      }

      final title = isGu
          ? 'ઓફલાઇન બેકઅપ યાદ અપાવણી'
          : 'Offline Backup Reminder';
      final body = isGu
          ? 'તમારા વર્કશોપ ડેટાનો સુરક્ષિત .zip બેકઅપ લેવાનો સમય થઈ ગયો છે.'
          : 'It is time to save a fresh offline StitchFlow .zip backup.';

      planned.add(
        PlannedLocalNotification(
          id: NotificationCategory.backupReminder.notificationId,
          category: NotificationCategory.backupReminder,
          channelId: NotificationCategory.backupReminder.channelId,
          scheduledAtUtcMillis: scheduledUtc,
          title: title,
          body: body,
          payloadRoute: RoutePaths.settingsBackup,
          privacyPrivate: isAppLockEnabled,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 1005: Important Local Business Alerts (24h dedupe cooldown)
    // -------------------------------------------------------------------------
    if (!settings.businessAlertsEnabled) {
      idsToCancel.add(NotificationCategory.businessAlerts.notificationId);
    } else {
      final severeOverdueCount = openIssues.where((i) {
        final age = WorkshopDailyCalculator.pendingAgeDays(
          i.issueView.movement.transactionAt,
          nowUtcMillis,
        );
        return age >= settings.overdueAlertDays;
      }).length;
      final highDamage = totalDamagedQty >= settings.damagedAlertThreshold;

      if (!highDamage && severeOverdueCount == 0) {
        idsToCancel.add(NotificationCategory.businessAlerts.notificationId);
      } else {
        final alertKey = highDamage
            ? 'damaged_${settings.damagedAlertThreshold}'
            : 'overdue_${settings.overdueAlertDays}';
        final withinCooldown =
            lastAlertCooldownKey == alertKey &&
            lastAlertFiredAtUtcMillis != null &&
            (nowUtcMillis - lastAlertFiredAtUtcMillis) < _cooldown24hMs;

        if (!withinCooldown) {
          firedAlertKey = alertKey;
          final title = isGu
              ? 'મહત્વપૂર્ણ વર્કશોપ ચેતવણી'
              : 'Important Workshop Alert';
          final String body;
          final String route;
          if (highDamage) {
            route = RoutePaths.stockRepair;
            body = isAppLockEnabled
                ? (isGu
                      ? 'નુકસાન સ્ટોક મર્યાદા કરતાં વધુ છે. તપાસ માટે ટેપ કરો.'
                      : 'Damaged stock has crossed your alert threshold. Tap to review.')
                : (isGu
                      ? 'નુકસાન સ્ટોક $totalDamagedQty પીસ થયો છે (મર્યાદા: ${settings.damagedAlertThreshold}).'
                      : 'Damaged stock reached $totalDamagedQty pcs (threshold: ${settings.damagedAlertThreshold}).');
          } else {
            route = RoutePaths.stockReturnPicker;
            body = isGu
                ? '$severeOverdueCount ઇશ્યૂ ${settings.overdueAlertDays}+ દિવસથી વધુ સમયથી બાકી છે.'
                : '$severeOverdueCount open issues are overdue by ${settings.overdueAlertDays}+ days.';
          }

          planned.add(
            PlannedLocalNotification(
              id: NotificationCategory.businessAlerts.notificationId,
              category: NotificationCategory.businessAlerts,
              channelId: NotificationCategory.businessAlerts.channelId,
              scheduledAtUtcMillis: nowUtcMillis,
              title: title,
              body: body,
              payloadRoute: route,
              isImmediateAlert: true,
              privacyPrivate: isAppLockEnabled,
            ),
          );
        }
      }
    }

    // Build deterministic digest so identical plans skip redundant OS AlarmManager writes
    final digestBuf = StringBuffer()
      ..write('C:${(idsToCancel.toList()..sort()).join(',')}|');
    for (final p in planned) {
      digestBuf.write(
        '${p.id}@${p.scheduledAtUtcMillis}:${p.title}:${p.body}:${p.payloadRoute}:${p.isImmediateAlert}:${p.privacyPrivate}|',
      );
    }

    return NotificationSyncPlan(
      planned: planned,
      idsToCancel: idsToCancel,
      digest: digestBuf.toString(),
      firedAlertCooldownKey: firedAlertKey,
    );
  }

  /// Next occurrence of `(hour, minute)` in `Asia/Kolkata` strictly after [nowUtcMillis].
  static int _nextDailyIstOccurrence({
    required int nowUtcMillis,
    required int hour,
    required int minute,
  }) {
    final nowIst = IstDateTimeHelper.fromUtcMillisToIst(nowUtcMillis);
    var candidate = tz.TZDateTime(
      IstDateTimeHelper.istLocation,
      nowIst.year,
      nowIst.month,
      nowIst.day,
      hour,
      minute,
    );
    if (!candidate.isAfter(nowIst)) {
      candidate = tz.TZDateTime(
        IstDateTimeHelper.istLocation,
        nowIst.year,
        nowIst.month,
        nowIst.day + 1,
        hour,
        minute,
      );
    }
    return candidate.toUtc().millisecondsSinceEpoch;
  }

  /// Next occurrence of `(weekday, hour, minute)` in `Asia/Kolkata` strictly after [nowUtcMillis].
  static int _nextWeeklyIstOccurrence({
    required int nowUtcMillis,
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final nowIst = IstDateTimeHelper.fromUtcMillisToIst(nowUtcMillis);
    var daysUntil = (weekday - nowIst.weekday) % 7;
    if (daysUntil < 0) daysUntil += 7;
    var candidate = tz.TZDateTime(
      IstDateTimeHelper.istLocation,
      nowIst.year,
      nowIst.month,
      nowIst.day + daysUntil,
      hour,
      minute,
    );
    if (!candidate.isAfter(nowIst)) {
      candidate = tz.TZDateTime(
        IstDateTimeHelper.istLocation,
        candidate.year,
        candidate.month,
        candidate.day + 7,
        hour,
        minute,
      );
    }
    return candidate.toUtc().millisecondsSinceEpoch;
  }
}
