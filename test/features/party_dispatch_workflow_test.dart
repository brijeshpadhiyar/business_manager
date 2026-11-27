import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/data/repositories/accounting_repository_impl.dart';
import 'package:business_manager/features/backup/data/services/data_health_service.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/parties/data/repositories/party_repository_impl.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/processes/data/repositories/process_repository_impl.dart';
import 'package:business_manager/features/rates/data/repositories/rate_repository_impl.dart';
import 'package:business_manager/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:business_manager/features/workers/data/repositories/worker_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'End-to-end Party Dispatch, Buyer Return, Party Payment, Lot Cost, Data Health & P&L',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('sf_party_e2e_');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });

      final tx = DatabaseTransactionRunner(db);
      final ids = IdGenerator();
      final media = NativeMediaStorageService(
        config: AppConfig.dev(),
        idGenerator: ids,
        baseDirectoryOverride: tempDir,
      );

      final lotRepo = LotRepositoryImpl(db, tx, ids, media);
      final procRepo = ProcessRepositoryImpl(db, tx, ids);
      final workerRepo = WorkerRepositoryImpl(db, tx, ids);
      final rateRepo = RateRepositoryImpl(db, tx, ids);
      final stockRepo = StockMovementRepositoryImpl(db, tx, ids);
      final acctRepo = AccountingRepositoryImpl(db, tx, ids);
      final partyRepo = PartyRepositoryImpl(db, tx, ids);
      final reportsRepo = ReportsRepositoryImpl(
        db,
        stockRepo,
        acctRepo,
        partyRepo,
      );
      final healthService = DataHealthService(db, media, ids);

      final now = IstDateTimeHelper.nowUtcMillis();
      final lot = await lotRepo.createLotComplete(
        lotNumber: '2001',
        title: 'Kurti Batch',
        transactionAtUtcMillis: now,
        designs: const [
          LotDesignDraftInput(
            designName: 'Floral',
            colours: [
              LotColourDraftInput(
                colourName: 'Maroon',
                initialQuantity: 100,
                unitPricePaise: 50000,
              ),
            ],
          ),
        ],
      );
      final detail = await lotRepo.getLotDetail(lot.id);
      final colour = detail!.designs.first.colours.first;

      final proc = await procRepo.createProcess(
        name: 'Stitching',
        defaultRatePaise: 5000,
      );
      final worker = await workerRepo.createWorker(
        name: 'Ramesh',
        phone: '9876543210',
      );
      await workerRepo.assignProcessToWorker(
        workerId: worker.id,
        processId: proc.id,
      );
      await rateRepo.addRate(
        workerId: worker.id,
        processId: proc.id,
        ratePaise: 5000,
        effectiveFrom: '2026-01-01',
      );

      final issue = await stockRepo.issueStock(
        designColourId: colour.id,
        processId: proc.id,
        workerId: worker.id,
        quantity: 60,
        transactionAtUtcMillis: now,
      );
      await stockRepo.recordSettlement(
        parentIssueId: issue.id,
        goodQuantity: 60,
        damagedQuantity: 0,
        lostQuantity: 0,
        shortageQuantity: 0,
        transactionAtUtcMillis: now,
      );

      final party = await partyRepo.createParty(
        name: 'Shree Fashion Surat',
        phone: '9988776655',
        partyType: PartyType.buyer,
      );

      // Over-dispatch > 100 must throw DomainValidationException
      await expectLater(
        partyRepo.createDispatchChallan(
          partyId: party.id,
          challanNumber: 'DC-0001',
          items: [
            DispatchLineDraft(
              lotId: lot.id,
              lotDesignId: detail.designs.first.design.id,
              designColourId: colour.id,
              quantity: 105,
              ratePaise: 65000,
            ),
          ],
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );

      // Valid dispatch of 70 pcs @ ₹650 (45,50,000 paise)
      final challan = await partyRepo.createDispatchChallan(
        partyId: party.id,
        challanNumber: 'DC-0001',
        items: [
          DispatchLineDraft(
            lotId: lot.id,
            lotDesignId: detail.designs.first.design.id,
            designColourId: colour.id,
            quantity: 70,
            ratePaise: 65000,
          ),
        ],
        transactionAtUtcMillis: now,
      );
      expect(challan.challan.netAmountPaise, 4550000);

      // Buyer returns 3 good + 2 damaged @ ₹650
      await partyRepo.createBuyerReturn(
        partyId: party.id,
        challanId: challan.challan.id,
        returnNumber: 'BR-0001',
        items: [
          BuyerReturnLineDraft(
            dispatchItemId: challan.items.first.id,
            lotId: lot.id,
            lotDesignId: detail.designs.first.design.id,
            designColourId: colour.id,
            returnCondition: BuyerReturnCondition.good,
            quantity: 3,
            ratePaise: 65000,
          ),
          BuyerReturnLineDraft(
            dispatchItemId: challan.items.first.id,
            lotId: lot.id,
            lotDesignId: detail.designs.first.design.id,
            designColourId: colour.id,
            returnCondition: BuyerReturnCondition.damaged,
            quantity: 2,
            ratePaise: 65000,
          ),
        ],
        reason: 'Stitching defect on 2 & excess 3',
        transactionAtUtcMillis: now,
      );

      // Live stock balance check: 100 - 70 + 3 = 33 available, 2 damaged, 65 net dispatched
      final bal = await stockRepo.getDesignColourBalance(colour.id);
      expect(bal!.physicalAvailableInHouse, 33);
      expect(bal.damagedBucket, 2);
      expect(bal.netDispatchedQty, 65);

      // Record party receipt ₹40,000
      await partyRepo.recordPartyPayment(
        partyId: party.id,
        paymentType: PartyPaymentType.receipt,
        paymentMode: PartyPaymentMode.upi,
        amountPaise: 4000000,
        transactionAtUtcMillis: now,
      );

      final ledger = await partyRepo.getPartyLedgerDetail(party.id);
      // 45,50,000 - 3,25,000 return - 40,00,000 receipt = 2,25,000 receivable due
      expect(ledger!.summary.outstandingReceivablePaise, 225000);

      // Add direct cost: Fabric ₹10,000
      await partyRepo.addLotDirectCost(
        lotId: lot.id,
        category: LotCostCategory.fabric,
        description: 'Rayon Fabric',
        amountPaise: 1000000,
        transactionAtUtcMillis: now,
      );

      final pnl = await partyRepo.getLotProfitLoss(lot.id);
      // Net revenue = 45,50,000 - 3,25,000 = 42,25,000
      // Worker labour = 60 * 5000 = 3,00,000
      // Direct cost = 10,00,000
      // Net profit = 29,25,000
      expect(pnl!.netRevenuePaise, 4225000);
      expect(pnl.workerLabourPaise, 300000);
      expect(pnl.directCostsPaise, 1000000);
      expect(pnl.netProfitPaise, 2925000);

      // Data Health must verify 0 stock/ledger/FK issues!
      final health = await healthService.runFullDiagnostics();
      expect(health.stockIssues, isEmpty);
      expect(health.ledgerIssues, isEmpty);
      expect(health.foreignKeyViolations, isEmpty);

      // Dashboard snapshot reflects dispatched stock and party receivable
      final snap = await reportsRepo.getDashboardSnapshot();
      expect(snap.dispatchedStock, 65);
      expect(snap.totalPartyReceivablePaise, 225000);
    },
  );
}
