import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_routing_validator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
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
    this._mediaStorage,
  );

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;
  final MediaStorageService _mediaStorage;

  Future<String?> _currentActor() async {
    final profile = await _db.businessProfileDao.getProfile();
    return profile?.ownerName;
  }

  @override
  Future<List<LotEntity>> getLots({
    String? searchQuery,
    LotStatus? status,
  }) async {
    final rows = await _db.lotDao.getActiveLots();
    final q = searchQuery?.trim().toLowerCase() ?? '';
    return rows
        .where((row) {
          if (status != null && row.status != status.dbValue) return false;
          if (q.isEmpty) return true;
          return row.lotNumber.toLowerCase().contains(q) ||
              (row.title?.toLowerCase().contains(q) ?? false) ||
              (row.notes?.toLowerCase().contains(q) ?? false);
        })
        .map(_lotToEntity)
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
          .add(_colourToEntity(c));
    }
    final designsWithColours = designRows
        .map(
          (d) => DesignWithColours(
            design: _designToEntity(d),
            colours: coloursByDesign[d.id] ?? const <DesignColourEntity>[],
          ),
        )
        .toList(growable: false);

    final photoRows = await _db.attachmentAuditDao.getActiveAttachments(
      'LOT',
      lotId,
    );

    return LotDetailAggregate(
      lot: _lotToEntity(lotRow),
      designs: designsWithColours,
      photos: photoRows.map(_attachmentToEntity).toList(),
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
      final actor = await _currentActor();

      await _db.lotDao.insertLot(
        LotsCompanion(
          id: Value(id),
          lotNumber: Value(cleanNumber),
          title: Value(_nullIfBlank(title)),
          notes: Value(_nullIfBlank(notes)),
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
              'title': _nullIfBlank(title),
            }),
          ),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final created = await _db.lotDao.findLotById(id);
      return _lotToEntity(created!);
    });
  }

  void _validateColourDraft(LotColourDraftInput draft) {
    final cleanName = draft.colourName.trim();
    if (cleanName.isEmpty) {
      throw const DomainValidationException(
        'colour_name_required',
        'Colour name cannot be empty.',
      );
    }
    if (draft.initialQuantity <= 0) {
      throw const DomainValidationException(
        'invalid_quantity',
        'Initial quantity must be greater than zero.',
      );
    }
    if (draft.unitPricePaise < 0) {
      throw const DomainValidationException(
        'invalid_amount',
        'Unit price cannot be negative.',
      );
    }
    if (cleanName.length > ValidationLimits.maxShortNameLength ||
        (draft.notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Colour name or notes exceed maximum allowed length.',
      );
    }
    if (draft.initialQuantity > ValidationLimits.maxQuantity) {
      throw const DomainValidationException(
        'quantity_too_large',
        'Initial quantity exceeds maximum allowed limit.',
      );
    }
    if (draft.unitPricePaise > ValidationLimits.maxAmountPaise) {
      throw const DomainValidationException(
        'amount_too_large',
        'Unit price exceeds maximum allowed limit.',
      );
    }
    if (!AppValidators.hexColorValidator(draft.colourHex).isValid) {
      throw const DomainValidationException(
        'invalid_hex_color',
        'Invalid hex colour code.',
      );
    }
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

    // Validate all nested designs & colours up front before opening DB writes.
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
        _validateColourDraft(colour);
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
      final actor = await _currentActor();

      await _db.lotDao.insertLot(
        LotsCompanion(
          id: Value(lotId),
          lotNumber: Value(cleanNumber),
          title: Value(_nullIfBlank(title)),
          notes: Value(_nullIfBlank(notes)),
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
              'title': _nullIfBlank(title),
              'designs_count': designs.length,
            }),
          ),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      // Track created design & colour IDs and remaining in-house quantities for
      // optional Phase 5 Initial Process Assignments in the same transaction.
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
            notes: Value(_nullIfBlank(design.notes)),
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
              colourHex: Value(_nullIfBlank(colour.colourHex)),
              initialQuantity: Value(colour.initialQuantity),
              unitPricePaise: Value(colour.unitPricePaise),
              notes: Value(_nullIfBlank(colour.notes)),
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

      // Optional Phase 5 Initial Process Assignments (multi-process / multi-worker)
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

        // Ensure active worker-process assignment link exists
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
        final cleanedNotes = _nullIfBlank(assign.notes);
        final cleanedOverride = _nullIfBlank(assign.rateOverrideReason);
        final pricingUnit = assign.pricingUnit.trim().isEmpty
            ? ProcessPricingCalculator.unitPerPiece
            : assign.pricingUnit.trim().toUpperCase();
        // Earnings = accepted qty x per-piece rate, so the ISSUE always locks
        // a per-piece rate (PER_DOZEN etc. converted here, never 12x).
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

        // Informational-only labour entry (Rule 1: ISSUE is never payable)
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
            payableAmountPaise: Value(0),
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

        // Same records as a Routing dispatch: handover timeline row and, for
        // an agreed rate that differs from the default, a rate-history row.
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
      return _lotToEntity(created!);
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
      _validateColourDraft(c);
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
      final actor = await _currentActor();

      await _db.lotDao.insertDesign(
        LotDesignsCompanion(
          id: Value(designId),
          lotId: Value(lotId),
          designName: Value(cleanName),
          notes: Value(_nullIfBlank(notes)),
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
            colourHex: Value(_nullIfBlank(c.colourHex)),
            initialQuantity: Value(c.initialQuantity),
            unitPricePaise: Value(c.unitPricePaise),
            notes: Value(_nullIfBlank(c.notes)),
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
      return _designToEntity(created!);
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
      _validateColourDraft(c);
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
      final actor = await _currentActor();

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
            colourHex: Value(_nullIfBlank(c.colourHex)),
            initialQuantity: Value(c.initialQuantity),
            unitPricePaise: Value(c.unitPricePaise),
            notes: Value(_nullIfBlank(c.notes)),
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
        createdEntities.add(_colourToEntity(row!));
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

      // Phase 6 Completion Reconciliation Guard: do not mark lot COMPLETED
      // while any assignment has outstanding or pending-inspection pieces.
      if (status == LotStatus.completed) {
        final lotMovRows = await _db.stockMovementDao.getMovementsForLot(lotId);
        final lotMovs = lotMovRows
            .map(
              (r) => StockMovementEntity(
                id: r.id,
                lotId: r.lotId,
                lotDesignId: r.lotDesignId,
                designColourId: r.designColourId,
                processId: r.processId,
                memberId: r.memberId,
                parentIssueId: r.parentIssueId,
                jobProcessId: r.jobProcessId,
                reversesMovementId: r.reversesMovementId,
                clientRequestId: r.clientRequestId,
                movementType: StockMovementType.fromDbValue(r.movementType),
                quantity: r.quantity,
                sourceRateId: r.sourceRateId,
                appliedRatePaise: r.appliedRatePaise,
                isRateOverridden: r.isRateOverridden == 1,
                overrideReason: r.overrideReason,
                lockedBillingMode: r.lockedBillingMode != null
                    ? BillingMode.fromDbValue(r.lockedBillingMode!)
                    : null,
                lockedIncludeDamaged: r.lockedIncludeDamaged == 1,
                reason: r.reason,
                notes: r.notes,
                transactionAt: r.transactionAt,
                recordedAt: r.recordedAt,
                createdBy: r.createdBy,
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              ),
            )
            .toList();
        const stockCalc = StockCalculator();
        const prodCalc = ProductionHistoryCalculator();
        final reversedIds = stockCalc.reversedMovementIds(lotMovs);
        final retRows = await _db.productionTrackingDao.getReturnsForLot(lotId);
        final inspRows = await _db.productionTrackingDao.getInspectionsForLot(
          lotId,
        );
        final returns = retRows
            .map(
              (r) => ProductionReturnEntity(
                id: r.id,
                parentIssueId: r.parentIssueId,
                lotId: r.lotId,
                lotDesignId: r.lotDesignId,
                designColourId: r.designColourId,
                processId: r.processId,
                memberId: r.memberId,
                returnedQuantity: r.returnedQuantity,
                returnMode: ProductionReturnMode.fromDbValue(r.returnMode),
                transactionAt: r.transactionAt,
                recordedAt: r.recordedAt,
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              ),
            )
            .toList();
        final insps = inspRows
            .map(
              (r) => ProductionInspectionEntity(
                id: r.id,
                inspectionType: ProductionInspectionType.fromDbValue(
                  r.inspectionType,
                ),
                productionReturnId: r.productionReturnId,
                parentIssueId: r.parentIssueId,
                lotId: r.lotId,
                lotDesignId: r.lotDesignId,
                designColourId: r.designColourId,
                processId: r.processId,
                memberId: r.memberId,
                acceptedQuantity: r.acceptedQuantity,
                rejectedQuantity: r.rejectedQuantity,
                lockedRatePaise: r.lockedRatePaise,
                earnedAmountPaise: r.earnedAmountPaise,
                creditWorkerEarnings: r.creditWorkerEarnings == 1,
                authorizedViaPin: r.authorizedViaPin == 1,
                transactionAt: r.transactionAt,
                recordedAt: r.recordedAt,
                createdAt: r.createdAt,
              ),
            )
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
      final actor = await _currentActor();

      await _db.lotDao.updateLotById(
        lotId,
        LotsCompanion(
          lotNumber: Value(cleanNumber),
          title: Value(_nullIfBlank(title)),
          notes: Value(_nullIfBlank(notes)),
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
              'title': _nullIfBlank(title),
              'status': status.dbValue,
            }),
          ),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final updated = await _db.lotDao.findLotById(lotId);
      return _lotToEntity(updated!);
    });
  }

  @override
  Future<void> archiveLot(String lotId) async {
    await _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findLotById(lotId);
      if (existing == null || existing.deletedAt != null) return;
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

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
  Future<LotDesignEntity> createDesign({
    required String lotId,
    required String designName,
    String? notes,
  }) async {
    final cleanName = designName.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Design name cannot be empty.');
    }
    if (cleanName.length > ValidationLimits.maxShortNameLength ||
        (notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Design name or notes exceed maximum allowed length.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final parentLot = await _db.lotDao.findLotById(lotId);
      if (parentLot == null || parentLot.deletedAt != null) {
        throw const LocalStorageException('Parent lot not found or archived.');
      }
      final now = IstDateTimeHelper.nowUtcMillis();
      final id = _idGenerator.nextEntityId();
      final actor = await _currentActor();

      await _db.lotDao.insertDesign(
        LotDesignsCompanion(
          id: Value(id),
          lotId: Value(lotId),
          designName: Value(cleanName),
          notes: Value(_nullIfBlank(notes)),
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
          entityId: Value(id),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({'lot_id': lotId, 'design_name': cleanName}),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final created = await _db.lotDao.findDesignById(id);
      return _designToEntity(created!);
    });
  }

  @override
  Future<LotDesignEntity> updateDesign({
    required String designId,
    required String designName,
    String? notes,
  }) async {
    final cleanName = designName.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Design name cannot be empty.');
    }
    if (cleanName.length > ValidationLimits.maxShortNameLength ||
        (notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Design name or notes exceed maximum allowed length.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findDesignById(designId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Design not found.');
      }
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

      await _db.lotDao.updateDesignById(
        designId,
        LotDesignsCompanion(
          designName: Value(cleanName),
          notes: Value(_nullIfBlank(notes)),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('lot_designs'),
          entityId: Value(designId),
          actionType: const Value('UPDATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({'design_name': existing.designName}),
          ),
          newValueJson: Value(jsonEncode({'design_name': cleanName})),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final updated = await _db.lotDao.findDesignById(designId);
      return _designToEntity(updated!);
    });
  }

  @override
  Future<void> deleteDesign(String designId) async {
    await _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findDesignById(designId);
      if (existing == null || existing.deletedAt != null) return;
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

      await _db.lotDao.softDeleteDesign(designId, now, actor);
      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('lot_designs'),
          entityId: Value(designId),
          actionType: const Value('SOFT_DELETE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({'design_name': existing.designName}),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<DesignColourEntity> addColourDirectlyToLot({
    required String lotId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  }) async {
    final designs = await _db.lotDao.getDesignsForLot(lotId);
    String? sentinelDesignId;
    for (final d in designs) {
      if (d.designName == kColourOnlyDesignSentinel) {
        sentinelDesignId = d.id;
        break;
      }
    }
    if (sentinelDesignId == null) {
      final created = await createDesign(
        lotId: lotId,
        designName: kColourOnlyDesignSentinel,
        notes: 'Colour-only lot variants',
      );
      sentinelDesignId = created.id;
    }
    return createDesignColour(
      lotDesignId: sentinelDesignId,
      colourName: colourName,
      colourHex: colourHex,
      initialQuantity: initialQuantity,
      unitPricePaise: unitPricePaise,
      notes: notes,
    );
  }

  @override
  Future<DesignColourEntity> createDesignColour({
    required String lotDesignId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  }) async {
    final cleanName = colourName.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Colour name cannot be empty.');
    }
    if (initialQuantity <= 0) {
      throw ArgumentError('Initial quantity must be greater than zero.');
    }
    if (unitPricePaise < 0) {
      throw ArgumentError('Unit price cannot be negative.');
    }
    if (cleanName.length > ValidationLimits.maxShortNameLength ||
        (notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Colour name or notes exceed maximum allowed length.',
      );
    }
    if (initialQuantity > ValidationLimits.maxQuantity) {
      throw const DomainValidationException(
        'quantity_too_large',
        'Initial quantity exceeds maximum allowed limit.',
      );
    }
    if (unitPricePaise > ValidationLimits.maxAmountPaise) {
      throw const DomainValidationException(
        'amount_too_large',
        'Unit price exceeds maximum allowed limit.',
      );
    }
    if (!AppValidators.hexColorValidator(colourHex).isValid) {
      throw const DomainValidationException(
        'invalid_hex_color',
        'Invalid hex colour code.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final parentDesign = await _db.lotDao.findDesignById(lotDesignId);
      if (parentDesign == null || parentDesign.deletedAt != null) {
        throw const LocalStorageException('Parent design not found.');
      }
      final now = IstDateTimeHelper.nowUtcMillis();
      final id = _idGenerator.nextEntityId();
      final actor = await _currentActor();

      await _db.lotDao.insertDesignColour(
        DesignColoursCompanion(
          id: Value(id),
          lotDesignId: Value(lotDesignId),
          colourName: Value(cleanName),
          colourHex: Value(_nullIfBlank(colourHex)),
          initialQuantity: Value(initialQuantity),
          unitPricePaise: Value(unitPricePaise),
          notes: Value(_nullIfBlank(notes)),
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
          entityId: Value(id),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'lot_design_id': lotDesignId,
              'colour_name': cleanName,
              'initial_quantity': initialQuantity,
              'unit_price_paise': unitPricePaise,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final created = await _db.lotDao.findDesignColourById(id);
      return _colourToEntity(created!);
    });
  }

  @override
  Future<DesignColourEntity> updateDesignColour({
    required String designColourId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  }) async {
    final cleanName = colourName.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Colour name cannot be empty.');
    }
    if (initialQuantity <= 0) {
      throw ArgumentError('Initial quantity must be greater than zero.');
    }
    if (unitPricePaise < 0) {
      throw ArgumentError('Unit price cannot be negative.');
    }
    if (cleanName.length > ValidationLimits.maxShortNameLength ||
        (notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Colour name or notes exceed maximum allowed length.',
      );
    }
    if (initialQuantity > ValidationLimits.maxQuantity) {
      throw const DomainValidationException(
        'quantity_too_large',
        'Initial quantity exceeds maximum allowed limit.',
      );
    }
    if (unitPricePaise > ValidationLimits.maxAmountPaise) {
      throw const DomainValidationException(
        'amount_too_large',
        'Unit price exceeds maximum allowed limit.',
      );
    }
    if (!AppValidators.hexColorValidator(colourHex).isValid) {
      throw const DomainValidationException(
        'invalid_hex_color',
        'Invalid hex colour code.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findDesignColourById(designColourId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Design colour not found.');
      }

      // Atomic stock integrity guard: never allow reducing initialQuantity below
      // committed/damaged/settled stock (which would produce negative in-house stock).
      if (initialQuantity < existing.initialQuantity) {
        final movementRows = await _db.stockMovementDao
            .getMovementsForDesignColour(designColourId);
        if (movementRows.isNotEmpty) {
          final movements = movementRows.map(_movementRowToEntity).toList();
          final simulated = const StockCalculator()
              .calculateDesignColourBalance(
                designColourId: existing.id,
                lotId: '',
                lotNumber: '',
                lotDesignId: existing.lotDesignId,
                designName: '',
                colourName: existing.colourName,
                unitPricePaise: unitPricePaise,
                initialQuantity: initialQuantity,
                allMovementsForColour: movements,
              );
          if (simulated.physicalAvailableInHouse < 0 ||
              simulated.totalGoodPhysicalStock < 0) {
            throw const DomainValidationException(
              'quantity_below_committed_stock',
              'Initial quantity cannot be reduced below stock already issued, damaged, or settled.',
            );
          }
        }
      }
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

      await _db.lotDao.updateDesignColourById(
        designColourId,
        DesignColoursCompanion(
          colourName: Value(cleanName),
          colourHex: Value(_nullIfBlank(colourHex)),
          initialQuantity: Value(initialQuantity),
          unitPricePaise: Value(unitPricePaise),
          notes: Value(_nullIfBlank(notes)),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('design_colours'),
          entityId: Value(designColourId),
          actionType: const Value('UPDATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'colour_name': existing.colourName,
              'initial_quantity': existing.initialQuantity,
              'unit_price_paise': existing.unitPricePaise,
            }),
          ),
          newValueJson: Value(
            jsonEncode({
              'colour_name': cleanName,
              'initial_quantity': initialQuantity,
              'unit_price_paise': unitPricePaise,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final updated = await _db.lotDao.findDesignColourById(designColourId);
      return _colourToEntity(updated!);
    });
  }

  @override
  Future<void> deleteDesignColour(String designColourId) async {
    await _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findDesignColourById(designColourId);
      if (existing == null || existing.deletedAt != null) return;
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

      await _db.lotDao.softDeleteDesignColour(designColourId, now, actor);
      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('design_colours'),
          entityId: Value(designColourId),
          actionType: const Value('SOFT_DELETE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'colour_name': existing.colourName,
              'initial_quantity': existing.initialQuantity,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<LotAttachmentEntity> addLotPhoto({
    required String lotId,
    required Uint8List bytes,
    required String fileExtension,
    required String mimeType,
    String? caption,
  }) async {
    // 1. Write file to private media storage first
    final saved = await _mediaStorage.saveBytes(
      bytes: bytes,
      category: MediaCategory.lots,
      entityId: lotId,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );

    // 2. Persist attachment metadata + audit atomically; clean up orphaned file on failure
    try {
      return await _txRunner.runInTransaction(() async {
        final parentLot = await _db.lotDao.findLotById(lotId);
        if (parentLot == null || parentLot.deletedAt != null) {
          throw const LocalStorageException(
            'Cannot attach photo: parent lot not found.',
          );
        }

        final now = IstDateTimeHelper.nowUtcMillis();
        final id = _idGenerator.nextEntityId();
        final actor = await _currentActor();

        await _db.attachmentAuditDao.insertAttachment(
          AttachmentsCompanion(
            id: Value(id),
            entityType: const Value('LOT'),
            entityId: Value(lotId),
            relativePath: Value(saved.relativePath),
            mimeType: Value(saved.mimeType),
            fileSizeBytes: Value(saved.fileSizeBytes),
            sha256: Value(saved.sha256Hex),
            caption: Value(_nullIfBlank(caption)),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await _db.attachmentAuditDao.insertAuditLog(
          AuditLogsCompanion(
            id: Value(_idGenerator.nextEntityId()),
            entityType: const Value('attachments'),
            entityId: Value(id),
            actionType: const Value('CREATE'),
            actor: Value(actor),
            newValueJson: Value(
              jsonEncode({
                'entity_type': 'LOT',
                'entity_id': lotId,
                'relative_path': saved.relativePath,
                'sha256': saved.sha256Hex,
              }),
            ),
            transactionAt: Value(now),
            recordedAt: Value(now),
          ),
        );

        return LotAttachmentEntity(
          id: id,
          lotId: lotId,
          relativePath: saved.relativePath,
          mimeType: saved.mimeType,
          fileSizeBytes: saved.fileSizeBytes,
          sha256: saved.sha256Hex,
          caption: _nullIfBlank(caption),
          createdAt: now,
        );
      });
    } catch (_) {
      // Orphan-file cleanup guarantee if DB write fails
      await _mediaStorage.deleteIfExists(saved.relativePath);
      rethrow;
    }
  }

  @override
  Future<void> removeLotPhoto(String attachmentId) async {
    await _txRunner.runInTransaction(() async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();
      await _db.attachmentAuditDao.softDeleteAttachment(attachmentId, now);
      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('attachments'),
          entityId: Value(attachmentId),
          actionType: const Value('SOFT_DELETE'),
          actor: Value(actor),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<Uint8List?> readPhotoBytes(String relativePath) {
    return _mediaStorage.readBytes(relativePath);
  }

  @override
  Future<List<LotEntity>> getAllActiveLots() async {
    final rows = await _db.lotDao.getActiveLots();
    return rows.map(_lotToEntity).toList();
  }

  @override
  Future<List<LotDesignEntity>> getAllActiveDesigns() async {
    final rows = await _db.lotDao.getAllActiveDesigns();
    return rows.map(_designToEntity).toList();
  }

  @override
  Future<List<DesignColourEntity>> getAllActiveDesignColours() async {
    final rows = await _db.lotDao.getAllActiveDesignColours();
    return rows.map(_colourToEntity).toList();
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  LotEntity _lotToEntity(LotRow row) => LotEntity(
    id: row.id,
    lotNumber: row.lotNumber,
    title: row.title,
    notes: row.notes,
    status: LotStatus.fromDbValue(row.status),
    transactionAt: row.transactionAt,
    recordedAt: row.recordedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  LotDesignEntity _designToEntity(LotDesignRow row) => LotDesignEntity(
    id: row.id,
    lotId: row.lotId,
    designName: row.designName,
    notes: row.notes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  DesignColourEntity _colourToEntity(DesignColourRow row) => DesignColourEntity(
    id: row.id,
    lotDesignId: row.lotDesignId,
    colourName: row.colourName,
    colourHex: row.colourHex,
    initialQuantity: row.initialQuantity,
    unitPricePaise: row.unitPricePaise,
    notes: row.notes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  LotAttachmentEntity _attachmentToEntity(AttachmentRow row) =>
      LotAttachmentEntity(
        id: row.id,
        lotId: row.entityId,
        relativePath: row.relativePath,
        mimeType: row.mimeType,
        fileSizeBytes: row.fileSizeBytes,
        sha256: row.sha256,
        caption: row.caption,
        createdAt: row.createdAt,
      );

  StockMovementEntity _movementRowToEntity(StockMovementRow row) =>
      StockMovementEntity(
        id: row.id,
        lotId: row.lotId,
        lotDesignId: row.lotDesignId,
        designColourId: row.designColourId,
        processId: row.processId,
        memberId: row.memberId,
        parentIssueId: row.parentIssueId,
        reversesMovementId: row.reversesMovementId,
        clientRequestId: row.clientRequestId,
        movementType: StockMovementType.fromDbValue(row.movementType),
        quantity: row.quantity,
        sourceRateId: row.sourceRateId,
        appliedRatePaise: row.appliedRatePaise,
        isRateOverridden: row.isRateOverridden == 1,
        overrideReason: row.overrideReason,
        lockedBillingMode: row.lockedBillingMode != null
            ? BillingMode.fromDbValue(row.lockedBillingMode!)
            : null,
        lockedIncludeDamaged: row.lockedIncludeDamaged == 1,
        reason: row.reason,
        notes: row.notes,
        transactionAt: row.transactionAt,
        recordedAt: row.recordedAt,
        createdBy: row.createdBy,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
