import 'dart:io';
import 'dart:typed_data';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late NativeMediaStorageService media;
  late LotRepositoryImpl repo;
  const now = 1795324800000;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_lots_test_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    media = NativeMediaStorageService(
      config: AppConfig.dev(),
      idGenerator: IdGenerator(),
      baseDirectoryOverride: tempDir,
    );
    repo = LotRepositoryImpl(
      db,
      DatabaseTransactionRunner(db),
      IdGenerator(),
      media,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Lots: create, update, duplicate rejection, search, filter, archive',
    () async {
      final lot1 = await repo.createLot(
        lotNumber: 'LOT-001',
        title: 'Festive Kurti',
        transactionAtUtcMillis: now,
      );
      await repo.createLot(
        lotNumber: 'LOT-002',
        title: 'Cotton Kurta',
        transactionAtUtcMillis: now,
      );

      // Duplicate active lot number rejected
      await expectLater(
        repo.createLot(lotNumber: 'LOT-001', transactionAtUtcMillis: now),
        throwsA(isA<SqliteException>()),
      );

      // Search
      final searched = await repo.getLots(searchQuery: 'festive');
      expect(searched.length, 1);
      expect(searched.first.lotNumber, 'LOT-001');

      // Update status to COMPLETED & filter
      await repo.updateLot(
        lotId: lot1.id,
        lotNumber: 'LOT-001',
        title: 'Festive Kurti',
        status: LotStatus.completed,
        transactionAtUtcMillis: now,
      );
      expect((await repo.getLots(status: LotStatus.completed)).length, 1);
      expect((await repo.getLots(status: LotStatus.active)).length, 1);

      // Archive (soft delete, never physical delete)
      await repo.archiveLot(lot1.id);
      expect((await repo.getLots()).length, 1);
      final archived = await repo.getLots(status: LotStatus.archived);
      expect(archived.map((l) => l.id), [lot1.id]);
      final rawRow = await db.lotDao.findLotById(lot1.id);
      expect(rawRow, isNotNull);
      expect(rawRow!.deletedAt, isNotNull);

      // Unarchive restores the lot to active list; duplicate active lot number blocked
      await repo.unarchiveLot(lot1.id);
      expect((await repo.getLots(status: LotStatus.archived)), isEmpty);
      expect((await repo.getLots()).length, 2);

      final lot1Dup = await repo.createLot(
        lotNumber: 'LOT-001-ALT',
        transactionAtUtcMillis: now,
      );
      await repo.archiveLot(lot1.id);
      await repo.updateLot(
        lotId: lot1Dup.id,
        lotNumber: 'LOT-001',
        title: 'Duplicate Active',
        status: LotStatus.active,
        transactionAtUtcMillis: now,
      );
      await expectLater(
        () => repo.unarchiveLot(lot1.id),
        throwsA(isA<DomainValidationException>()),
      );
    },
  );

  test(
    'Designs & Colours: independent quantities/prices and duplicate guards',
    () async {
      final lot = await repo.createLot(
        lotNumber: 'LOT-001',
        transactionAtUtcMillis: now,
      );
      final d1 = await repo.createDesign(lotId: lot.id, designName: 'D-101');
      final d2 = await repo.createDesign(lotId: lot.id, designName: 'D-102');

      // Duplicate design in same lot rejected (case-insensitive)
      await expectLater(
        repo.createDesign(lotId: lot.id, designName: 'd-101'),
        throwsA(isA<SqliteException>()),
      );

      // Independent colours in D-101
      final red = await repo.createDesignColour(
        lotDesignId: d1.id,
        colourName: 'Red',
        initialQuantity: 100,
        unitPricePaise: 25000,
      );
      final blue = await repo.createDesignColour(
        lotDesignId: d1.id,
        colourName: 'Blue',
        initialQuantity: 80,
        unitPricePaise: 25000,
      );
      final black = await repo.createDesignColour(
        lotDesignId: d1.id,
        colourName: 'Black',
        initialQuantity: 120,
        unitPricePaise: 27500,
      );

      expect(red.initialQuantity, 100);
      expect(blue.initialQuantity, 80);
      expect(black.initialQuantity, 120);
      expect(black.unitPricePaise, 27500);

      // Duplicate colour in same design rejected
      await expectLater(
        repo.createDesignColour(
          lotDesignId: d1.id,
          colourName: 'red',
          initialQuantity: 10,
          unitPricePaise: 1000,
        ),
        throwsA(isA<SqliteException>()),
      );

      // Same colour name allowed in another design (D-102)
      await repo.createDesignColour(
        lotDesignId: d2.id,
        colourName: 'Red',
        initialQuantity: 50,
        unitPricePaise: 30000,
      );

      // Invalid quantity & negative price rejected
      await expectLater(
        repo.createDesignColour(
          lotDesignId: d2.id,
          colourName: 'Green',
          initialQuantity: 0,
          unitPricePaise: 1000,
        ),
        throwsArgumentError,
      );
      await expectLater(
        repo.createDesignColour(
          lotDesignId: d2.id,
          colourName: 'Green',
          initialQuantity: 10,
          unitPricePaise: -50,
        ),
        throwsArgumentError,
      );

      final detail = await repo.getLotDetail(lot.id);
      expect(detail!.designs.length, 2);
      expect(detail.designs.first.colours.length, 3);
    },
  );

  test('Photos: save with SHA-256, missing file handling, and orphan cleanup on DB failure', () async {
    final lot = await repo.createLot(
      lotNumber: 'LOT-PHOTO',
      transactionAtUtcMillis: now,
    );
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

    final saved = await repo.addLotPhoto(
      lotId: lot.id,
      bytes: bytes,
      fileExtension: 'jpg',
      mimeType: 'image/jpeg',
    );
    expect(saved.sha256, media.computeSha256(bytes));
    expect(await repo.readPhotoBytes(saved.relativePath), equals(bytes));

    // Missing physical file handled gracefully (returns null instead of crashing)
    await media.deleteIfExists(saved.relativePath);
    expect(await repo.readPhotoBytes(saved.relativePath), isNull);

    // Orphan-file cleanup when DB insert fails (non-existent parent lot)
    await expectLater(
      repo.addLotPhoto(
        lotId: 'missing-lot-id',
        bytes: bytes,
        fileExtension: 'jpg',
        mimeType: 'image/jpeg',
      ),
      throwsA(isA<LocalStorageException>()),
    );
    final orphanFiles = tempDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('missing-lot-id'))
        .toList();
    expect(orphanFiles, isEmpty);
  });
}
