import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/connection/database_connection_native.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/production_history/data/repositories/production_history_repository_impl.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const now = 1795324800000;
  late Directory tempDir;

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_v8_mig_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Schema v7 -> v8 migration preserves all existing production & financial records and integrates seamlessly with new v8 returns',
    () async {
      final file = await resolvePrivateDatabaseFile(
        AppConfig.prod(),
        baseDirectoryOverride: tempDir,
      );

      // 1. Seed a populated database then downgrade schema to exact v7 state
      final seedDb = AppDatabase.forTesting(NativeDatabase(file));
      await seedDb.verifyPragmas();

      await seedDb.lotDao.insertLot(
        const LotsCompanion(
          id: Value('lot-legacy'),
          lotNumber: Value('LOT-LEGACY-01'),
          title: Value('Pre-v8 Silk Batch'),
          status: Value('ACTIVE'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await seedDb.lotDao.insertDesign(
        const LotDesignsCompanion(
          id: Value('des-legacy'),
          lotId: Value('lot-legacy'),
          designName: Value('D-Legacy'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await seedDb.lotDao.insertDesignColour(
        const DesignColoursCompanion(
          id: Value('col-legacy'),
          lotDesignId: Value('des-legacy'),
          colourName: Value('Emerald'),
          initialQuantity: Value(100),
          unitPricePaise: Value(45000),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await seedDb.processMemberDao.insertProcess(
        const ProcessesCompanion(
          id: Value('proc-legacy'),
          name: Value('Stitching'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await seedDb.processMemberDao.insertMember(
        const MembersCompanion(
          id: Value('w-legacy'),
          name: Value('Rameshbhai'),
          phone: Value('9876543210'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await seedDb.processMemberDao.insertMemberProcess(
        const MemberProcessesCompanion(
          id: Value('mp-legacy'),
          memberId: Value('w-legacy'),
          processId: Value('proc-legacy'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      // Pre-v8 ISSUE (100 pcs @ ₹10) + partial legacy RETURN_GOOD (40 pcs) + Labour (₹400) + Payment (₹150)
      await seedDb.stockMovementDao.insertMovement(
        const StockMovementsCompanion(
          id: Value('iss-legacy'),
          lotId: Value('lot-legacy'),
          lotDesignId: Value('des-legacy'),
          designColourId: Value('col-legacy'),
          processId: Value('proc-legacy'),
          memberId: Value('w-legacy'),
          movementType: Value('ISSUE'),
          quantity: Value(100),
          appliedRatePaise: Value(1000),
          lockedBillingMode: Value('RECEIVED_QTY'),
          lockedIncludeDamaged: Value(0),
          transactionAt: Value(now + 1000),
          recordedAt: Value(now + 1000),
          createdAt: Value(now + 1000),
          updatedAt: Value(now + 1000),
        ),
      );
      await seedDb.stockMovementDao.insertMovement(
        const StockMovementsCompanion(
          id: Value('ret-legacy-g1'),
          lotId: Value('lot-legacy'),
          lotDesignId: Value('des-legacy'),
          designColourId: Value('col-legacy'),
          processId: Value('proc-legacy'),
          memberId: Value('w-legacy'),
          parentIssueId: Value('iss-legacy'),
          movementType: Value('RETURN_GOOD'),
          quantity: Value(40),
          appliedRatePaise: Value(1000),
          lockedBillingMode: Value('RECEIVED_QTY'),
          lockedIncludeDamaged: Value(0),
          transactionAt: Value(now + 2000),
          recordedAt: Value(now + 2000),
          createdAt: Value(now + 2000),
          updatedAt: Value(now + 2000),
        ),
      );
      await seedDb.labourEntryDao.insertEntry(
        const LabourEntriesCompanion(
          id: Value('lab-legacy-1'),
          stockMovementId: Value('ret-legacy-g1'),
          memberId: Value('w-legacy'),
          processId: Value('proc-legacy'),
          lotId: Value('lot-legacy'),
          basisType: Value('RECEIVED_GOOD'),
          quantity: Value(40),
          ratePaise: Value(1000),
          amountPaise: Value(40000),
          isPayable: Value(1),
          transactionAt: Value(now + 2000),
          recordedAt: Value(now + 2000),
          createdAt: Value(now + 2000),
          updatedAt: Value(now + 2000),
        ),
      );
      await seedDb.paymentDao.insertPayment(
        const PaymentsCompanion(
          id: Value('pay-legacy-1'),
          memberId: Value('w-legacy'),
          paymentType: Value('REGULAR'),
          amountPaise: Value(15000),
          paymentMode: Value('CASH'),
          transactionAt: Value(now + 3000),
          recordedAt: Value(now + 3000),
          createdAt: Value(now + 3000),
          updatedAt: Value(now + 3000),
        ),
      );

      // Drop v8 tables and v8 indexes, and roll back user_version to 7
      await seedDb.customStatement('DROP TABLE IF EXISTS rejection_repairs;');
      await seedDb.customStatement('DROP TABLE IF EXISTS rejection_records;');
      await seedDb.customStatement(
        'DROP TABLE IF EXISTS production_inspections;',
      );
      await seedDb.customStatement('DROP TABLE IF EXISTS production_returns;');
      await seedDb.customStatement('DROP INDEX IF EXISTS idx_sm_job_process;');
      await seedDb.customStatement('PRAGMA user_version = 7;');
      await seedDb.close();

      // 2. Reopen with Schema v8 AppDatabase -> executes real v7 -> v8 migration
      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(upgraded.close);
      final pragmas = await upgraded.verifyPragmas();
      expect(pragmas.foreignKeysEnabled, isTrue);
      expect(pragmas.isWalMode, isTrue);
      expect(pragmas.isSynchronousFull, isTrue);

      final userVer = await upgraded
          .customSelect('PRAGMA user_version;')
          .getSingle();
      expect(
        userVer.read<int>('user_version'),
        DatabaseMigrationManager.currentSchemaVersion,
      );
      expect(DatabaseMigrationManager.currentSchemaVersion, 8);

      final integrity = await upgraded
          .customSelect('PRAGMA integrity_check;')
          .getSingle();
      expect(integrity.data.values.first.toString().toLowerCase(), 'ok');

      final fkViolations = await upgraded
          .customSelect('PRAGMA foreign_key_check;')
          .get();
      expect(fkViolations, isEmpty);

      // Verify all 4 v8 tables + key v8 indexes exist
      final tableRows = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%';",
          )
          .get();
      final tables = tableRows.map((r) => r.read<String>('name')).toSet();
      expect(
        tables,
        containsAll(const [
          'production_returns',
          'production_inspections',
          'rejection_records',
          'rejection_repairs',
        ]),
      );

      final idxRows = await upgraded
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index';")
          .get();
      final indexes = idxRows.map((r) => r.read<String>('name')).toSet();
      expect(
        indexes,
        containsAll(const [
          'idx_sm_job_process',
          'idx_pr_issue',
          'idx_pr_lot_tx',
          'idx_pi_return',
          'idx_pi_repair',
          'idx_rr_lot_status',
          'idx_rep_rejection',
        ]),
      );

      // 3. Verify legacy pre-v8 history reconciles accurately BEFORE any new writes
      final repo = ProductionHistoryRepositoryImpl(
        upgraded,
        DatabaseTransactionRunner(upgraded),
        IdGenerator(),
      );

      final beforeHist = await repo.getLotCompleteHistory('lot-legacy');
      expect(beforeHist, isNotNull);
      expect(beforeHist!.totalAssignedQty, 100);
      expect(beforeHist.totalReturnedQty, 40);
      expect(beforeHist.totalAcceptedQty, 40);
      expect(beforeHist.totalOutstandingQty, 60);
      expect(beforeHist.totalPendingInspectionQty, 0);
      expect(beforeHist.totalProductionCostPaise, 40000);

      // 4. Now log a new Schema v8 Pending Inspection return for the remaining 60 pcs
      final retRes = await repo.recordProductionReturn(
        parentIssueId: 'iss-legacy',
        returnedQuantity: 60,
        transactionAtUtcMillis: now + 4000,
        inspectImmediately: false,
      );
      expect(retRes.remainingOutstandingQty, 0);
      expect(retRes.remainingPendingInspectionQty, 60);

      // Still ₹400 earned (₹0 from pending inspection)
      var workerProf = await repo.getWorkerCompleteProfile('w-legacy');
      expect(workerProf!.financialSummary.earnedLabourPaise, 40000);
      expect(workerProf.pendingInspectionQty, 60);
      expect(workerProf.outstandingQty, 0);

      // 5. Inspect those 60 pcs -> 55 accepted, 5 rejected
      final inspRes = await repo.approveReturnInspection(
        productionReturnId: retRes.productionReturn.id,
        acceptedQuantity: 55,
        rejectedQuantity: 5,
        rejectionReason: 'Minor stain',
        transactionAtUtcMillis: now + 5000,
        inspectedBy: 'Owner',
        approvedBy: 'Owner',
        authorizedViaPin: true,
      );
      expect(inspRes.earnedAmountPaise, 55000);

      // Final combined totals: 40 legacy + 55 v8 = 95 accepted (₹950 earned), 5 rejected, ₹150 paid => ₹800 outstanding
      workerProf = await repo.getWorkerCompleteProfile('w-legacy');
      expect(workerProf!.acceptedQty, 95);
      expect(workerProf.rejectedQty, 5);
      expect(workerProf.pendingInspectionQty, 0);
      expect(workerProf.outstandingQty, 0);
      expect(workerProf.financialSummary.earnedLabourPaise, 95000);
      expect(workerProf.financialSummary.outstandingPayablePaise, 80000);

      // Verify foreign keys still spotless after mixed legacy + v8 operations
      final fkAfter = await upgraded
          .customSelect('PRAGMA foreign_key_check;')
          .get();
      expect(fkAfter, isEmpty);

      await upgraded.close();
    },
  );
}
