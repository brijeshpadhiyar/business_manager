import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_initializer.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DatabaseTransactionRunner txRunner;
  const now = 1795324800000;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    txRunner = DatabaseTransactionRunner(db);
    await db.verifyPragmas();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedBaseGraph() async {
    await db.lotDao.insertLot(
      const LotsCompanion(
        id: Value('lot-1'),
        lotNumber: Value('1001'),
        transactionAt: Value(now),
        recordedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.lotDao.insertDesign(
      const LotDesignsCompanion(
        id: Value('design-1'),
        lotId: Value('lot-1'),
        designName: Value('Design A'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.lotDao.insertDesignColour(
      const DesignColoursCompanion(
        id: Value('colour-1'),
        lotDesignId: Value('design-1'),
        colourName: Value('Red'),
        initialQuantity: Value(100),
        unitPricePaise: Value(25000),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.processMemberDao.insertProcess(
      const ProcessesCompanion(
        id: Value('proc-1'),
        name: Value('Cutting'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.processMemberDao.insertMember(
      const MembersCompanion(
        id: Value('mem-1'),
        name: Value('Hasmukh Bhai'),
        address: Value('Surat'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.processMemberDao.insertMemberProcess(
      const MemberProcessesCompanion(
        id: Value('mp-1'),
        memberId: Value('mem-1'),
        processId: Value('proc-1'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  test('creates all 14 tables and seeds default business_profile', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name;",
        )
        .get();
    final tableNames = rows.map((r) => r.read<String>('name')).toSet();

    expect(tableNames, {
      'attachments',
      'audit_logs',
      'business_profile',
      'design_colours',
      'labour_entries',
      'lot_designs',
      'lots',
      'member_process_rates',
      'member_processes',
      'members',
      'payments',
      'processes',
      'stock_movements',
      'worker_ledger_adjustments',
    });

    final profile = await db.businessProfileDao.getProfile();
    expect(profile, isNotNull);
    expect(profile!.nameEn, 'Business Manager');
    expect(profile.nameGu, 'બિઝનેસ મેનેજર');
    expect(profile.defaultBillingMode, 'RECEIVED_QTY');
  });

  test('DatabaseInitializer verifies PRAGMAs and runs idempotently', () async {
    final initializer = DatabaseInitializer(db, AppLogger(AppConfig.dev()));
    final first = await initializer.initialize();
    final second = await initializer.initialize();

    expect(first.foreignKeysEnabled, isTrue);
    expect(first.isSynchronousFull, isTrue);
    expect(first.busyTimeoutMs, 5000);
    expect(identical(first, second), isTrue);
  });

  test('rejects invalid foreign keys across child tables', () async {
    await expectLater(
      db.lotDao.insertDesign(
        const LotDesignsCompanion(
          id: Value('d-bad'),
          lotId: Value('nonexistent-lot'),
          designName: Value('Invalid'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ),
      throwsA(isA<SqliteException>()),
    );

    await expectLater(
      db.processMemberDao.insertMemberProcess(
        const MemberProcessesCompanion(
          id: Value('mp-bad'),
          memberId: Value('missing-member'),
          processId: Value('missing-process'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test(
    'enforces unique partial indexes and allows soft-deleted reuse',
    () async {
      await seedBaseGraph();

      // Active duplicate lot number rejected
      await expectLater(
        db.lotDao.insertLot(
          const LotsCompanion(
            id: Value('lot-dup'),
            lotNumber: Value('1001'),
            transactionAt: Value(now),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        ),
        throwsA(isA<SqliteException>()),
      );

      // Case-insensitive duplicate active process rejected
      await expectLater(
        db.processMemberDao.insertProcess(
          const ProcessesCompanion(
            id: Value('proc-dup'),
            name: Value('cutting'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        ),
        throwsA(isA<SqliteException>()),
      );

      // Duplicate member-process link rejected
      await expectLater(
        db.processMemberDao.insertMemberProcess(
          const MemberProcessesCompanion(
            id: Value('mp-dup'),
            memberId: Value('mem-1'),
            processId: Value('proc-1'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        ),
        throwsA(isA<SqliteException>()),
      );

      // Invalid rate effective date range rejected
      await expectLater(
        db.processMemberDao.insertMemberProcessRate(
          const MemberProcessRatesCompanion(
            id: Value('rate-bad'),
            memberId: Value('mem-1'),
            processId: Value('proc-1'),
            ratePaise: Value(2000),
            effectiveFrom: Value('2026-12-01'),
            effectiveTo: Value('2026-11-30'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test(
    'enforces labour idempotency, client_request_id, and single reversal',
    () async {
      await seedBaseGraph();

      await db.stockMovementDao.insertMovement(
        const StockMovementsCompanion(
          id: Value('sm-1'),
          lotId: Value('lot-1'),
          lotDesignId: Value('design-1'),
          designColourId: Value('colour-1'),
          processId: Value('proc-1'),
          memberId: Value('mem-1'),
          clientRequestId: Value('req-1'),
          movementType: Value('ISSUE'),
          quantity: Value(50),
          appliedRatePaise: Value(2000),
          lockedBillingMode: Value('RECEIVED_QTY'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Duplicate client_request_id rejected
      await expectLater(
        db.stockMovementDao.insertMovement(
          const StockMovementsCompanion(
            id: Value('sm-dup-req'),
            lotId: Value('lot-1'),
            lotDesignId: Value('design-1'),
            designColourId: Value('colour-1'),
            processId: Value('proc-1'),
            memberId: Value('mem-1'),
            clientRequestId: Value('req-1'),
            movementType: Value('ISSUE'),
            quantity: Value(50),
            appliedRatePaise: Value(2000),
            lockedBillingMode: Value('RECEIVED_QTY'),
            transactionAt: Value(now),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        ),
        throwsA(isA<SqliteException>()),
      );

      // Single reversal enforced on stock_movements
      await db.stockMovementDao.insertMovement(
        const StockMovementsCompanion(
          id: Value('sm-rev-1'),
          lotId: Value('lot-1'),
          lotDesignId: Value('design-1'),
          designColourId: Value('colour-1'),
          reversesMovementId: Value('sm-1'),
          movementType: Value('REVERSAL'),
          quantity: Value(50),
          reason: Value('Wrong quantity'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await expectLater(
        db.stockMovementDao.insertMovement(
          const StockMovementsCompanion(
            id: Value('sm-rev-2'),
            lotId: Value('lot-1'),
            lotDesignId: Value('design-1'),
            designColourId: Value('colour-1'),
            reversesMovementId: Value('sm-1'),
            movementType: Value('REVERSAL'),
            quantity: Value(50),
            reason: Value('Duplicate reversal'),
            transactionAt: Value(now),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        ),
        throwsA(isA<SqliteException>()),
      );

      // Labour idempotency: duplicate (stock_movement_id, basis_type) rejected
      await db.labourEntryDao.insertEntry(
        const LabourEntriesCompanion(
          id: Value('lab-1'),
          stockMovementId: Value('sm-1'),
          memberId: Value('mem-1'),
          processId: Value('proc-1'),
          lotId: Value('lot-1'),
          basisType: Value('ISSUED'),
          quantity: Value(50),
          ratePaise: Value(2000),
          amountPaise: Value(100000),
          isPayable: Value(0),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await expectLater(
        db.labourEntryDao.insertEntry(
          const LabourEntriesCompanion(
            id: Value('lab-dup'),
            stockMovementId: Value('sm-1'),
            memberId: Value('mem-1'),
            processId: Value('proc-1'),
            lotId: Value('lot-1'),
            basisType: Value('ISSUED'),
            quantity: Value(50),
            ratePaise: Value(2000),
            amountPaise: Value(100000),
            isPayable: Value(0),
            transactionAt: Value(now),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        ),
        throwsA(isA<SqliteException>()),
      );

      // Single reversal enforced on payments
      await db.paymentDao.insertPayment(
        const PaymentsCompanion(
          id: Value('pay-1'),
          memberId: Value('mem-1'),
          paymentType: Value('ADVANCE'),
          amountPaise: Value(100000),
          paymentMode: Value('CASH'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.paymentDao.insertPayment(
        const PaymentsCompanion(
          id: Value('pay-rev-1'),
          memberId: Value('mem-1'),
          paymentType: Value('REVERSAL'),
          reversesPaymentId: Value('pay-1'),
          amountPaise: Value(100000),
          paymentMode: Value('CASH'),
          reason: Value('Entered twice'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await expectLater(
        db.paymentDao.insertPayment(
          const PaymentsCompanion(
            id: Value('pay-rev-2'),
            memberId: Value('mem-1'),
            paymentType: Value('REVERSAL'),
            reversesPaymentId: Value('pay-1'),
            amountPaise: Value(100000),
            paymentMode: Value('CASH'),
            reason: Value('Duplicate reversal'),
            transactionAt: Value(now),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test(
    'DatabaseTransactionRunner commits multi-table writes atomically',
    () async {
      await seedBaseGraph();

      await txRunner.runInTransaction(() async {
        await db.stockMovementDao.insertMovement(
          const StockMovementsCompanion(
            id: Value('sm-tx-1'),
            lotId: Value('lot-1'),
            lotDesignId: Value('design-1'),
            designColourId: Value('colour-1'),
            processId: Value('proc-1'),
            memberId: Value('mem-1'),
            movementType: Value('ISSUE'),
            quantity: Value(20),
            appliedRatePaise: Value(2000),
            lockedBillingMode: Value('RECEIVED_QTY'),
            transactionAt: Value(now),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        await db.labourEntryDao.insertEntry(
          const LabourEntriesCompanion(
            id: Value('lab-tx-1'),
            stockMovementId: Value('sm-tx-1'),
            memberId: Value('mem-1'),
            processId: Value('proc-1'),
            lotId: Value('lot-1'),
            basisType: Value('ISSUED'),
            quantity: Value(20),
            ratePaise: Value(2000),
            amountPaise: Value(40000),
            isPayable: Value(0),
            transactionAt: Value(now),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        await db.attachmentAuditDao.insertAuditLog(
          const AuditLogsCompanion(
            id: Value('aud-tx-1'),
            entityType: Value('stock_movements'),
            entityId: Value('sm-tx-1'),
            actionType: Value('CREATE'),
            transactionAt: Value(now),
            recordedAt: Value(now),
          ),
        );
      });

      expect(await db.stockMovementDao.findById('sm-tx-1'), isNotNull);
      expect(
        (await db.labourEntryDao.getEntriesForMovement('sm-tx-1')).length,
        1,
      );
      expect(
        (await db.attachmentAuditDao.getAuditLogsForEntity(
          'stock_movements',
          'sm-tx-1',
        )).length,
        1,
      );
    },
  );

  test('DatabaseTransactionRunner rolls back all tables on failure', () async {
    await seedBaseGraph();

    await expectLater(
      txRunner.runInTransaction(() async {
        await db.stockMovementDao.insertMovement(
          const StockMovementsCompanion(
            id: Value('sm-rb-1'),
            lotId: Value('lot-1'),
            lotDesignId: Value('design-1'),
            designColourId: Value('colour-1'),
            processId: Value('proc-1'),
            memberId: Value('mem-1'),
            movementType: Value('ISSUE'),
            quantity: Value(10),
            appliedRatePaise: Value(2000),
            lockedBillingMode: Value('RECEIVED_QTY'),
            transactionAt: Value(now),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        await db.attachmentAuditDao.insertAuditLog(
          const AuditLogsCompanion(
            id: Value('aud-rb-1'),
            entityType: Value('stock_movements'),
            entityId: Value('sm-rb-1'),
            actionType: Value('CREATE'),
            transactionAt: Value(now),
            recordedAt: Value(now),
          ),
        );
        throw StateError('Simulated mid-transaction failure');
      }),
      throwsStateError,
    );

    // Neither movement nor audit log was persisted
    expect(await db.stockMovementDao.findById('sm-rb-1'), isNull);
    expect(
      await db.attachmentAuditDao.getAuditLogsForEntity(
        'stock_movements',
        'sm-rb-1',
      ),
      isEmpty,
    );
  });
}
