import 'dart:async';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:business_manager/features/notifications/data/repositories/notification_settings_repository.dart';
import 'package:business_manager/features/notifications/domain/calculators/notification_plan_calculator.dart';
import 'package:business_manager/features/notifications/domain/entities/notification_entities.dart';
import 'package:business_manager/features/notifications/domain/services/local_notification_service.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:business_manager/features/reports/domain/repositories/reports_repository.dart';
import 'package:business_manager/features/security/domain/repositories/security_repository.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:injectable/injectable.dart';

/// Reconciles live workshop SQLite state into deterministic local Android
/// notifications (idempotent, deduplicated, lock-screen privacy aware).
@lazySingleton
final class NotificationRefreshCoordinator {
  NotificationRefreshCoordinator(
    this._db,
    this._stockRepo,
    this._accountingRepo,
    this._reportsRepo,
    this._securityRepo,
    this._localeCubit,
    this._settingsRepo,
    this._notificationService,
  );

  final AppDatabase _db;
  final StockMovementRepository _stockRepo;
  final AccountingRepository _accountingRepo;
  final ReportsRepository _reportsRepo;
  final SecurityRepository _securityRepo;
  final LocaleCubit _localeCubit;
  final NotificationSettingsRepository _settingsRepo;
  final LocalNotificationService _notificationService;

  static const NotificationPlanCalculator _calculator =
      NotificationPlanCalculator();

  bool _refreshInFlight = false;

  /// Cycle-free global trigger safe to call from repositories, backup services,
  /// and cubits without introducing DI circular dependencies.
  static void requestBackgroundRefreshIfRegistered({
    bool forceReschedule = false,
  }) {
    if (getIt.isRegistered<NotificationRefreshCoordinator>()) {
      getIt<NotificationRefreshCoordinator>().triggerBackgroundRefresh(
        forceReschedule: forceReschedule,
      );
    }
  }

  /// Fire-and-forget non-blocking trigger called after stock, payment, backup,
  /// restore, security, or locale updates.
  void triggerBackgroundRefresh({bool forceReschedule = false}) {
    unawaited(refreshIfPermitted(forceReschedule: forceReschedule));
  }

  /// Re-evaluates all 5 notification categories against current SQLite data and
  /// syncs only if permission is granted and the plan digest changed.
  Future<NotificationSyncPlan?> refreshIfPermitted({
    bool forceReschedule = false,
    int? nowUtcMillis,
  }) async {
    if (_refreshInFlight) return null;
    _refreshInFlight = true;
    try {
      final perm = await _notificationService.checkPermissionStatus();
      if (perm != NotificationPermissionStatus.granted) {
        if (perm == NotificationPermissionStatus.denied) {
          await _notificationService.cancelAll();
          await _settingsRepo.clearLastPlanDigest();
        }
        return null;
      }

      final settings = await _settingsRepo.loadSettings();
      final nowUtc = nowUtcMillis ?? IstDateTimeHelper.nowUtcMillis();
      final security = await _securityRepo.loadSettings();
      final localeCode =
          _localeCubit.state.preference.locale?.languageCode ?? 'en';

      final openIssues = await _stockRepo.getOpenIssues();
      final workerFinancials = await _accountingRepo.getAllWorkerSummaries();
      final partySummaries = getIt.isRegistered<PartyRepository>()
          ? await getIt<PartyRepository>().getAllPartySummaries(
              includeInactive: false,
            )
          : const <PartyFinancialSummary>[];
      final todaySummary = await _reportsRepo.getDailyWorkshopSummary(
        targetDayUtcMillis: nowUtc,
      );
      final lastBackupAudit = await _db.attachmentAuditDao
          .getLatestAuditByAction('BACKUP_EXPORT');
      final lastAlert = await _settingsRepo.getLastAlertCooldown();

      final plan = _calculator.computePlan(
        settings: settings,
        nowUtcMillis: nowUtc,
        localeCode: localeCode,
        isAppLockEnabled: security.pinEnabled,
        openIssues: openIssues,
        workerFinancials: workerFinancials,
        partySummaries: partySummaries,
        hasActivityToday: todaySummary.hasAnyActivity,
        todayIssuedQty: todaySummary.issuedQty,
        todayReturnedGoodQty: todaySummary.goodReturnedQty,
        totalDamagedQty: todaySummary.currentTotalDamagedQty,
        lastBackupExportUtcMillis: lastBackupAudit?.recordedAt,
        lastAlertFiredAtUtcMillis: lastAlert.firedAtUtcMillis,
        lastAlertCooldownKey: lastAlert.key,
      );

      final lastDigest = await _settingsRepo.getLastPlanDigest();
      if (!forceReschedule &&
          lastDigest == plan.digest &&
          plan.firedAlertCooldownKey == null) {
        return plan;
      }

      await _notificationService.syncPlan(plan);
      await _settingsRepo.setLastPlanDigest(plan.digest);

      if (plan.firedAlertCooldownKey != null) {
        await _settingsRepo.recordAlertCooldown(
          firedAtUtcMillis: nowUtc,
          key: plan.firedAlertCooldownKey!,
        );
      }

      return plan;
    } catch (_) {
      // Notifications must never destabilize core workshop operations.
      return null;
    } finally {
      _refreshInFlight = false;
    }
  }
}
