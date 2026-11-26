import 'package:business_manager/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').getSingle();
  });

  tearDown(() async {
    await db.close();
  });

  test('5,000-movement scale benchmark: SQLite paged & cursor queries stay fast and duplicate-free', () async {
    final baseTs = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;

    // Seed 150 lots, 50 workers, 1 process, and 5,000 stock movements inside a
    // single transaction with remote-apply guard so seed runs in < 1s.
    await db.syncDao.runAsRemoteApply(() async {
      await db.processMemberDao.insertProcess(
        ProcessesCompanion.insert(
          id: 'proc-1',
          name: 'Stitching',
          createdAt: baseTs,
          updatedAt: baseTs,
        ),
      );

      for (var w = 0; w < 50; w++) {
        await db.processMemberDao.insertMember(
          MembersCompanion.insert(
            id: 'w-$w',
            name: 'Worker ${w.toString().padLeft(3, '0')}',
            phone: Value('98765${w.toString().padLeft(5, '0')}'),
            createdAt: baseTs + w,
            updatedAt: baseTs + w,
          ),
        );
      }

      for (var l = 0; l < 150; l++) {
        final lotId = 'lot-$l';
        final desId = 'des-$l';
        final colId = 'col-$l';
        await db.lotDao.insertLot(
          LotsCompanion.insert(
            id: lotId,
            lotNumber: 'LOT-${l.toString().padLeft(4, '0')}',
            title: Value('Batch $l'),
            transactionAt: baseTs + l * 1000,
            recordedAt: baseTs + l * 1000,
            createdAt: baseTs + l * 1000,
            updatedAt: baseTs + l * 1000,
          ),
        );
        await db.lotDao.insertDesign(
          LotDesignsCompanion.insert(
            id: desId,
            lotId: lotId,
            designName: 'Design $l',
            createdAt: baseTs + l,
            updatedAt: baseTs + l,
          ),
        );
        await db.lotDao.insertDesignColour(
          DesignColoursCompanion.insert(
            id: colId,
            lotDesignId: desId,
            colourName: 'Indigo',
            initialQuantity: 10000,
            unitPricePaise: const Value(5000),
            createdAt: baseTs + l,
            updatedAt: baseTs + l,
          ),
        );
      }

      await db.batch((batch) {
        for (var m = 0; m < 5000; m++) {
          final lotIdx = m % 150;
          final workerIdx = m % 50;
          final ts = baseTs + m * 60000;
          batch.insert(
            db.stockMovements,
            StockMovementsCompanion.insert(
              id: 'sm-${m.toString().padLeft(5, '0')}',
              lotId: 'lot-$lotIdx',
              lotDesignId: 'des-$lotIdx',
              designColourId: 'col-$lotIdx',
              processId: const Value('proc-1'),
              memberId: Value('w-$workerIdx'),
              movementType: 'ISSUE',
              quantity: 10,
              appliedRatePaise: const Value(2500),
              transactionAt: ts,
              recordedAt: ts,
              createdAt: ts,
              updatedAt: ts,
            ),
          );
        }
      });
    });

    // 1. Offset-paged Lots query (with search)
    final lotSw = Stopwatch()..start();
    final lotPage1 = await db.lotDao.getLotsPaged(limit: 25, offset: 0);
    final lotPage2 = await db.lotDao.getLotsPaged(limit: 25, offset: 25);
    final lotSearch = await db.lotDao.getLotsPaged(
      limit: 25,
      offset: 0,
      searchQuery: 'LOT-0042',
    );
    lotSw.stop();
    expect(lotPage1.totalCount, 150);
    expect(lotPage1.items, hasLength(25));
    expect(lotPage1.hasMore, isTrue);
    expect(lotPage2.items, hasLength(25));
    expect(
      lotPage1.items.map((e) => e.id).toSet().intersection(
        lotPage2.items.map((e) => e.id).toSet(),
      ),
      isEmpty,
    );
    expect(lotSearch.totalCount, 1);
    expect(lotSearch.items.first.lotNumber, 'LOT-0042');
    expect(lotSw.elapsedMilliseconds, lessThan(250));

    // 2. Offset-paged Members query
    final memPage = await db.processMemberDao.getMembersPaged(
      limit: 20,
      offset: 0,
      isActive: true,
    );
    expect(memPage.totalCount, 50);
    expect(memPage.items, hasLength(20));
    expect(memPage.hasMore, isTrue);

    // 3. Keyset/Cursor-paged Stock Movements across 5,000 rows
    final smSw = Stopwatch()..start();
    final smPage1 = await db.stockMovementDao.getMovementsPaged(limit: 100);
    final smPage2 = await db.stockMovementDao.getMovementsPaged(
      limit: 100,
      cursorTransactionAt: smPage1.nextCursorTransactionAt,
      cursorId: smPage1.nextCursorId,
    );
    final smByWorker = await db.stockMovementDao.getMovementsPaged(
      limit: 50,
      memberId: 'w-7',
    );
    smSw.stop();

    expect(smPage1.totalCount, 5000);
    expect(smPage1.items, hasLength(100));
    expect(smPage1.hasMore, isTrue);
    expect(smPage2.items, hasLength(100));
    expect(
      smPage1.items.map((e) => e.id).toSet().intersection(
        smPage2.items.map((e) => e.id).toSet(),
      ),
      isEmpty,
    );
    expect(
      smPage1.items.last.transactionAt,
      greaterThan(smPage2.items.first.transactionAt),
    );
    expect(smByWorker.totalCount, 100); // 5000 / 50 workers
    expect(smSw.elapsedMilliseconds, lessThan(250));

    // 4. Verify SQLite uses indexes on hot-path cursor query
    final plan = await db.customSelect(
      'EXPLAIN QUERY PLAN '
      'SELECT * FROM stock_movements '
      'WHERE member_id = ? '
      'ORDER BY transaction_at DESC, id DESC LIMIT 50',
      variables: [const Variable<String>('w-7')],
    ).get();
    final planText = plan
        .map((r) => r.data.values.join(' '))
        .join('\n')
        .toUpperCase();
    expect(planText, contains('INDEX'));
  });
}
