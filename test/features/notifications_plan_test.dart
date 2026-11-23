import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/notifications/domain/calculators/notification_plan_calculator.dart';
import 'package:business_manager/features/notifications/domain/entities/notification_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  const calc = NotificationPlanCalculator();

  OpenIssueSummary mkOpenIssue({
    required String id,
    required int issuedTxAt,
    required int remainingPending,
  }) {
    final move = StockMovementEntity(
      id: id,
      lotId: 'l1',
      lotDesignId: 'd1',
      designColourId: 'c1',
      processId: 'p1',
      memberId: 'w1',
      movementType: StockMovementType.issue,
      quantity: remainingPending,
      appliedRatePaise: 2000,
      isRateOverridden: false,
      lockedIncludeDamaged: false,
      transactionAt: issuedTxAt,
      recordedAt: issuedTxAt,
      createdAt: issuedTxAt,
      updatedAt: issuedTxAt,
    );
    return OpenIssueSummary(
      issueView: StockMovementView(
        movement: move,
        lotNumber: 'LOT-1',
        designName: 'D-1',
        colourName: 'Blue',
        processName: 'Stitching',
        workerName: 'Ramesh Bhai',
        isReversed: false,
        remainingPendingQty: remainingPending,
      ),
      childSettlements: const [],
    );
  }

  WorkerFinancialSummary mkWorkerFin({
    required String id,
    required String name,
    required int outstandingPaise,
  }) {
    return WorkerFinancialSummary(
      workerId: id,
      workerName: name,
      workerIsActive: true,
      totalIssuedLabourPaise: outstandingPaise,
      totalReceivedLabourPaise: outstandingPaise,
      earnedLabourPaise: outstandingPaise,
      adjustmentCreditsPaise: 0,
      adjustmentDebitsPaise: 0,
      regularPaymentsPaise: 0,
      advancePaymentsPaise: 0,
      advanceRefundsPaise: 0,
      netPaidToWorkerPaise: 0,
      netBalancePaise: outstandingPaise,
      outstandingPayablePaise: outstandingPaise,
      advanceCreditBalancePaise: 0,
    );
  }

  group('NotificationPlanCalculator', () {
    test('schedules all 5 categories in IST with deterministic IDs & redacts lock-screen privacy when PIN ON', () {
      // Thursday 2026-04-16 09:00:00 IST (before 10:00 AM, 8:00 PM, 8:30 PM)
      final nowUtc = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 4,
        day: 16,
        hour: 9,
      );
      final fiveDaysAgo = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 4,
        day: 11,
        hour: 10,
      );
      final tenDaysAgo = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 4,
        day: 6,
        hour: 10,
      );

      final plan = calc.computePlan(
        settings: const NotificationSettings(),
        nowUtcMillis: nowUtc,
        localeCode: 'en',
        isAppLockEnabled: true,
        openIssues: [
          mkOpenIssue(
            id: 'iss-1',
            issuedTxAt: fiveDaysAgo,
            remainingPending: 40,
          ),
        ],
        workerFinancials: [
          mkWorkerFin(
            id: 'w1',
            name: 'Ramesh Bhai',
            outstandingPaise: 125000, // ₹1,250
          ),
        ],
        hasActivityToday: true,
        todayIssuedQty: 50,
        todayReturnedGoodQty: 30,
        totalDamagedQty: 25, // >= 20 triggers 1005 alert
        lastBackupExportUtcMillis:
            tenDaysAgo, // > 7 days ago -> overdue -> schedules tonight 8:30 PM
      );

      expect(plan.idsToCancel, isEmpty);
      expect(plan.planned.length, 5);
      expect(plan.planned.map((e) => e.id).toSet(), {
        1001,
        1002,
        1003,
        1004,
        1005,
      });

      // Verify IST scheduling times
      final pendingNotif = plan.planned.firstWhere((e) => e.id == 1001);
      final pendingIst = IstDateTimeHelper.fromUtcMillisToIst(
        pendingNotif.scheduledAtUtcMillis,
      );
      expect(pendingIst.hour, 10);
      expect(pendingIst.day, 16);

      final settleNotif = plan.planned.firstWhere((e) => e.id == 1002);
      final settleIst = IstDateTimeHelper.fromUtcMillisToIst(
        settleNotif.scheduledAtUtcMillis,
      );
      expect(settleIst.weekday, DateTime.saturday);
      expect(settleIst.hour, 18);

      // Lock-screen privacy redaction: MUST NOT leak Rupee amount or worker name when PIN is ON!
      for (final p in plan.planned) {
        expect(p.privacyPrivate, isTrue);
        expect(p.body, isNot(contains('Ramesh')));
        expect(p.body, isNot(contains('1,250')));
        expect(p.body, isNot(contains('₹')));
      }
      expect(plan.firedAlertCooldownKey, 'damaged_20');
    });

    test('automatically cancels resolved reminders, skips quiet days, and enforces 24h alert cooldown', () {
      final nowUtc = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 4,
        day: 16,
        hour: 11,
      );

      // All issues settled, all worker balances ₹0, no activity today, damaged = 0
      final plan = calc.computePlan(
        settings: const NotificationSettings(),
        nowUtcMillis: nowUtc,
        localeCode: 'gu',
        isAppLockEnabled: false,
        openIssues: const [],
        workerFinancials: [
          mkWorkerFin(id: 'w1', name: 'Ramesh', outstandingPaise: 0),
        ],
        hasActivityToday: false,
        todayIssuedQty: 0,
        todayReturnedGoodQty: 0,
        totalDamagedQty: 0,
        lastBackupExportUtcMillis:
            nowUtc, // just backed up -> schedules 7d later
      );

      expect(plan.idsToCancel, containsAll(const [1001, 1002, 1003, 1005]));
      expect(plan.planned.length, 1);
      expect(plan.planned.first.id, 1004);
      final backupIst = IstDateTimeHelper.fromUtcMillisToIst(
        plan.planned.first.scheduledAtUtcMillis,
      );
      expect(backupIst.day, 23); // 16 + 7 = 23

      // Test 24h cooldown deduplication on 1005
      final cooledPlan = calc.computePlan(
        settings: const NotificationSettings(),
        nowUtcMillis: nowUtc,
        localeCode: 'en',
        isAppLockEnabled: false,
        openIssues: const [],
        workerFinancials: const [],
        hasActivityToday: false,
        todayIssuedQty: 0,
        todayReturnedGoodQty: 0,
        totalDamagedQty: 25,
        lastBackupExportUtcMillis: nowUtc,
        lastAlertFiredAtUtcMillis: nowUtc - 3600000, // 1h ago (< 24h)
        lastAlertCooldownKey: 'damaged_20',
      );
      expect(cooledPlan.planned.where((e) => e.id == 1005), isEmpty);
      expect(cooledPlan.firedAlertCooldownKey, isNull);
    });

    test('enforces strict deep-link allowlist', () {
      expect(
        NotificationPlanCalculator.isAllowedDeepLinkRoute(
          RoutePaths.stockReturnPicker,
        ),
        isTrue,
      );
      expect(
        NotificationPlanCalculator.isAllowedDeepLinkRoute(
          RoutePaths.dailySummary,
        ),
        isTrue,
      );
      expect(
        NotificationPlanCalculator.isAllowedDeepLinkRoute('/evil/route'),
        isFalse,
      );
      expect(NotificationPlanCalculator.isAllowedDeepLinkRoute(null), isFalse);
    });
  });
}
