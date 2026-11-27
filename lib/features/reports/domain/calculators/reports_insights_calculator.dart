import 'dart:math' as math;

import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/reports/domain/calculators/reports_analytics_accumulators.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:timezone/timezone.dart' as tz;

/// Pure-Dart insights, period comparison, bottleneck, and trend-chart builder
/// extracted from [ReportsAnalyticsCalculator].
final class ReportsInsightsCalculator {
  const ReportsInsightsCalculator();

  static const int _millisPerDay = 86400000;

  BusinessInsightsBundle buildInsights({
    required ReportFilter filter,
    required List<DailyReportRow> dailyRows,
    required List<WorkerPerformanceRow> workerPerfRows,
    required List<ProcessPerformanceRow> processPerfRows,
    required List<StockMovementEntity> activeMovements,
    required List<LabourEntryEntity> allLabourEntries,
    required Set<String> revLabourIds,
    required Map<String, ReasonAcc> defectReasonAcc,
    required int totalPeriodGood,
    required int totalPeriodDamaged,
    required int totalPeriodLostShortage,
    required int dailyTotalIssued,
    required int dailyTotalGood,
    required int periodTotalLabourPaise,
    required bool Function(StockMovementEntity) matchesStockDimensions,
    required bool Function(LabourEntryEntity) matchesLabourDimensions,
  }) {
    final overallDefectRate = computeReportDefectRate(
      good: totalPeriodGood,
      damaged: totalPeriodDamaged,
      lostShortage: totalPeriodLostShortage,
    );

    final trendResult = buildTrendPoints(
      dailyRowsNewestFirst: dailyRows,
      fromUtcMillis: filter.fromUtcMillis,
      toUtcMillis: filter.toUtcMillis,
    );

    final prevWindow = IstDateRangePresets.previousWindow(
      preset: filter.preset,
      fromUtcMillis: filter.fromUtcMillis,
      toUtcMillis: filter.toUtcMillis,
    );
    PeriodComparisonSummary? periodComparison;
    final prevGoodByWorker = <String, int>{};

    if (prevWindow != null) {
      var prevIssued = 0;
      var prevGood = 0;
      var prevDamaged = 0;
      var prevLostShortage = 0;
      var prevLabourPaise = 0;

      for (final m in activeMovements) {
        if (m.transactionAt < prevWindow.fromUtcMillis ||
            m.transactionAt > prevWindow.toUtcMillis) {
          continue;
        }
        if (!matchesStockDimensions(m)) continue;
        switch (m.movementType) {
          case StockMovementType.issue:
            prevIssued += m.quantity;
          case StockMovementType.returnGood:
            prevGood += m.quantity;
            if (m.memberId != null) {
              prevGoodByWorker[m.memberId!] =
                  (prevGoodByWorker[m.memberId!] ?? 0) + m.quantity;
            }
          case StockMovementType.returnDamaged:
            prevDamaged += m.quantity;
          case StockMovementType.settlementLost:
          case StockMovementType.settlementShortage:
            prevLostShortage += m.quantity;
          case StockMovementType.adjustmentDamagedToGood:
          case StockMovementType.reversal:
            break;
        }
      }

      for (final e in allLabourEntries) {
        if (e.basisType == LabourBasisType.reversal ||
            revLabourIds.contains(e.id) ||
            !e.isPayable) {
          continue;
        }
        if (e.transactionAt < prevWindow.fromUtcMillis ||
            e.transactionAt > prevWindow.toUtcMillis) {
          continue;
        }
        if (!matchesLabourDimensions(e)) continue;
        prevLabourPaise += e.amountPaise;
      }

      periodComparison = PeriodComparisonSummary(
        previousFromUtcMillis: prevWindow.fromUtcMillis,
        previousToUtcMillis: prevWindow.toUtcMillis,
        issuedQty: compareMetric(dailyTotalIssued, prevIssued),
        goodReturnedQty: compareMetric(dailyTotalGood, prevGood),
        labourCostPaise: compareMetric(periodTotalLabourPaise, prevLabourPaise),
        currentDefectRatePercent: overallDefectRate,
        previousDefectRatePercent: computeReportDefectRate(
          good: prevGood,
          damaged: prevDamaged,
          lostShortage: prevLostShortage,
        ),
      );
    }

    final bottlenecks = <ProcessBottleneckItem>[];
    for (final pr in processPerfRows) {
      if (pr.currentPendingQty <= 0) continue;
      final ratio = pr.periodGoodReturnedQty > 0
          ? pr.currentPendingQty / pr.periodGoodReturnedQty
          : null;
      bottlenecks.add(
        ProcessBottleneckItem(
          processId: pr.processId,
          processName: pr.processName,
          currentPendingQty: pr.currentPendingQty,
          openIssuesCount: pr.currentOpenIssuesCount,
          oldestOpenIssueAgeDays: pr.oldestOpenIssueAgeDays ?? 0,
          periodCompletedQty: pr.periodGoodReturnedQty,
          pendingToCompletedRatio: ratio,
        ),
      );
    }
    bottlenecks.sort((a, b) {
      final ageCmp = b.oldestOpenIssueAgeDays.compareTo(
        a.oldestOpenIssueAgeDays,
      );
      if (ageCmp != 0) return ageCmp;
      final ratioA = a.pendingToCompletedRatio ?? double.infinity;
      final ratioB = b.pendingToCompletedRatio ?? double.infinity;
      final ratioCmp = ratioB.compareTo(ratioA);
      if (ratioCmp != 0) return ratioCmp;
      return b.currentPendingQty.compareTo(a.currentPendingQty);
    });

    final workerTrends = workerPerfRows
        .where((w) => w.periodGoodReturnedQty > 0)
        .take(8)
        .map((w) {
          final prevGood = prevGoodByWorker[w.workerId] ?? 0;
          final pct = prevWindow == null || prevGood == 0
              ? null
              : ((w.periodGoodReturnedQty - prevGood) * 100.0) / prevGood;
          return WorkerProductivityTrendItem(
            workerId: w.workerId,
            workerName: w.workerName,
            currentGoodReturnedQty: w.periodGoodReturnedQty,
            previousGoodReturnedQty: prevGood,
            percentChange: pct,
            defectRatePercent: w.defectRatePercent,
          );
        })
        .toList();

    final topDefectReasons =
        defectReasonAcc.entries
            .map(
              (e) => DefectReasonStat(
                reason: e.key,
                quantity: e.value.quantity,
                occurrences: e.value.occurrences,
              ),
            )
            .toList()
          ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final labourCostShares = <ProcessLabourCostShare>[];
    if (periodTotalLabourPaise > 0) {
      for (final pr in processPerfRows) {
        if (pr.periodLabourCostPaise <= 0) continue;
        labourCostShares.add(
          ProcessLabourCostShare(
            processId: pr.processId,
            processName: pr.processName,
            labourCostPaise: pr.periodLabourCostPaise,
            sharePercent:
                (pr.periodLabourCostPaise * 100.0) / periodTotalLabourPaise,
          ),
        );
      }
      labourCostShares.sort(
        (a, b) => b.labourCostPaise.compareTo(a.labourCostPaise),
      );
    }

    return BusinessInsightsBundle(
      trendPoints: trendResult.points,
      isWeeklyBuckets: trendResult.isWeekly,
      periodComparison: periodComparison,
      bottlenecks: bottlenecks,
      workerTrends: workerTrends,
      overallDefectRatePercent: overallDefectRate,
      totalPeriodDefectsQty: totalPeriodDamaged + totalPeriodLostShortage,
      topDefectReasons: topDefectReasons.take(6).toList(),
      processLabourCostShares: labourCostShares,
      totalPeriodLabourCostPaise: periodTotalLabourPaise,
    );
  }

  static PeriodComparisonMetric compareMetric(int current, int previous) {
    final delta = current - previous;
    final pct = previous == 0 ? null : (delta * 100.0) / previous;
    return PeriodComparisonMetric(
      currentValue: current,
      previousValue: previous,
      delta: delta,
      percentChange: pct,
    );
  }

  ({List<ProductionTrendPoint> points, bool isWeekly}) buildTrendPoints({
    required List<DailyReportRow> dailyRowsNewestFirst,
    required int? fromUtcMillis,
    required int? toUtcMillis,
  }) {
    if (dailyRowsNewestFirst.isEmpty) {
      return (points: const [], isWeekly: false);
    }
    final chronological = dailyRowsNewestFirst.reversed.toList();
    final spanDays = (fromUtcMillis != null && toUtcMillis != null)
        ? ((toUtcMillis - fromUtcMillis) ~/ _millisPerDay) + 1
        : chronological.length;
    final useWeekly = spanDays > 31 || chronological.length > 31;

    if (!useWeekly) {
      final points = chronological.map((r) {
        final parts = r.istDateIso.split('-');
        final shortLabel = parts.length == 3
            ? '${parts[2]}/${parts[1]}'
            : r.istDateIso;
        return ProductionTrendPoint(
          bucketKey: r.istDateIso,
          label: shortLabel,
          issuedQty: r.issuedQty,
          goodReturnedQty: r.goodReturnedQty,
          damagedLostQty: r.damagedQty + r.lostAndShortageQty,
          labourCostPaise: r.labourEarnedPaise,
        );
      }).toList();
      return (points: points, isWeekly: false);
    }

    final weeklyMap = <String, TrendBucketAcc>{};
    for (final r in chronological) {
      final ist = IstDateTimeHelper.fromUtcMillisToIst(r.dayStartUtcMillis);
      final daysFromMon = ist.weekday - DateTime.monday;
      final mon = tz.TZDateTime(
        IstDateTimeHelper.istLocation,
        ist.year,
        ist.month,
        ist.day - daysFromMon,
      );
      final key = AppDateTimeFormatter.toIsoDate(mon);
      final label = AppDateTimeFormatter.formatShortDayMonth(mon);
      final acc = weeklyMap.putIfAbsent(key, () => TrendBucketAcc(label));
      acc.issued += r.issuedQty;
      acc.good += r.goodReturnedQty;
      acc.defects += r.damagedQty + r.lostAndShortageQty;
      acc.labour += r.labourEarnedPaise;
    }

    final sortedKeys = weeklyMap.keys.toList()..sort();
    final startIdx = math.max(0, sortedKeys.length - 16);
    final points = [
      for (int i = startIdx; i < sortedKeys.length; i++)
        ProductionTrendPoint(
          bucketKey: sortedKeys[i],
          label: weeklyMap[sortedKeys[i]]!.label,
          issuedQty: weeklyMap[sortedKeys[i]]!.issued,
          goodReturnedQty: weeklyMap[sortedKeys[i]]!.good,
          damagedLostQty: weeklyMap[sortedKeys[i]]!.defects,
          labourCostPaise: weeklyMap[sortedKeys[i]]!.labour,
        ),
    ];
    return (points: points, isWeekly: true);
  }
}
