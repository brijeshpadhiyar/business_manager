import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/mappers/actor_resolver.dart';
import 'package:business_manager/core/database/mappers/ledger_row_mappers.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/lots/data/repositories/lot_media_and_variant_delegate.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_routing_validator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/production_history/data/repositories/production_history_dataset_loader.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_history_calculator.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LotRepository)
final class LotRepositoryImpl implements LotRepository {
  LotRepositoryImpl(
    this._db,
    this._txRunner,
    this._idGenerator,
    MediaStorageService mediaStorage,
  ) : _delegate = LotMediaAndVariantDelegate(
        _db,
        _txRunner,
        _idGenerator,
        mediaStorage,
      );

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;
  final LotMediaAndVariantDelegate _delegate;

  @override
  Future<List<LotEntity>> getLots({
    String? searchQuery,
    LotStatus? status,
  }) async {
    final rows = status == LotStatus.archived
        ? await _db.lotDao.getArchivedLots()
        : await _db.lotDao.getActiveLots();
    final q = searchQuery?.trim().toLowerCase() ?? '';
    return rows
        .where((row) {
          if (status != null && row.status != status.dbValue) return false;
          if (q.isEmpty) return true;
          return row.lotNumber.toLowerCase().contains(q) ||
              (row.title?.toLowerCase().contains(q) ?? false) ||
              (row.notes?.toLowerCase().contains(q) ?? false);
        })
        .map(LotMediaAndVariantDelegate.lotToEntity)
        .toList();
  }

  @override
  Future<LotDetailAggregate?> getLotDetail(String lotId) async {
    final lotRow = await _db.lotDao.findLotById(lotId);
    if (lotRow == null || lotRow.deletedAt != null) return null;

    final designRows = await _db.lotDao.getDesignsForLot(lotId);
    final designIds = designRows.map((d) => d.id).toList(growable: false);
    final allColourRows = await _db.lotDao.getColoursForDesigns(designIds);
    final coloursByDesign = <String, List<DesignColourEntity>>{};
    for (final c in allColourRows) {
      coloursByDesign
          .putIfAbsent(c.lotDesignId, () => <DesignColourEntity>[])
          .add(LotMediaAndVariantDelegate.colourToEntity(c));
    }
    final designsWithColours = designRows
        .map(
          (d) => DesignWithColours(
            design: LotMediaAndVariantDelegate.designToEntity(d),
            colours: coloursByDesign[d.id] ?? const <DesignColourEntity>[],
          ),
        )
        .toList(growable: false);

    final photoRows = await _db.attachmentAuditDao.getActiveAttachments(
      'LOT',
      lotId,
    );

    return LotDetailAggregate(
      lot: LotMediaAndVariantDelegate.lotToEntity(lotRow),
      designs: designsWithColours,
      photos: photoRows
          .map(LotMediaAndVariantDelegate.attachmentToEntity)
          .toList(),
    );
  }

  @override
  Future<LotEntity> createLot({
    required String lotNumber,
    String? title,
    String? notes,
    required int transactionAtUtcMillis,
  }) async {
    final cleanNumber = lotNumber.trim();
    if (cleanNumber.isEmpty) {
      throw ArgumentError('Lot number cannot be empty.');
    }
    if (cleanNumber.length > ValidationLimits.maxShortNameLength ||
        (title?.trim().length ?? 0) > ValidationLimits.maxPersonNameLength ||
        (notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Entered lot details exceed maximum allowed length.',
      );
    }
    if (!AppValidators.dateValidator(transactionAtUtcMillis).isValid) {
      throw const DomainValidationException(
        'invalid_date',
        'Lot transaction date is invalid.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final id = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.lotDao.insertLot(
        LotsCompanion(
          id: Value(id),
          lotNumber: Value(cleanNumber),
          title: Value(LotMediaAndVariantDelegate.nullIfBlank(title)),
          notes: Value(LotMediaAndVariantDelegate.nullIfBlank(notes)),
          status: const Value('ACTIVE'),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('lots'),
          entityId: Value(id),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'lot_number': cleanNumber,
              'title': LotMediaAndVariantDelegate.nullIfBlank(title),
            }),
          ),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final created = await _db.lotDao.findLotById(id);
      return LotMediaAndVariantDelegate.lotToEntity(created!);
    });
  }

  @override
  Future<List<String>> getDistinctDesignNames() async {
    final activeLots = await _db.lotDao.getActiveLots();
    final activeLotIds = {for (final l in activeLots) l.id};
    final designs = await _db.lotDao.getAllActiveDesigns();
    final seenLower = <String>{};
    final result = <String>[];
    for (final d in designs) {
      if (!activeLotIds.contains(d.lotId)) continue;
      final trimmed = d.designName.trim();
      if (trimmed.isEmpty || trimmed == kColourOnlyDesignSentinel) continue;
      final lower = trimmed.toLowerCase();
      if (seenLower.add(lower)) {
        result.add(trimmed);
      }
    }
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  @override
  Future<LotEntity> createLotComplete({
    required String lotNumber,
    String? title,
    String? notes,
    required int transactionAtUtcMillis,
    required List<LotDesignDraftInput> designs,
    List<InitialLotProcessAssignmentInput> initialAssignments = const [],
  }) async {
    final cleanNumber = lotNumber.trim();
    if (cleanNumber.isEmpty) {
      throw const DomainValidationException(
        'lot_number_required',
        'Lot number cannot be empty.',
      );
    }
    if (cleanNumber.length > ValidationLimits.maxShortNameLength ||
        (title?.trim().length ?? 0) > ValidationLimits.maxPersonNameLength ||
        (notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Entered lot details exceed maximum allowed length.',
      );
    }
    if (!AppValidators.dateValidator(transactionAtUtcMillis).isValid) {
      throw const DomainValidationException(
        'invalid_date',
        'Lot transaction date is invalid.',
      );
    }

    final seenDesignNames = <String>{};
    for (final design in designs) {
      final cleanDesign = design.designName.trim();
      if (cleanDesign.isEmpty) {
        throw const DomainValidationException(
          'design_name_required',
          'Design name cannot be empty.',
        );
      }
      if (cleanDesign.length > ValidationLimits.maxShortNameLength ||
          (design.notes?.trim().length ?? 0) >
              ValidationLimits.maxNotesLength) {
        throw const DomainValidationException(
          'text_too_long',
          'Design name or notes exceed maximum allowed length.',
        );
      }
      if (!seenDesignNames.add(cleanDesign.toLowerCase())) {
        throw const DomainValidationException(
          'duplicate_design_name',
          'Duplicate design name in the same lot.',
        );
      }
      final seenColours = <String>{};
      for (final colour in design.colours) {
        LotMediaAndVariantDelegate.validateColourDraft(colour);
        if (!seenColours.add(colour.colourName.trim().toLowerCase())) {
          throw const DomainValidationException(
            'duplicate_colour_name',
            'Duplicate colour name under the same design.',
          );
        }
      }
    }

    return _txRunner.runInTransaction(() async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final lotId = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.lotDao.insertLot(
        LotsCompanion(
          id: Value(lotId),
          lotNumber: Value(cleanNumber),
          title: Value(LotMediaAndVariantDelegate.nullIfBlank(title)),
          notes: Value(LotMediaAndVariantDelegate.nullIfBlank(notes)),
          status: const Value('ACTIVE'),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('lots'),
          entityId: Value(lotId),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'lot_number': cleanNumber,
              'title': LotMediaAndVariantDelegate.nullIfBlank(title),
              'designs_count': designs.length,
            }),
          ),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final createdSkuByKey =
          <String, ({String designId, String colourId, int available})>{};

      for (final design in designs) {
        final designId = _idGenerator.nextEntityId();
        final cleanDesign = design.designName.trim();
        await _db.lotDao.insertDesign(
          LotDesignsCompanion(
            id: Value(designId),
            lotId: Value(lotId),
            designName: Value(cleanDesign),
            notes: Value(LotMediaAndVariantDelegate.nullIfBlank(design.notes)),
            createdBy: Value(actor),
            updatedBy: Value(actor),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        await _db.attachmentAuditDao.insertAuditLog(
          AuditLogsCompanion(
            id: Value(_idGenerator.nextEntityId()),
            entityType: const Value('lot_designs'),
            entityId: Value(designId),
            actionType: const Value('CREATE'),
            actor: Value(actor),
            newValueJson: Value(
              jsonEncode({'lot_id': lotId, 'design_name': cleanDesign}),
            ),
            transactionAt: Value(transactionAtUtcMillis),
            recordedAt: Value(now),
          ),
        );

        for (final colour in design.colours) {
          final colourId = _idGenerator.nextEntityId();
          final cleanColour = colour.colourName.trim();
          await _db.lotDao.insertDesignColour(
            DesignColoursCompanion(
              id: Value(colourId),
              lotDesignId: Value(designId),
              colourName: Value(cleanColour),
              colourHex: Value(
                LotMediaAndVariantDelegate.nullIfBlank(colour.colourHex),
              ),
              initialQuantity: Value(colour.initialQuantity),
              unitPricePaise: Value(colour.unitPricePaise),
              notes: Value(
                LotMediaAndVariantDelegate.nullIfBlank(colour.notes),
              ),
              createdBy: Value(actor),
              updatedBy: Value(actor),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
          await _db.attachmentAuditDao.insertAuditLog(
            AuditLogsCompanion(
              id: Value(_idGenerator.nextEntityId()),
              entityType: const Value('design_colours'),
              entityId: Value(colourId),
              actionType: const Value('CREATE'),
              actor: Value(actor),
              newValueJson: Value(
                jsonEncode({
                  'lot_design_id': designId,
                  'colour_name': cleanColour,
                  'initial_quantity': colour.initialQuantity,
                  'unit_price_paise': colour.unitPricePaise,
                }),
              ),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
            ),
          );

          final skuKey =
              '${cleanDesign.toLowerCase()}::${cleanColour.toLowerCase()}';
          createdSkuByKey[skuKey] = (
            designId: designId,
            colourId: colourId,
            available: colour.initialQuantity,
          );
        }
      }

      var seqOrder = 1;
      for (final assign in initialAssignments) {
        if (assign.quantity <= 0) {
          throw const DomainValidationException(
            'invalid_quantity',
            'Assigned quantity must be greater than zero.',
          );
        }
        if (assign.agreedRatePaise < 0) {
          throw const DomainValidationException(
            'invalid_rate',
            'Rate cannot be negative.',
          );
        }
        final skuKey =
            '${assign.designName.trim().toLowerCase()}::${assign.colourName.trim().toLowerCase()}';
        final sku = createdSkuByKey[skuKey];
        if (sku == null) {
          throw const DomainValidationException(
            'sku_not_found',
            'Assigned design & colour variant was not found in this lot.',
          );
        }
        if (assign.quantity > sku.available) {
          throw const DomainValidationException(
            'insufficient_good_stock',
            'Initial assignment quantity exceeds available colour quantity.',
          );
        }

        final worker = await _db.processMemberDao.findMemberById(
          assign.workerId,
        );
        if (worker == null ||
            worker.deletedAt != null ||
            worker.isActive != 1) {
          throw const DomainValidationException(
            'worker_inactive',
            'Selected worker is inactive or unavailable.',
          );
        }
        final proc = await _db.processMemberDao.findProcessById(
          assign.processId,
        );
        if (proc == null || proc.deletedAt != null || proc.isActive != 1) {
          throw const DomainValidationException(
            'process_inactive',
            'Selected process is inactive or unavailable.',
          );
        }

        final link = await _db.processMemberDao.findMemberProcessLink(
          worker.id,
          proc.id,
        );
        if (link == null) {
          await _db.processMemberDao.insertMemberProcess(
            MemberProcessesCompanion.insert(
              id: _idGenerator.nextEntityId(),
              memberId: worker.id,
              processId: proc.id,
              isActive: const Value(1),
              createdAt: now,
              updatedAt: now,
            ),
          );
        } else if (link.isActive == 0) {
          await _db.processMemberDao.updateMemberProcessById(
            link.id,
            MemberProcessesCompanion(
              isActive: const Value(1),
              updatedAt: Value(now),
            ),
          );
        }

        final jpId = _idGenerator.nextEntityId();
        final movId = _idGenerator.nextEntityId();
        final cleanedNotes = LotMediaAndVariantDelegate.nullIfBlank(
          assign.notes,
        );
        final cleanedOverride = LotMediaAndVariantDelegate.nullIfBlank(
          assign.rateOverrideReason,
        );
        final pricingUnit = assign.pricingUnit.trim().isEmpty
            ? ProcessPricingCalculator.unitPerPiece
            : assign.pricingUnit.trim().toUpperCase();
        final perPieceRatePaise = const ProcessPricingCalculator()
            .effectivePerPieceRatePaise(
              quantity: assign.quantity,
              ratePaise: assign.agreedRatePaise,
              pricingUnit: pricingUnit,
            );

        await _db.stockMovementDao.insertMovement(
          StockMovementsCompanion(
            id: Value(movId),
            lotId: Value(lotId),
            lotDesignId: Value(sku.designId),
            designColourId: Value(sku.colourId),
            processId: Value(proc.id),
            memberId: Value(worker.id),
            jobProcessId: Value(jpId),
            movementType: Value(StockMovementType.issue.dbValue),
            quantity: Value(assign.quantity),
            appliedRatePaise: Value(perPieceRatePaise),
            isRateOverridden: Value(cleanedOverride != null ? 1 : 0),
            overrideReason: Value(cleanedOverride),
            lockedBillingMode: Value(BillingMode.receivedQty.dbValue),
            lockedIncludeDamaged: const Value(0),
            notes: Value(cleanedNotes),
            transactionAt: Value(transactionAtUtcMillis),
            recordedAt: Value(now),
            createdBy: Value(actor),
            updatedBy: Value(actor),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await _db.labourEntryDao.insertEntry(
          LabourEntriesCompanion(
            id: Value(_idGenerator.nextEntityId()),
            stockMovementId: Value(movId),
            memberId: Value(worker.id),
            processId: Value(proc.id),
            lotId: Value(lotId),
            basisType: const Value('ISSUED'),
            quantity: Value(assign.quantity),
            ratePaise: Value(perPieceRatePaise),
            amountPaise: Value(assign.quantity * perPieceRatePaise),
            isPayable: const Value(0),
            transactionAt: Value(transactionAtUtcMillis),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await _db.jobProcessDao.insertJobProcess(
          JobProcessesCompanion.insert(
            id: jpId,
            lotId: lotId,
            lotDesignId: sku.designId,
            designColourId: sku.colourId,
            processId: proc.id,
            memberId: Value(worker.id),
            sequenceOrder: Value(seqOrder++),
            plannedQuantity: assign.quantity,
            dispatchedQuantity: Value(assign.quantity),
            receivedQuantity: const Value(0),
            status: Value(JobProcessStatus.dispatched.dbValue),
            linkedIssueMovementId: Value(movId),
            defaultRatePaise: Value(proc.defaultRatePaise),
            agreedRatePaise: Value(assign.agreedRatePaise),
            pricingUnit: Value(pricingUnit),
            rateOverrideReason: Value(cleanedOverride),
            payableAmountPaise: const Value(0),
            paidAmountPaise: const Value(0),
            paymentStatus: Value(ProcessPaymentStatus.pending.dbValue),
            notes: Value(cleanedNotes),
            transactionAt: transactionAtUtcMillis,
            createdBy: Value(actor),
            updatedBy: Value(actor),
            createdAt: now,
            updatedAt: now,
          ),
        );

        final handoverId = _idGenerator.nextEntityId();
        await _db.jobProcessDao.insertHandover(
          ProcessHandoversCompanion.insert(
            id: handoverId,
            transferReference: const ProcessRoutingValidator()
                .generateReference(
                  type: ProcessHandoverType.factoryDispatch,
                  transactionAtUtcMillis: transactionAtUtcMillis,
                  uniqueId: handoverId,
                ),
            lotId: lotId,
            lotDesignId: sku.designId,
            designColourId: sku.colourId,
            handoverType: ProcessHandoverType.factoryDispatch.dbValue,
            toJobProcessId: Value(jpId),
            toMemberId: Value(worker.id),
            processId: proc.id,
            quantityDispatched: assign.quantity,
            status: Value(ProcessHandoverStatus.pendingReceipt.dbValue),
            linkedStockMovementId: Value(movId),
            notes: Value(cleanedNotes),
            transactionAt: transactionAtUtcMillis,
            recordedAt: now,
            createdBy: Value(actor),
            createdAt: now,
            updatedAt: now,
          ),
        );
        if (cleanedOverride != null &&
            assign.agreedRatePaise != proc.defaultRatePaise) {
          await _db.jobProcessDao.insertRateHistory(
            ProcessRateHistoriesCompanion.insert(
              id: _idGenerator.nextEntityId(),
              scope: 'JOB_ASSIGNMENT',
              processId: proc.id,
              jobProcessId: Value(jpId),
              memberId: Value(worker.id),
              designColourId: Value(sku.colourId),
              previousRatePaise: proc.defaultRatePaise,
              newRatePaise: assign.agreedRatePaise,
              pricingUnit: pricingUnit,
              reason: cleanedOverride,
              changedBy: Value(actor),
              changedAt: now,
            ),
          );
        }

        createdSkuByKey[skuKey] = (
          designId: sku.designId,
          colourId: sku.colourId,
          available: sku.available - assign.quantity,
        );
      }

      final created = await _db.lotDao.findLotById(lotId);
      return LotMediaAndVariantDelegate.lotToEntity(created!);
    });
  }

  @override
  Future<LotDesignEntity> createDesignWithColours({
    required String lotId,
    required String designName,
    String? notes,
    required List<LotColourDraftInput> colours,
  }) async {
    final cleanName = designName.trim();
    if (cleanName.isEmpty) {
      throw const DomainValidationException(
        'design_name_required',
        'Design name cannot be empty.',
      );
    }
    if (cleanName.length > ValidationLimits.maxShortNameLength ||
        (notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Design name or notes exceed maximum allowed length.',
      );
    }
    final seenColours = <String>{};
    for (final c in colours) {
      LotMediaAndVariantDelegate.validateColourDraft(c);
      if (!seenColours.add(c.colourName.trim().toLowerCase())) {
        throw const DomainValidationException(
          'duplicate_colour_name',
          'Duplicate colour name under the same design.',
        );
      }
    }

    return _txRunner.runInTransaction(() async {
      final parentLot = await _db.lotDao.findLotById(lotId);
      if (parentLot == null || parentLot.deletedAt != null) {
        throw const LocalStorageException('Parent lot not found or archived.');
      }
      final now = IstDateTimeHelper.nowUtcMillis();
      final designId = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.lotDao.insertDesign(
        LotDesignsCompanion(
          id: Value(designId),
          lotId: Value(lotId),
          designName: Value(cleanName),
          notes: Value(LotMediaAndVariantDelegate.nullIfBlank(notes)),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('lot_designs'),
          entityId: Value(designId),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'lot_id': lotId,
              'design_name': cleanName,
              'colours_count': colours.length,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      for (final c in colours) {
        final colourId = _idGenerator.nextEntityId();
        final cleanColour = c.colourName.trim();
        await _db.lotDao.insertDesignColour(
          DesignColoursCompanion(
            id: Value(colourId),
            lotDesignId: Value(designId),
            colourName: Value(cleanColour),
            colourHex: Value(
              LotMediaAndVariantDelegate.nullIfBlank(c.colourHex),
            ),
            initialQuantity: Value(c.initialQuantity),
            unitPricePaise: Value(c.unitPricePaise),
            notes: Value(LotMediaAndVariantDelegate.nullIfBlank(c.notes)),
            createdBy: Value(actor),
            updatedBy: Value(actor),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        await _db.attachmentAuditDao.insertAuditLog(
          AuditLogsCompanion(
            id: Value(_idGenerator.nextEntityId()),
            entityType: const Value('design_colours'),
            entityId: Value(colourId),
            actionType: const Value('CREATE'),
            actor: Value(actor),
            newValueJson: Value(
              jsonEncode({
                'lot_design_id': designId,
                'colour_name': cleanColour,
                'initial_quantity': c.initialQuantity,
                'unit_price_paise': c.unitPricePaise,
              }),
            ),
            transactionAt: Value(now),
            recordedAt: Value(now),
          ),
        );
      }

      final created = await _db.lotDao.findDesignById(designId);
      return LotMediaAndVariantDelegate.designToEntity(created!);
    });
  }

  @override
  Future<List<DesignColourEntity>> createDesignColoursBatch({
    required String lotId,
    String? lotDesignId,
    required List<LotColourDraftInput> colours,
  }) async {
    if (colours.isEmpty) return const [];
    final seenColours = <String>{};
    for (final c in colours) {
      LotMediaAndVariantDelegate.validateColourDraft(c);
      if (!seenColours.add(c.colourName.trim().toLowerCase())) {
        throw const DomainValidationException(
          'duplicate_colour_name',
          'Duplicate colour name in selection.',
        );
      }
    }

    return _txRunner.runInTransaction(() async {
      final parentLot = await _db.lotDao.findLotById(lotId);
      if (parentLot == null || parentLot.deletedAt != null) {
        throw const LocalStorageException('Parent lot not found or archived.');
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveOptional(_db);

      String targetDesignId;
      if (lotDesignId != null) {
        final parentDesign = await _db.lotDao.findDesignById(lotDesignId);
        if (parentDesign == null || parentDesign.deletedAt != null) {
          throw const LocalStorageException('Parent design not found.');
        }
        targetDesignId = lotDesignId;
      } else {
        final existingDesigns = await _db.lotDao.getDesignsForLot(lotId);
        String? sentinelId;
        for (final d in existingDesigns) {
          if (d.designName == kColourOnlyDesignSentinel) {
            sentinelId = d.id;
            break;
          }
        }
        if (sentinelId == null) {
          sentinelId = _idGenerator.nextEntityId();
          await _db.lotDao.insertDesign(
            LotDesignsCompanion(
              id: Value(sentinelId),
              lotId: Value(lotId),
              designName: const Value(kColourOnlyDesignSentinel),
              notes: const Value('Colour-only lot variants'),
              createdBy: Value(actor),
              updatedBy: Value(actor),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
          await _db.attachmentAuditDao.insertAuditLog(
            AuditLogsCompanion(
              id: Value(_idGenerator.nextEntityId()),
              entityType: const Value('lot_designs'),
              entityId: Value(sentinelId),
              actionType: const Value('CREATE'),
              actor: Value(actor),
              newValueJson: Value(
                jsonEncode({
                  'lot_id': lotId,
                  'design_name': kColourOnlyDesignSentinel,
                }),
              ),
              transactionAt: Value(now),
              recordedAt: Value(now),
            ),
          );
        }
        targetDesignId = sentinelId;
      }

      final createdEntities = <DesignColourEntity>[];
      for (final c in colours) {
        final colourId = _idGenerator.nextEntityId();
        final cleanColour = c.colourName.trim();
        await _db.lotDao.insertDesignColour(
          DesignColoursCompanion(
            id: Value(colourId),
            lotDesignId: Value(targetDesignId),
            colourName: Value(cleanColour),
            colourHex: Value(
              LotMediaAndVariantDelegate.nullIfBlank(c.colourHex),
            ),
            initialQuantity: Value(c.initialQuantity),
            unitPricePaise: Value(c.unitPricePaise),
            notes: Value(LotMediaAndVariantDelegate.nullIfBlank(c.notes)),
            createdBy: Value(actor),
            updatedBy: Value(actor),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        await _db.attachmentAuditDao.insertAuditLog(
          AuditLogsCompanion(
            id: Value(_idGenerator.nextEntityId()),
            entityType: const Value('design_colours'),
            entityId: Value(colourId),
            actionType: const Value('CREATE'),
            actor: Value(actor),
            newValueJson: Value(
              jsonEncode({
                'lot_design_id': targetDesignId,
                'colour_name': cleanColour,
                'initial_quantity': c.initialQuantity,
                'unit_price_paise': c.unitPricePaise,
              }),
            ),
            transactionAt: Value(now),
            recordedAt: Value(now),
          ),
        );
        final row = await _db.lotDao.findDesignColourById(colourId);
        createdEntities.add(LotMediaAndVariantDelegate.colourToEntity(row!));
      }
      return createdEntities;
    });
  }

  @override
  Future<LotEntity> updateLot({
    required String lotId,
    required String lotNumber,
    String? title,
    String? notes,
    required LotStatus status,
    required int transactionAtUtcMillis,
  }) async {
    final cleanNumber = lotNumber.trim();
    if (cleanNumber.isEmpty) {
      throw ArgumentError('Lot number cannot be empty.');
    }
    if (cleanNumber.length > ValidationLimits.maxShortNameLength ||
        (title?.trim().length ?? 0) > ValidationLimits.maxPersonNameLength ||
        (notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Entered lot details exceed maximum allowed length.',
      );
    }
    if (!AppValidators.dateValidator(transactionAtUtcMillis).isValid) {
      throw const DomainValidationException(
        'invalid_date',
        'Lot transaction date is invalid.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findLotById(lotId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Lot not found.');
      }

      if (status == LotStatus.completed) {
        final lotMovRows = await _db.stockMovementDao.getMovementsForLot(lotId);
        final lotMovs = lotMovRows.map(LedgerRowMappers.stockMovement).toList();
        const stockCalc = StockCalculator();
        const prodCalc = ProductionHistoryCalculator();
        final reversedIds = stockCalc.reversedMovementIds(lotMovs);
        final retRows = await _db.productionTrackingDao.getReturnsForLot(lotId);
        final inspRows = await _db.productionTrackingDao.getInspectionsForLot(
          lotId,
        );
        final returns = retRows
            .map(ProductionHistoryDatasetLoader.mapReturn)
            .toList();
        final insps = inspRows
            .map(ProductionHistoryDatasetLoader.mapInspection)
            .toList();
        final pendingInspMap = prodCalc.pendingInspectionByIssue(
          returns: returns,
          inspections: insps,
          reversedMovementIds: reversedIds,
        );
        for (final m in lotMovs) {
          if (m.movementType != StockMovementType.issue ||
              reversedIds.contains(m.id)) {
            continue;
          }
          final settledPending = stockCalc.calculateIssueRemainingPending(
            issue: m,
            allMovementsForColour: lotMovs
                .where((x) => x.designColourId == m.designColourId)
                .toList(),
          );
          final pendingInsp = pendingInspMap[m.id] ?? 0;
          if (settledPending > 0 || pendingInsp > 0) {
            throw const DomainValidationException(
              'lot_has_unreconciled_quantities',
              'Cannot mark lot completed while pieces are still with workers or pending QC inspection.',
            );
          }
        }
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.lotDao.updateLotById(
        lotId,
        LotsCompanion(
          lotNumber: Value(cleanNumber),
          title: Value(LotMediaAndVariantDelegate.nullIfBlank(title)),
          notes: Value(LotMediaAndVariantDelegate.nullIfBlank(notes)),
          status: Value(status.dbValue),
          transactionAt: Value(transactionAtUtcMillis),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('lots'),
          entityId: Value(lotId),
          actionType: const Value('UPDATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'lot_number': existing.lotNumber,
              'title': existing.title,
              'status': existing.status,
            }),
          ),
          newValueJson: Value(
            jsonEncode({
              'lot_number': cleanNumber,
              'title': LotMediaAndVariantDelegate.nullIfBlank(title),
              'status': status.dbValue,
            }),
          ),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final updated = await _db.lotDao.findLotById(lotId);
      return LotMediaAndVariantDelegate.lotToEntity(updated!);
    });
  }

  @override
  Future<void> archiveLot(String lotId) async {
    await _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findLotById(lotId);
      if (existing == null || existing.deletedAt != null) return;
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.lotDao.softDeleteLot(lotId, now, actor);
      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('lots'),
          entityId: Value(lotId),
          actionType: const Value('SOFT_DELETE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'lot_number': existing.lotNumber,
              'status': existing.status,
            }),
          ),
          newValueJson: Value(
            jsonEncode({'status': 'ARCHIVED', 'deleted_at': now}),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> unarchiveLot(
    String lotId, {
    LotStatus restoreStatus = LotStatus.active,
  }) async {
    final targetStatus = restoreStatus == LotStatus.archived
        ? LotStatus.active
        : restoreStatus;
    await _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findLotById(lotId);
      if (existing == null || existing.deletedAt == null) return;
      final activeLots = await _db.lotDao.getActiveLots();
      final conflict = activeLots.any(
        (l) =>
            l.id != lotId &&
            l.lotNumber.trim().toLowerCase() ==
                existing.lotNumber.trim().toLowerCase(),
      );
      if (conflict) {
        throw const DomainValidationException(
          'duplicate_lot_number',
          'Another active lot already uses this lot number.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveOptional(_db);
      await _db.lotDao.restoreArchivedLot(
        lotId,
        status: targetStatus.dbValue,
        updatedAtUtcMillis: now,
        actor: actor,
      );
      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('lots'),
          entityId: Value(lotId),
          actionType: const Value('REACTIVATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'lot_number': existing.lotNumber,
              'status': existing.status,
              'deleted_at': existing.deletedAt,
            }),
          ),
          newValueJson: Value(
            jsonEncode({'status': targetStatus.dbValue, 'deleted_at': null}),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<LotDesignEntity> createDesign({
    required String lotId,
    required String designName,
    String? notes,
  }) => _delegate.createDesign(
    lotId: lotId,
    designName: designName,
    notes: notes,
  );

  @override
  Future<LotDesignEntity> updateDesign({
    required String designId,
    required String designName,
    String? notes,
  }) => _delegate.updateDesign(
    designId: designId,
    designName: designName,
    notes: notes,
  );

  @override
  Future<void> deleteDesign(String designId) =>
      _delegate.deleteDesign(designId);

  @override
  Future<DesignColourEntity> addColourDirectlyToLot({
    required String lotId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  }) => _delegate.addColourDirectlyToLot(
    lotId: lotId,
    colourName: colourName,
    colourHex: colourHex,
    initialQuantity: initialQuantity,
    unitPricePaise: unitPricePaise,
    notes: notes,
  );

  @override
  Future<DesignColourEntity> createDesignColour({
    required String lotDesignId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  }) => _delegate.createDesignColour(
    lotDesignId: lotDesignId,
    colourName: colourName,
    colourHex: colourHex,
    initialQuantity: initialQuantity,
    unitPricePaise: unitPricePaise,
    notes: notes,
  );

  @override
  Future<DesignColourEntity> updateDesignColour({
    required String designColourId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  }) => _delegate.updateDesignColour(
    designColourId: designColourId,
    colourName: colourName,
    colourHex: colourHex,
    initialQuantity: initialQuantity,
    unitPricePaise: unitPricePaise,
    notes: notes,
  );

  @override
  Future<void> deleteDesignColour(String designColourId) =>
      _delegate.deleteDesignColour(designColourId);

  @override
  Future<LotAttachmentEntity> addLotPhoto({
    required String lotId,
    required Uint8List bytes,
    required String fileExtension,
    required String mimeType,
    String? caption,
  }) => _delegate.addLotPhoto(
    lotId: lotId,
    bytes: bytes,
    fileExtension: fileExtension,
    mimeType: mimeType,
    caption: caption,
  );

  @override
  Future<void> removeLotPhoto(String attachmentId) =>
      _delegate.removeLotPhoto(attachmentId);

  @override
  Future<Uint8List?> readPhotoBytes(String relativePath) =>
      _delegate.readPhotoBytes(relativePath);

  @override
  Future<List<LotEntity>> getAllActiveLots() async {
    final rows = await _db.lotDao.getActiveLots();
    return rows.map(LotMediaAndVariantDelegate.lotToEntity).toList();
  }

  @override
  Future<List<LotDesignEntity>> getAllActiveDesigns() =>
      _delegate.getAllActiveDesigns();

  @override
  Future<List<DesignColourEntity>> getAllActiveDesignColours() =>
      _delegate.getAllActiveDesignColours();
}
