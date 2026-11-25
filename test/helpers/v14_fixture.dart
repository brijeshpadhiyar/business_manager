import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/accounting/data/repositories/accounting_repository_impl.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_repository_impl.dart';
import 'package:business_manager/features/processes/data/repositories/process_repository_impl.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/production_history/data/repositories/production_history_repository_impl.dart';
import 'package:business_manager/features/rates/data/repositories/rate_repository_impl.dart';
import 'package:business_manager/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/workers/data/repositories/worker_repository_impl.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2026-11-24 00:00 IST.
const int v14BaseTs = 1795411200000;

/// Shared in-memory fixture for v1.4 integrity tests: one lot, one design,
/// one colour (100 pcs), one process (Stitching @ ₹10/pc) and two workers.
final class V14Fixture {
  V14Fixture._();

  late final AppDatabase db;
  late final Directory tempDir;
  late final LotRepositoryImpl lotRepo;
  late final ProcessRepositoryImpl processRepo;
  late final WorkerRepositoryImpl workerRepo;
  late final RateRepositoryImpl rateRepo;
  late final StockMovementRepositoryImpl stockRepo;
  late final AccountingRepositoryImpl accountingRepo;
  late final ProductionHistoryRepositoryImpl historyRepo;
  late final ProcessRoutingRepositoryImpl routingRepo;
  late final ReportsRepositoryImpl reportsRepo;

  late final ProcessEntity stitching;
  late final WorkerEntity ramesh;
  late final WorkerEntity suresh;
  late final LotEntity lot;
  late final String colourId;

  static const int ratePaise = 1000;
  static const int initialQty = 100;

  static Future<V14Fixture> create() async {
    final f = V14Fixture._();
    f.tempDir = await Directory.systemTemp.createTemp('sf_v14_');
    f.db = AppDatabase.forTesting(NativeDatabase.memory());
    await f.db.verifyPragmas();
    final tx = DatabaseTransactionRunner(f.db);
    final ids = IdGenerator();
    final media = NativeMediaStorageService(
      config: AppConfig.dev(),
      idGenerator: ids,
      baseDirectoryOverride: f.tempDir,
    );
    f.lotRepo = LotRepositoryImpl(f.db, tx, ids, media);
    f.processRepo = ProcessRepositoryImpl(f.db, tx, ids);
    f.workerRepo = WorkerRepositoryImpl(f.db, tx, ids);
    f.rateRepo = RateRepositoryImpl(f.db, tx, ids);
    f.stockRepo = StockMovementRepositoryImpl(f.db, tx, ids);
    f.accountingRepo = AccountingRepositoryImpl(f.db, tx, ids);
    f.historyRepo = ProductionHistoryRepositoryImpl(f.db, tx, ids);
    f.routingRepo = ProcessRoutingRepositoryImpl(f.db, tx, f.stockRepo, ids);
    f.reportsRepo = ReportsRepositoryImpl(f.db, f.stockRepo, f.accountingRepo);

    f.stitching = await f.processRepo.createProcess(
      name: 'Stitching',
      defaultRatePaise: ratePaise,
    );
    f.ramesh = await f.workerRepo.createWorker(
      name: 'Ramesh',
      phone: '9876500001',
    );
    f.suresh = await f.workerRepo.createWorker(
      name: 'Suresh',
      phone: '9876500002',
    );
    for (final w in [f.ramesh, f.suresh]) {
      await f.workerRepo.assignProcessToWorker(
        workerId: w.id,
        processId: f.stitching.id,
      );
      await f.rateRepo.addRate(
        workerId: w.id,
        processId: f.stitching.id,
        ratePaise: ratePaise,
        effectiveFrom: '2025-01-01',
      );
    }

    f.lot = await f.lotRepo.createLotComplete(
      lotNumber: 'LOT-V14',
      title: 'v1.4 fixture',
      transactionAtUtcMillis: v14BaseTs,
      designs: const [
        LotDesignDraftInput(
          designName: 'D-1',
          colours: [
            LotColourDraftInput(
              colourName: 'Red',
              initialQuantity: initialQty,
              unitPricePaise: 50000,
            ),
          ],
        ),
      ],
    );
    final detail = (await f.lotRepo.getLotDetail(f.lot.id))!;
    f.colourId = detail.designs.first.colours.first.id;
    return f;
  }

  Future<void> dispose() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  }

  Future<StockMovementEntity> issue(
    int qty, {
    String? workerId,
    int offsetMs = 0,
  }) => stockRepo.issueStock(
    designColourId: colourId,
    processId: stitching.id,
    workerId: workerId ?? ramesh.id,
    quantity: qty,
    transactionAtUtcMillis: v14BaseTs + offsetMs,
  );

  Future<DesignColourStockBalance> balance() async =>
      (await stockRepo.getDesignColourBalance(colourId))!;

  Future<int> earnedPaise(String workerId) async {
    final all = await accountingRepo.getAllWorkerSummaries();
    return all.firstWhere((w) => w.workerId == workerId).earnedLabourPaise;
  }

  /// Net payable incl. adjustments, before payments.
  Future<int> netBalancePaise(String workerId) async {
    final all = await accountingRepo.getAllWorkerSummaries();
    return all.firstWhere((w) => w.workerId == workerId).netBalancePaise;
  }
}

/// Golden rule: every piece of a colour sits in exactly one bucket.
void expectReconciled(DesignColourStockBalance b) {
  expect(
    b.physicalAvailableInHouse +
        b.totalPendingWithWorkers +
        b.totalPendingInspection +
        b.damagedBucket +
        b.totalLost +
        b.totalShortage,
    b.initialQuantity,
    reason:
        'available=${b.physicalAvailableInHouse} withWorkers=${b.totalPendingWithWorkers} '
        'pendingQC=${b.totalPendingInspection} damaged=${b.damagedBucket} '
        'lost=${b.totalLost} shortage=${b.totalShortage} initial=${b.initialQuantity}',
  );
  expect(b.damagedBucket, greaterThanOrEqualTo(0));
  expect(b.physicalAvailableInHouse, greaterThanOrEqualTo(0));
}
