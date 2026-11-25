import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

/// Opt-in realistic workshop dataset seeder strictly restricted to `dev` builds
/// launched with `--dart-define=SEED_PERF_DATA=true`.
///
/// Never runs in `prod` builds or standard test runs, and never mutates
/// production databases.
abstract final class DevPerfSeeder {
  static const bool enabled = bool.fromEnvironment('SEED_PERF_DATA');

  static Future<void> seedIfRequested({
    required AppConfig config,
    required AppDatabase db,
    required MediaStorageService mediaStorage,
    required AppLogger logger,
  }) async {
    if (!config.isDev || !enabled) return;

    final existingRow = await db
        .customSelect('SELECT COUNT(*) AS cnt FROM lots WHERE deleted_at IS NULL')
        .getSingle();
    final existingLots = (existingRow.data['cnt'] as num).toInt();
    if (existingLots >= 50) {
      logger.info('DevPerfSeeder: already seeded ($existingLots active lots).');
      return;
    }

    final sw = Stopwatch()..start();
    final now = IstDateTimeHelper.nowUtcMillis();
    const dayMs = 86400000;

    final processNames = [
      'Cutting',
      'Stitching',
      'Overlock',
      'Embroidery',
      'Buttoning',
      'Kaj / Buttonhole',
      'Thread Cutting',
      'Washing',
      'Steam Pressing',
      'Quality Check',
      'Tagging',
      'Folding & Packing',
      'Handwork / Zari',
      'Piping',
      'Interlock',
      'Lace Fixing',
      'Smocking',
      'Pleating',
      'Dyeing',
      'Dispatch QC',
    ];

    final colourPalette = <(String, String)>[
      ('Crimson Red', '#B91C1C'),
      ('Royal Navy', '#1E3A8A'),
      ('Emerald Teal', '#0F766E'),
      ('Marigold Amber', '#D97706'),
      ('Ivory Cream', '#F5F5DC'),
      ('Charcoal Slate', '#334155'),
      ('Dusty Rose', '#BE185D'),
      ('Olive Sage', '#4D7C0F'),
      ('Plum Wine', '#6B21A8'),
    ];

    await db.transaction(() async {
      // 1. Seed 20 processes
      for (var i = 0; i < processNames.length; i++) {
        final pid = 'perf-proc-${i + 1}';
        await db.into(db.processes).insertOnConflictUpdate(
          ProcessesCompanion.insert(
            id: pid,
            name: processNames[i],
            description: Value('Workshop stage ${i + 1} (${processNames[i]})'),
            isActive: Value(i < 17 ? 1 : 0),
            defaultRatePaise: Value((15 + (i % 8) * 5) * 100),
            createdAt: now - (30 * dayMs),
            updatedAt: now - (30 * dayMs),
          ),
        );
      }

      // 2. Seed 40 workers + assignments + effective rates
      for (var i = 0; i < 40; i++) {
        final wid = 'perf-worker-${i + 1}';
        await db.into(db.members).insertOnConflictUpdate(
          MembersCompanion.insert(
            id: wid,
            name: 'Karigar ${(i + 1).toString().padLeft(2, '0')} Patel',
            phone: Value('98765${(10000 + i * 137).toString().substring(0, 5)}'),
            address: Value('Unit ${(i % 6) + 1}, Surat Textile Market'),
            isActive: Value(i < 34 ? 1 : 0),
            createdAt: now - (30 * dayMs),
            updatedAt: now - (30 * dayMs),
          ),
        );

        final assignedProcIdx = i % 10;
        final pid = 'perf-proc-${assignedProcIdx + 1}';
        await db.into(db.memberProcesses).insertOnConflictUpdate(
          MemberProcessesCompanion.insert(
            id: 'perf-mp-${i + 1}',
            memberId: wid,
            processId: pid,
            createdAt: now - (28 * dayMs),
            updatedAt: now - (28 * dayMs),
          ),
        );
        await db.into(db.memberProcessRates).insertOnConflictUpdate(
          MemberProcessRatesCompanion.insert(
            id: 'perf-rate-${i + 1}',
            memberId: wid,
            processId: pid,
            ratePaise: (18 + (i % 12) * 3) * 100,
            effectiveFrom: '2026-01-01',
            createdAt: now - (28 * dayMs),
            updatedAt: now - (28 * dayMs),
          ),
        );
      }

      // 3. Seed 60 lots × 3 designs × 3 colours (540 SKUs) + rich newest lot (8 designs × 4 colours)
      final sampleSkuIds = <(String lotId, String designId, String colourId)>[];
      for (var l = 1; l <= 60; l++) {
        final lotId = 'perf-lot-$l';
        final txAt = now - ((60 - l) * dayMs ~/ 2);
        final status = l <= 48 ? 'ACTIVE' : 'COMPLETED';
        await db.into(db.lots).insertOnConflictUpdate(
          LotsCompanion.insert(
            id: lotId,
            lotNumber: 'LOT-${1000 + l}',
            title: Value('Festive Kurti Batch #$l'),
            notes: Value('High-volume workshop run for seasonal dispatch #$l'),
            status: Value(status),
            transactionAt: txAt,
            recordedAt: txAt,
            createdAt: txAt,
            updatedAt: txAt,
          ),
        );

        final designCount = l == 60 ? 8 : 3;
        final coloursPerDesign = l == 60 ? 4 : 3;
        for (var d = 1; d <= designCount; d++) {
          final designId = 'perf-des-$l-$d';
          await db.into(db.lotDesigns).insertOnConflictUpdate(
            LotDesignsCompanion.insert(
              id: designId,
              lotId: lotId,
              designName: 'Design D-$l$d',
              createdAt: txAt,
              updatedAt: txAt,
            ),
          );

          for (var c = 0; c < coloursPerDesign; c++) {
            final colourId = 'perf-col-$l-$d-$c';
            final pal = colourPalette[(l + d + c) % colourPalette.length];
            await db.into(db.designColours).insertOnConflictUpdate(
              DesignColoursCompanion.insert(
                id: colourId,
                lotDesignId: designId,
                colourName: pal.$1,
                colourHex: Value(pal.$2),
                initialQuantity: 120 + ((l + d + c) % 5) * 40,
                unitPricePaise: Value((240 + (c * 35)) * 100),
                createdAt: txAt,
                updatedAt: txAt,
              ),
            );
            if (sampleSkuIds.length < 90) {
              sampleSkuIds.add((lotId, designId, colourId));
            }
          }
        }
      }

      // 4. Seed 90 ISSUE movements + 70 partial/full RETURN_GOOD + 15 RETURN_DAMAGED + Labour + 80 Payments
      for (var i = 0; i < sampleSkuIds.length; i++) {
        final (lotId, designId, colourId) = sampleSkuIds[i];
        final workerIdx = i % 34;
        final workerId = 'perf-worker-${workerIdx + 1}';
        final procIdx = workerIdx % 10;
        final procId = 'perf-proc-${procIdx + 1}';
        final rateId = 'perf-rate-${workerIdx + 1}';
        final ratePaise = (18 + (workerIdx % 12) * 3) * 100;
        final txAt = now - ((90 - i) * 3600000);
        final issueId = 'perf-sm-iss-$i';

        await db.into(db.stockMovements).insertOnConflictUpdate(
          StockMovementsCompanion.insert(
            id: issueId,
            lotId: lotId,
            lotDesignId: designId,
            designColourId: colourId,
            processId: Value(procId),
            memberId: Value(workerId),
            movementType: 'ISSUE',
            quantity: 60,
            sourceRateId: Value(rateId),
            appliedRatePaise: Value(ratePaise),
            lockedBillingMode: const Value('RECEIVED_QTY'),
            transactionAt: txAt,
            recordedAt: txAt,
            createdAt: txAt,
            updatedAt: txAt,
          ),
        );

        if (i < 70) {
          final retQty = i < 45 ? 40 : 60;
          final retId = 'perf-sm-ret-$i';
          final retAt = txAt + 7200000;
          await db.into(db.stockMovements).insertOnConflictUpdate(
            StockMovementsCompanion.insert(
              id: retId,
              lotId: lotId,
              lotDesignId: designId,
              designColourId: colourId,
              processId: Value(procId),
              memberId: Value(workerId),
              parentIssueId: Value(issueId),
              movementType: 'RETURN_GOOD',
              quantity: retQty,
              sourceRateId: Value(rateId),
              appliedRatePaise: Value(ratePaise),
              lockedBillingMode: const Value('RECEIVED_QTY'),
              transactionAt: retAt,
              recordedAt: retAt,
              createdAt: retAt,
              updatedAt: retAt,
            ),
          );

          await db.into(db.labourEntries).insertOnConflictUpdate(
            LabourEntriesCompanion.insert(
              id: 'perf-lab-$i',
              stockMovementId: retId,
              memberId: workerId,
              processId: procId,
              lotId: lotId,
              basisType: 'RECEIVED_GOOD',
              quantity: retQty,
              ratePaise: ratePaise,
              amountPaise: retQty * ratePaise,
              isPayable: 1,
              transactionAt: retAt,
              recordedAt: retAt,
              createdAt: retAt,
              updatedAt: retAt,
            ),
          );
        }

        if (i < 15) {
          final dmgId = 'perf-sm-dmg-$i';
          final dmgAt = txAt + 10800000;
          await db.into(db.stockMovements).insertOnConflictUpdate(
            StockMovementsCompanion.insert(
              id: dmgId,
              lotId: lotId,
              lotDesignId: designId,
              designColourId: colourId,
              processId: Value(procId),
              memberId: Value(workerId),
              parentIssueId: Value(issueId),
              movementType: 'RETURN_DAMAGED',
              quantity: 5,
              sourceRateId: Value(rateId),
              appliedRatePaise: Value(ratePaise),
              lockedBillingMode: const Value('RECEIVED_QTY'),
              transactionAt: dmgAt,
              recordedAt: dmgAt,
              createdAt: dmgAt,
              updatedAt: dmgAt,
            ),
          );
        }
      }

      for (var p = 0; p < 80; p++) {
        final workerId = 'perf-worker-${(p % 34) + 1}';
        final payAt = now - ((80 - p) * 7200000);
        await db.into(db.payments).insertOnConflictUpdate(
          PaymentsCompanion.insert(
            id: 'perf-pay-$p',
            memberId: workerId,
            paymentType: p % 4 == 0 ? 'ADVANCE' : 'REGULAR',
            amountPaise: (250 + (p % 6) * 150) * 100,
            paymentMode: p % 3 == 0 ? 'UPI' : (p % 3 == 1 ? 'CASH' : 'BANK_TRANSFER'),
            referenceNo: Value('REF-${2000 + p}'),
            transactionAt: payAt,
            recordedAt: payAt,
            createdAt: payAt,
            updatedAt: payAt,
          ),
        );
      }
    });

    // 5. Attach 4 real sample photos to newest lot (perf-lot-60) for LotDetail photo profiling
    try {
      final byteData = await rootBundle.load(AppIdentity.symbolPngAsset);
      final bytes = byteData.buffer.asUint8List();
      for (var k = 1; k <= 4; k++) {
        final saved = await mediaStorage.saveBytes(
          bytes: bytes,
          category: MediaCategory.lots,
          entityId: 'perf-lot-60',
          fileExtension: 'png',
          mimeType: 'image/png',
        );
        await db.into(db.attachments).insertOnConflictUpdate(
          AttachmentsCompanion.insert(
            id: 'perf-photo-60-$k',
            entityType: 'LOT',
            entityId: 'perf-lot-60',
            relativePath: saved.relativePath,
            mimeType: saved.mimeType,
            fileSizeBytes: saved.fileSizeBytes,
            sha256: saved.sha256Hex,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    } catch (e) {
      logger.warning('DevPerfSeeder: skipped sample photos ($e)');
    }

    sw.stop();
    logger.info(
      'DevPerfSeeder: seeded 60 lots, 40 workers, 20 processes, 175 stock movements, 80 payments in ${sw.elapsedMilliseconds}ms.',
    );
  }
}
