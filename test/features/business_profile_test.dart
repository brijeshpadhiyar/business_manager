import 'dart:io';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/business_profile/data/repositories/business_profile_repository_impl.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_profile_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'loads seeded profile, updates it, audits it, and persists across reopen',
    () async {
      final dbFile = File('${tempDir.path}/profile_test.sqlite');
      final db1 = AppDatabase.forTesting(NativeDatabase(dbFile));
      final repo1 = BusinessProfileRepositoryImpl(
        db1,
        DatabaseTransactionRunner(db1),
        IdGenerator(),
      );

      final initial = await repo1.getProfile();
      expect(initial.nameEn, 'Business Manager');
      expect(initial.defaultBillingMode, BillingMode.receivedQty);

      final updated = await repo1.updateProfile(
        nameEn: 'Patel Garments',
        nameGu: 'પટેલ ગાર્મેન્ટ્સ',
        ownerName: 'Rameshbhai',
        phone: '9876543210',
        address: 'Surat Textile Market',
        defaultBillingMode: BillingMode.givenQty,
      );

      expect(updated.nameEn, 'Patel Garments');
      expect(updated.nameGu, 'પટેલ ગાર્મેન્ટ્સ');
      expect(updated.defaultBillingMode, BillingMode.givenQty);

      final audits = await db1.attachmentAuditDao.getAuditLogsForEntity(
        'business_profile',
        'default',
      );
      expect(audits.length, 1);
      expect(audits.first.actionType, 'UPDATE');
      await db1.close();

      // Reopen and verify persistence
      final db2 = AppDatabase.forTesting(NativeDatabase(dbFile));
      final repo2 = BusinessProfileRepositoryImpl(
        db2,
        DatabaseTransactionRunner(db2),
        IdGenerator(),
      );
      final reopened = await repo2.getProfile();
      expect(reopened.nameEn, 'Patel Garments');
      expect(reopened.nameGu, 'પટેલ ગાર્મેન્ટ્સ');
      expect(reopened.ownerName, 'Rameshbhai');
      expect(reopened.defaultBillingMode, BillingMode.givenQty);
      await db2.close();
    },
  );

  test('rejects blank English or Gujarati business names', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = BusinessProfileRepositoryImpl(
      db,
      DatabaseTransactionRunner(db),
      IdGenerator(),
    );

    await expectLater(
      repo.updateProfile(
        nameEn: '   ',
        nameGu: 'પટેલ',
        defaultBillingMode: BillingMode.receivedQty,
      ),
      throwsArgumentError,
    );
    await expectLater(
      repo.updateProfile(
        nameEn: 'Patel',
        nameGu: '',
        defaultBillingMode: BillingMode.receivedQty,
      ),
      throwsArgumentError,
    );

    await db.close();
  });
}
