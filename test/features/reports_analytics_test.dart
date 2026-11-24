import 'dart:convert';

import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/reports/data/services/excel_csv_export_service.dart';
import 'package:business_manager/features/reports/data/services/report_html_builder.dart';
import 'package:business_manager/features/reports/domain/calculators/reports_analytics_calculator.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  const calc = ReportsAnalyticsCalculator();

  StockMovementEntity mkMove({
    required String id,
    required StockMovementType type,
    required int qty,
    required int txAt,
    String lotId = 'lot-1',
    String designId = 'des-1',
    String colourId = 'col-1',
    String? processId = 'proc-1',
    String? workerId = 'wrk-1',
    String? parentIssueId,
    String? reversesId,
    String? reason,
  }) {
    return StockMovementEntity(
      id: id,
      lotId: lotId,
      lotDesignId: designId,
      designColourId: colourId,
      processId: processId,
      memberId: workerId,
      parentIssueId: parentIssueId,
      reversesMovementId: reversesId,
      movementType: type,
      quantity: qty,
      appliedRatePaise: 2000,
      isRateOverridden: false,
      lockedIncludeDamaged: false,
      reason: reason,
      transactionAt: txAt,
      recordedAt: txAt,
      createdAt: txAt,
      updatedAt: txAt,
    );
  }

  LabourEntryEntity mkLabour({
    required String id,
    required int qty,
    required int ratePaise,
    required int txAt,
    String workerId = 'wrk-1',
    String processId = 'proc-1',
    String lotId = 'lot-1',
    LabourBasisType basis = LabourBasisType.receivedGood,
    String? reversesId,
    bool isPayable = true,
  }) {
    return LabourEntryEntity(
      id: id,
      stockMovementId: 'sm-$id',
      reversesLabourEntryId: reversesId,
      memberId: workerId,
      processId: processId,
      lotId: lotId,
      basisType: basis,
      quantity: qty,
      ratePaise: ratePaise,
      amountPaise: qty * ratePaise,
      isPayable: isPayable,
      transactionAt: txAt,
      recordedAt: txAt,
      createdAt: txAt,
      updatedAt: txAt,
    );
  }

  PaymentEntity mkPayment({
    required String id,
    required PaymentType type,
    required int amountPaise,
    required int txAt,
    String workerId = 'wrk-1',
    PaymentMode mode = PaymentMode.cash,
    String? reversesId,
  }) {
    return PaymentEntity(
      id: id,
      memberId: workerId,
      paymentType: type,
      reversesPaymentId: reversesId,
      amountPaise: amountPaise,
      paymentMode: mode,
      transactionAt: txAt,
      recordedAt: txAt,
      createdAt: txAt,
      updatedAt: txAt,
    );
  }

  group('IstDateRangePresets', () {
    test('resolves IST Today, Yesterday, This Week (Mon-Sun), This Month, Prev Month', () {
      // Reference: Wednesday 2026-04-15 14:30:00 IST
      final refUtc = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 4,
        day: 15,
        hour: 14,
        minute: 30,
      );

      final today = IstDateRangePresets.resolve(
        ReportDatePreset.today,
        referenceUtcMillis: refUtc,
      );
      expect(
        IstDateTimeHelper.toIstBusinessDate(today.fromUtcMillis!),
        '2026-04-15',
      );
      expect(
        IstDateTimeHelper.toIstBusinessDate(today.toUtcMillis!),
        '2026-04-15',
      );

      final yesterday = IstDateRangePresets.resolve(
        ReportDatePreset.yesterday,
        referenceUtcMillis: refUtc,
      );
      expect(
        IstDateTimeHelper.toIstBusinessDate(yesterday.fromUtcMillis!),
        '2026-04-14',
      );

      final week = IstDateRangePresets.resolve(
        ReportDatePreset.thisWeek,
        referenceUtcMillis: refUtc,
      );
      // 2026-04-15 is Wednesday -> Mon 2026-04-13 to Sun 2026-04-19
      expect(
        IstDateTimeHelper.toIstBusinessDate(week.fromUtcMillis!),
        '2026-04-13',
      );
      expect(
        IstDateTimeHelper.toIstBusinessDate(week.toUtcMillis!),
        '2026-04-19',
      );

      final month = IstDateRangePresets.resolve(
        ReportDatePreset.thisMonth,
        referenceUtcMillis: refUtc,
      );
      expect(
        IstDateTimeHelper.toIstBusinessDate(month.fromUtcMillis!),
        '2026-04-01',
      );
      expect(
        IstDateTimeHelper.toIstBusinessDate(month.toUtcMillis!),
        '2026-04-30',
      );

      final prevMonth = IstDateRangePresets.resolve(
        ReportDatePreset.previousMonth,
        referenceUtcMillis: refUtc,
      );
      expect(
        IstDateTimeHelper.toIstBusinessDate(prevMonth.fromUtcMillis!),
        '2026-03-01',
      );
      expect(
        IstDateTimeHelper.toIstBusinessDate(prevMonth.toUtcMillis!),
        '2026-03-31',
      );
    });
  });

  group('ReportsAnalyticsCalculator accuracy & invariants', () {
    test('computes all 6 categories, excludes reversals, verifies turnaround, and compares periods safely', () {
      final dayPrev = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 3,
        day: 10,
        hour: 10,
      );
      final day1Issue = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 4,
        day: 10,
        hour: 10,
      );
      // Settled 24 hours later -> turnaround = 24.0h
      final day2Settle = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 4,
        day: 11,
        hour: 10,
      );
      final day3Open = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 4,
        day: 12,
        hour: 9,
      );
      final nowUtc = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 4,
        day: 15,
        hour: 12,
      );

      final movements = [
        // Prior month activity (for period comparison)
        mkMove(
          id: 'm-prev-i',
          type: StockMovementType.issue,
          qty: 50,
          txAt: dayPrev,
        ),
        mkMove(
          id: 'm-prev-g',
          type: StockMovementType.returnGood,
          qty: 50,
          txAt: dayPrev + 3600000,
          parentIssueId: 'm-prev-i',
        ),

        // Current month settled issue (40 good + 10 damaged = 50 -> fully settled)
        mkMove(
          id: 'm-i1',
          type: StockMovementType.issue,
          qty: 50,
          txAt: day1Issue,
        ),
        mkMove(
          id: 'm-g1',
          type: StockMovementType.returnGood,
          qty: 40,
          txAt: day2Settle,
          parentIssueId: 'm-i1',
        ),
        mkMove(
          id: 'm-d1',
          type: StockMovementType.returnDamaged,
          qty: 10,
          txAt: day2Settle,
          parentIssueId: 'm-i1',
          reason: 'Fabric tear',
        ),

        // Reversed issue (must be completely excluded!)
        mkMove(
          id: 'm-rev-target',
          type: StockMovementType.issue,
          qty: 99,
          txAt: day1Issue,
        ),
        mkMove(
          id: 'm-rev-row',
          type: StockMovementType.reversal,
          qty: 99,
          txAt: day1Issue + 1000,
          reversesId: 'm-rev-target',
        ),

        // Open issue (30 pending, 3 days old on Apr 15 -> bottleneck!)
        mkMove(
          id: 'm-i2',
          type: StockMovementType.issue,
          qty: 30,
          txAt: day3Open,
          processId: 'proc-2',
          workerId: 'wrk-2',
        ),
      ];

      final labour = [
        mkLabour(id: 'l-prev', qty: 50, ratePaise: 1000, txAt: dayPrev),
        mkLabour(id: 'l-1', qty: 40, ratePaise: 2000, txAt: day2Settle),
        // Reversed labour (must be excluded)
        mkLabour(id: 'l-rev-t', qty: 99, ratePaise: 2000, txAt: day2Settle),
        mkLabour(
          id: 'l-rev-r',
          qty: -99,
          ratePaise: 2000,
          txAt: day2Settle + 1000,
          basis: LabourBasisType.reversal,
          reversesId: 'l-rev-t',
        ),
      ];

      final payments = [
        mkPayment(
          id: 'p-1',
          type: PaymentType.regular,
          amountPaise: 50000,
          txAt: day2Settle,
        ),
      ];

      final filter = ReportFilter.forPreset(
        ReportDatePreset.thisMonth,
        referenceUtcMillis: nowUtc,
      );

      final bundle = calc.compute(
        filter: filter,
        businessNameEn: 'StitchFlow Workshop',
        businessNameGu: 'સ્ટિચફ્લો વર્કશોપ',
        lots: const [
          ReportLotInput(
            id: 'lot-1',
            lotNumber: 'LOT-101',
            title: 'Kurta',
            status: LotStatus.active,
          ),
        ],
        designs: const [
          ReportDesignInput(id: 'des-1', lotId: 'lot-1', designName: 'D-1'),
        ],
        colours: const [
          ReportColourInput(
            id: 'col-1',
            lotId: 'lot-1',
            lotDesignId: 'des-1',
            colourName: 'Ivory',
            initialQuantity: 200,
            unitPricePaise: 25000,
          ),
        ],
        processes: const [
          ReportProcessInput(id: 'proc-1', name: 'Cutting', isActive: true),
          ReportProcessInput(id: 'proc-2', name: 'Stitching', isActive: true),
        ],
        workers: const [
          ReportWorkerInput(id: 'wrk-1', name: 'રાકેશ ભાઈ', isActive: true),
          ReportWorkerInput(id: 'wrk-2', name: 'મહેશ ભાઈ', isActive: true),
        ],
        allMovements: movements,
        allLabourEntries: labour,
        allPayments: payments,
        allAdjustments: const [],
        nowUtcMillis: nowUtc,
      );

      // Daily totals (Apr 10-12: 50 + 30 issued = 80; reversed 99 excluded!)
      expect(bundle.dailyTotalIssued, 80);
      expect(bundle.dailyTotalGoodReturned, 40);
      expect(bundle.dailyTotalDamaged, 10);
      expect(bundle.dailyTotalLabourPaise, 80000);
      expect(bundle.dailyTotalNetPaymentsPaise, 50000);
      expect(bundle.currentTotalPendingQty, 30);

      // Inventory cross-check: 200 initial - 10 damaged - 30 pending = 160 available good
      expect(bundle.inventory.availableGoodStock, 160);
      expect(bundle.inventory.damagedBucket, 10);
      expect(bundle.inventory.pendingWithWorkers, 30);
      // Reference stock value: (200 - 10) * 25000 = 4,750,000 paise
      expect(bundle.inventory.referenceGoodStockValuePaise, 190 * 25000);

      // Process turnaround: proc-1 has 1 fully settled issue (24.0h), proc-2 has 0 (null)
      final cutting = bundle.processPerformance.firstWhere(
        (p) => p.processId == 'proc-1',
      );
      expect(cutting.settledIssuesCount, 1);
      expect(cutting.averageTurnaroundHours, closeTo(24.0, 0.01));

      final stitching = bundle.processPerformance.firstWhere(
        (p) => p.processId == 'proc-2',
      );
      expect(stitching.settledIssuesCount, 0);
      expect(stitching.averageTurnaroundHours, isNull);
      expect(stitching.currentPendingQty, 30);

      // Insights: Period comparison (Issued 80 vs 50 = +60%; Labour 80k vs 50k = +60%)
      final cmp = bundle.insights.periodComparison!;
      expect(cmp.issuedQty.percentChange, closeTo(60.0, 0.01));
      expect(cmp.labourCostPaise.percentChange, closeTo(60.0, 0.01));

      // Bottlenecks: Stitching has 30 pending, 3 days old
      expect(bundle.insights.bottlenecks.length, 1);
      expect(bundle.insights.bottlenecks.first.processId, 'proc-2');
      expect(bundle.insights.bottlenecks.first.oldestOpenIssueAgeDays, 3);

      // Defect reason captured
      expect(bundle.insights.topDefectReasons.first.reason, 'Fabric tear');
      expect(bundle.insights.topDefectReasons.first.quantity, 10);

      // Gujarati HTML + Excel (.xlsx) round-trip + UTF-8 BOM CSV
      const htmlBuilder = ReportHtmlBuilder();
      final html = htmlBuilder.buildHtml(
        bundle: bundle,
        category: ReportCategory.workerPerformance,
        localeCode: 'gu',
      );
      expect(html, contains('NotoSansGujarati-Regular.ttf'));
      expect(html, contains('સ્ટિચફ્લો વર્કશોપ'));
      expect(html, contains('રાકેશ ભાઈ'));
      expect(html.toLowerCase(), isNot(contains('revenue')));

      final sheets = ExcelCsvExportService.buildSheets(
        bundle: bundle,
        category: ReportCategory.workerPerformance,
        localeCode: 'gu',
        fullWorkbook: true,
      );
      expect(sheets.length, 10);

      final xlsxBytes = ExcelCsvExportService.buildXlsxBytes(sheets);
      expect(xlsxBytes, isNotEmpty);
      final decoded = Excel.decodeBytes(xlsxBytes);
      expect(decoded.tables.keys, contains('કારીગર_કામગીરી'));
      final workerTable = decoded.tables['કારીગર_કામગીરી']!;
      final decodedNames = workerTable.rows
          .skip(1)
          .map((r) => r.first?.value?.toString() ?? '')
          .toList();
      expect(decodedNames, contains('રાકેશ ભાઈ'));

      final csvBytes = ExcelCsvExportService.buildCsvBytesWithBom(sheets[1]);
      // UTF-8 BOM is EF BB BF
      expect(csvBytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
      final csvText = utf8.decode(csvBytes);
      expect(csvText, contains('રાકેશ ભાઈ'));
    });
  });

  group('Performance Benchmark (5,000 movements + 3,000 labour + 1,000 payments)', () {
    test('completes full single-pass analytics computation under 500ms', () {
      final baseUtc = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 1,
        day: 1,
        hour: 9,
      );
      const dayMs = 86400000;

      final workers = [
        for (var i = 0; i < 20; i++)
          ReportWorkerInput(id: 'w-$i', name: 'Worker $i', isActive: true),
      ];
      final processes = [
        for (var i = 0; i < 6; i++)
          ReportProcessInput(id: 'p-$i', name: 'Process $i', isActive: true),
      ];
      final lots = [
        for (var i = 0; i < 10; i++)
          ReportLotInput(
            id: 'l-$i',
            lotNumber: 'LOT-${100 + i}',
            status: LotStatus.active,
          ),
      ];
      final designs = [
        for (var i = 0; i < 20; i++)
          ReportDesignInput(
            id: 'd-$i',
            lotId: 'l-${i % 10}',
            designName: 'D-$i',
          ),
      ];
      final colours = [
        for (var i = 0; i < 40; i++)
          ReportColourInput(
            id: 'c-$i',
            lotId: 'l-${(i % 20) % 10}',
            lotDesignId: 'd-${i % 20}',
            colourName: 'Colour $i',
            initialQuantity: 5000,
            unitPricePaise: 20000,
          ),
      ];

      // 2,500 issues + 2,500 settlements = 5,000 movements
      final movements = <StockMovementEntity>[];
      for (var i = 0; i < 2500; i++) {
        final colIdx = i % 40;
        final desIdx = colIdx % 20;
        final lotIdx = desIdx % 10;
        final tx = baseUtc + (i % 120) * dayMs;
        final issueId = 'iss-$i';
        movements.add(
          mkMove(
            id: issueId,
            type: StockMovementType.issue,
            qty: 10,
            txAt: tx,
            lotId: 'l-$lotIdx',
            designId: 'd-$desIdx',
            colourId: 'c-$colIdx',
            processId: 'p-${i % 6}',
            workerId: 'w-${i % 20}',
          ),
        );
        movements.add(
          mkMove(
            id: 'ret-$i',
            type: i % 15 == 0
                ? StockMovementType.returnDamaged
                : StockMovementType.returnGood,
            qty: i < 2400 ? 10 : 5,
            txAt: tx + 43200000,
            lotId: 'l-$lotIdx',
            designId: 'd-$desIdx',
            colourId: 'c-$colIdx',
            processId: 'p-${i % 6}',
            workerId: 'w-${i % 20}',
            parentIssueId: issueId,
            reason: i % 15 == 0 ? 'Stitching defect' : null,
          ),
        );
      }

      final labour = <LabourEntryEntity>[
        for (var i = 0; i < 3000; i++)
          mkLabour(
            id: 'lab-$i',
            qty: 10,
            ratePaise: 1500,
            txAt: baseUtc + (i % 120) * dayMs,
            workerId: 'w-${i % 20}',
            processId: 'p-${i % 6}',
            lotId: 'l-${i % 10}',
          ),
      ];

      final payments = <PaymentEntity>[
        for (var i = 0; i < 1000; i++)
          mkPayment(
            id: 'pay-$i',
            type: PaymentType.regular,
            amountPaise: 10000,
            txAt: baseUtc + (i % 120) * dayMs,
            workerId: 'w-${i % 20}',
          ),
      ];

      final nowUtc = baseUtc + 120 * dayMs;
      final filter = ReportFilter(
        preset: ReportDatePreset.custom,
        fromUtcMillis: baseUtc + 90 * dayMs,
        toUtcMillis: nowUtc,
      );

      final sw = Stopwatch()..start();
      final bundle = calc.compute(
        filter: filter,
        businessNameEn: 'Benchmark Workshop',
        businessNameGu: 'બેન્ચમાર્ક',
        lots: lots,
        designs: designs,
        colours: colours,
        processes: processes,
        workers: workers,
        allMovements: movements,
        allLabourEntries: labour,
        allPayments: payments,
        allAdjustments: const [],
        nowUtcMillis: nowUtc,
      );
      sw.stop();

      // ignore: avoid_print
      print(
        'BENCHMARK_12_3: 5000 movements + 3000 labour + 1000 payments computed in ${sw.elapsedMilliseconds} ms',
      );
      expect(bundle.dailyRows, isNotEmpty);
      expect(bundle.workerPerformance.length, 20);
      expect(bundle.processPerformance.length, 6);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });
}
