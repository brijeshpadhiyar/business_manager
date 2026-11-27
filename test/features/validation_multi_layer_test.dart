import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/accounting/data/repositories/accounting_repository_impl.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/presentation/bloc/worker_ledger_cubit.dart';
import 'package:business_manager/features/business_profile/data/repositories/business_profile_repository_impl.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/business_profile/presentation/bloc/business_profile_cubit.dart';
import 'package:business_manager/features/business_profile/presentation/bloc/business_profile_state.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/parties/data/repositories/party_repository_impl.dart';
import 'package:business_manager/features/processes/data/repositories/process_repository_impl.dart';
import 'package:business_manager/features/rates/data/repositories/rate_repository_impl.dart';
import 'package:business_manager/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/reports/domain/services/report_export_service.dart';
import 'package:business_manager/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:business_manager/features/workers/data/repositories/worker_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final class _NoopExportService implements ReportExportService {
  @override
  Future<ReportExportResult> exportCsv({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
  }) async => const ReportExportResult(success: true, message: 'ok');

  @override
  Future<ReportExportResult> exportExcel({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
    bool fullWorkbook = false,
  }) async => const ReportExportResult(success: true, message: 'ok');

  @override
  Future<ReportExportResult> printOrSavePdf({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
    int? subTabIndex,
  }) async => const ReportExportResult(success: true, message: 'ok');
}

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late WorkerRepositoryImpl workerRepo;
  late BusinessProfileRepositoryImpl profileRepo;
  late ProcessRepositoryImpl processRepo;
  late LotRepositoryImpl lotRepo;
  late RateRepositoryImpl rateRepo;
  late StockMovementRepositoryImpl stockRepo;
  late AccountingRepositoryImpl acctRepo;
  late ReportsRepositoryImpl reportsRepo;

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_val_multi_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final tx = DatabaseTransactionRunner(db);
    final idGen = IdGenerator();
    final media = NativeMediaStorageService(
      config: AppConfig.dev(),
      idGenerator: idGen,
      baseDirectoryOverride: tempDir,
    );

    workerRepo = WorkerRepositoryImpl(db, tx, idGen);
    profileRepo = BusinessProfileRepositoryImpl(db, tx, idGen);
    processRepo = ProcessRepositoryImpl(db, tx, idGen);
    lotRepo = LotRepositoryImpl(db, tx, idGen, media);
    rateRepo = RateRepositoryImpl(db, tx, idGen);
    stockRepo = StockMovementRepositoryImpl(db, tx, idGen);
    acctRepo = AccountingRepositoryImpl(db, tx, idGen);
    final partyRepo = PartyRepositoryImpl(db, tx, idGen);
    reportsRepo = ReportsRepositoryImpl(db, stockRepo, acctRepo, partyRepo);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Repository Layer — Mobile, Length & Business Rule Enforcement', () {
    test('WorkerRepository rejects invalid phones & lengths, allows shared name/family phone', () async {
      await expectLater(
        workerRepo.createWorker(name: 'Ramesh', phone: '12345'),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'mobile_invalid_indian',
          ),
        ),
      );
      await expectLater(
        workerRepo.createWorker(name: 'Ramesh', phone: '98765abcde'),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'mobile_invalid_chars',
          ),
        ),
      );
      await expectLater(
        workerRepo.createWorker(name: 'A' * 121),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'text_too_long',
          ),
        ),
      );

      // Preserves existing business rule: shared names & family phones are allowed,
      // and original formatting is trimmed without auto-prepending +91.
      final w1 = await workerRepo.createWorker(
        name: 'Ramesh Patel',
        phone: ' 98765 43210 ',
      );
      final w2 = await workerRepo.createWorker(
        name: 'Ramesh Patel',
        phone: '98765 43210',
      );
      expect(w1.phone, '98765 43210');
      expect(w2.id, isNot(w1.id));
    });

    test('BusinessProfileRepository & Cubit validate phone and map validation codes', () async {
      final cubit = BusinessProfileCubit(profileRepo);
      await cubit.loadProfile();
      await cubit.saveProfile(
        nameEn: 'Patel Studio',
        nameGu: 'પટેલ સ્ટુડિયો',
        phone: '5555555555', // invalid Indian prefix
        defaultBillingMode: BillingMode.receivedQty,
      );
      expect(cubit.state.status, BusinessProfileStatus.error);
      expect(cubit.state.errorMessage, 'mobile_invalid_indian');
      await cubit.close();
    });

    test('LotRepository atomically blocks reducing initialQuantity below committed stock', () async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final lot = await lotRepo.createLot(
        lotNumber: 'LOT-VAL-1',
        transactionAtUtcMillis: now,
      );
      final design = await lotRepo.createDesign(
        lotId: lot.id,
        designName: 'D-1',
      );
      final colour = await lotRepo.createDesignColour(
        lotDesignId: design.id,
        colourName: 'Navy',
        initialQuantity: 100,
        unitPricePaise: 25000,
      );
      final proc = await processRepo.createProcess(name: 'Cutting');
      final worker = await workerRepo.createWorker(name: 'Suresh');
      await workerRepo.assignProcessToWorker(
        workerId: worker.id,
        processId: proc.id,
      );
      await rateRepo.addRate(
        workerId: worker.id,
        processId: proc.id,
        ratePaise: 2000,
        effectiveFrom: '2025-01-01',
      );

      // Issue 60 pieces -> 40 remain in-house, 60 committed with worker
      await stockRepo.issueStock(
        designColourId: colour.id,
        processId: proc.id,
        workerId: worker.id,
        quantity: 60,
        transactionAtUtcMillis: now,
      );

      // Reducing initialQuantity to 50 would create -10 available stock -> BLOCKED!
      await expectLater(
        lotRepo.updateDesignColour(
          designColourId: colour.id,
          colourName: 'Navy',
          initialQuantity: 50,
          unitPricePaise: 25000,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'quantity_below_committed_stock',
          ),
        ),
      );

      // Reducing to 60 (exact committed stock -> 0 available) is ALLOWED!
      final updated = await lotRepo.updateDesignColour(
        designColourId: colour.id,
        colourName: 'Navy',
        initialQuantity: 60,
        unitPricePaise: 25000,
      );
      expect(updated.initialQuantity, 60);
      final bal = await stockRepo.getDesignColourBalance(colour.id);
      expect(bal!.physicalAvailableInHouse, 0);
    });

    test('StockMovementRepository & AccountingRepository enforce upper bounds and strict override', () async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final lot = await lotRepo.createLot(
        lotNumber: 'LOT-VAL-2',
        transactionAtUtcMillis: now,
      );
      final design = await lotRepo.createDesign(
        lotId: lot.id,
        designName: 'D-2',
      );
      final colour = await lotRepo.createDesignColour(
        lotDesignId: design.id,
        colourName: 'Ivory',
        initialQuantity: 100,
        unitPricePaise: 10000,
      );
      final proc = await processRepo.createProcess(name: 'Stitching');
      final worker = await workerRepo.createWorker(name: 'Kishore');
      await workerRepo.assignProcessToWorker(
        workerId: worker.id,
        processId: proc.id,
      );
      await rateRepo.addRate(
        workerId: worker.id,
        processId: proc.id,
        ratePaise: 2500,
        effectiveFrom: '2025-01-01',
      );

      // Override enabled with null rate must throw invalid_rate (not silently ignore!)
      await expectLater(
        stockRepo.issueStock(
          designColourId: colour.id,
          processId: proc.id,
          workerId: worker.id,
          quantity: 10,
          transactionAtUtcMillis: now,
          allowRateOverride: true,
          overrideRatePaise: null,
          overrideReason: 'Urgent',
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'invalid_rate',
          ),
        ),
      );

      // Payment exceeding maxAmountPaise rejected
      await expectLater(
        acctRepo.recordPayment(
          workerId: worker.id,
          paymentType: PaymentType.regular,
          amountPaise: ValidationLimits.maxAmountPaise + 1,
          paymentMode: PaymentMode.cash,
          transactionAtUtcMillis: now,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'amount_too_large',
          ),
        ),
      );

      // Idempotent payment replay prevents duplicate ledger entries
      final reqId = IdGenerator().nextRequestId();
      final p1 = await acctRepo.recordPayment(
        workerId: worker.id,
        paymentType: PaymentType.regular,
        amountPaise: 50000,
        paymentMode: PaymentMode.upi,
        transactionAtUtcMillis: now,
        clientRequestId: reqId,
      );
      final p2 = await acctRepo.recordPayment(
        workerId: worker.id,
        paymentType: PaymentType.regular,
        amountPaise: 50000,
        paymentMode: PaymentMode.upi,
        transactionAtUtcMillis: now,
        clientRequestId: reqId,
      );
      expect(p2.id, p1.id);
      final allPayments = await acctRepo.getPayments(workerId: worker.id);
      expect(allPayments.length, 1);
    });
  });

  group('BLoC Layer — Date Range Validation (ReportsCubit & WorkerLedgerCubit)', () {
    test('ReportsCubit rejects end date earlier than start date with dateRangeErrorCode', () async {
      final cubit = ReportsCubit(reportsRepo, _NoopExportService());
      await cubit.loadReports();

      final start = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 5,
        day: 20,
      );
      final earlierEnd = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 5,
        day: 10,
      );
      await cubit.setCustomDateRange(
        fromUtcMillis: start,
        toUtcMillis: earlierEnd,
      );
      expect(cubit.state.dateRangeErrorCode, 'invalid_date_range');

      // Fixing to a valid range clears the error
      final validEnd = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 5,
        day: 25,
      );
      await cubit.setCustomDateRange(
        fromUtcMillis: start,
        toUtcMillis: validEnd,
      );
      expect(cubit.state.dateRangeErrorCode, isNull);
      await cubit.close();
    });

    test('WorkerLedgerCubit rejects end date earlier than start date', () async {
      final worker = await workerRepo.createWorker(name: 'Mahesh');
      final cubit = WorkerLedgerCubit(acctRepo);
      await cubit.loadLedger(worker.id);

      final start = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 6,
        day: 15,
      );
      final earlierEnd = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 6,
        day: 1,
      );
      await cubit.loadLedger(
        worker.id,
        fromUtcMillis: start,
        toUtcMillis: earlierEnd,
      );
      expect(cubit.state.dateRangeErrorCode, 'invalid_date_range');

      await cubit.loadLedger(
        worker.id,
        fromUtcMillis: earlierEnd,
        toUtcMillis: start,
      );
      expect(cubit.state.dateRangeErrorCode, isNull);
      await cubit.close();
    });
  });
}
