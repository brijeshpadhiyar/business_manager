import 'dart:typed_data';

import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/lots/presentation/bloc/lot_detail_cubit.dart';
import 'package:business_manager/features/lots/presentation/pages/lot_detail_page.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/domain/repositories/process_routing_repository.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockLotRepository extends Mock implements LotRepository {}

class _MockRoutingRepository extends Mock implements ProcessRoutingRepository {}

void main() {
  late _MockLotRepository lotRepo;
  late _MockRoutingRepository routingRepo;

  // Minimal valid 1x1 transparent PNG
  final png1x1 = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  const ts = 1700000000000;
  const sampleLot = LotEntity(
    id: 'lot-1',
    lotNumber: 'LOT-1001',
    title: 'Perf Test Lot',
    status: LotStatus.active,
    transactionAt: ts,
    recordedAt: ts,
    createdAt: ts,
    updatedAt: ts,
  );

  const sampleDetail = LotDetailAggregate(
    lot: sampleLot,
    designs: [
      DesignWithColours(
        design: LotDesignEntity(
          id: 'des-1',
          lotId: 'lot-1',
          designName: 'Floral Kurti',
          createdAt: ts,
          updatedAt: ts,
        ),
        colours: [
          DesignColourEntity(
            id: 'col-1',
            lotDesignId: 'des-1',
            colourName: 'Crimson Red',
            colourHex: '#B91C1C',
            initialQuantity: 100,
            unitPricePaise: 25000,
            createdAt: ts,
            updatedAt: ts,
          ),
        ],
      ),
      DesignWithColours(
        design: LotDesignEntity(
          id: 'des-2',
          lotId: 'lot-1',
          designName: 'Anarkali Set',
          createdAt: ts,
          updatedAt: ts,
        ),
        colours: [
          DesignColourEntity(
            id: 'col-2',
            lotDesignId: 'des-2',
            colourName: 'Royal Navy',
            colourHex: '#1E3A8A',
            initialQuantity: 80,
            unitPricePaise: 32000,
            createdAt: ts,
            updatedAt: ts,
          ),
        ],
      ),
    ],
    photos: [
      LotAttachmentEntity(
        id: 'att-1',
        lotId: 'lot-1',
        relativePath: 'lots/lot-1/p1.png',
        mimeType: 'image/png',
        fileSizeBytes: 67,
        sha256: 'deadbeef',
        createdAt: ts,
      ),
    ],
  );

  const sampleRouting = JobRoutingOverview(
    lot: sampleLot,
    skuBalances: [],
    jobProcesses: [],
    handovers: [],
    currentLocations: [],
    availableProcesses: [],
    availableWorkers: [],
  );

  setUp(() async {
    await getIt.reset();
    lotRepo = _MockLotRepository();
    routingRepo = _MockRoutingRepository();

    when(() => lotRepo.getLotDetail('lot-1')).thenAnswer((_) async => sampleDetail);
    when(() => lotRepo.readPhotoBytes('lots/lot-1/p1.png'))
        .thenAnswer((_) async => png1x1);
    when(() => routingRepo.getJobRoutingOverview('lot-1'))
        .thenAnswer((_) async => sampleRouting);

    getIt.registerFactory<LotDetailCubit>(
      () => LotDetailCubit(lotRepo, routingRepo),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'PF-01: typing in Design Search triggers 0 extra DB routing queries and 0 extra photo disk reads',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LotDetailPage(lotId: 'lot-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Loaded once on initial screen mount
      verify(() => lotRepo.getLotDetail('lot-1')).called(1);
      verify(() => routingRepo.getJobRoutingOverview('lot-1')).called(1);
      verify(() => lotRepo.readPhotoBytes('lots/lot-1/p1.png')).called(1);

      // Type multiple queries into Design Search
      final searchField = find.byType(TextFormField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Floral');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Floral Kurti'), findsOneWidget);
      expect(find.text('Anarkali Set'), findsNothing);

      await tester.enterText(searchField, 'Navy');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Anarkali Set'), findsOneWidget);
      expect(find.text('Floral Kurti'), findsNothing);

      await tester.enterText(searchField, '');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Zero extra DB or disk reads triggered by typing!
      verifyNever(() => lotRepo.getLotDetail(any()));
      verifyNever(() => routingRepo.getJobRoutingOverview(any()));
      verifyNever(() => lotRepo.readPhotoBytes(any()));
    },
  );
}
