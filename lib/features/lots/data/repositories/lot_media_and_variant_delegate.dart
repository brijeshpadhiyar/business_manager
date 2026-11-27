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
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/parties/data/repositories/party_repository_impl.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:drift/drift.dart';

/// Shared entity mappers plus design, colour variant, and private lot photo
/// operations for [LotRepositoryImpl].
final class LotMediaAndVariantDelegate {
  const LotMediaAndVariantDelegate(
    this._db,
    this._txRunner,
    this._idGenerator,
    this._mediaStorage,
  );

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;
  final MediaStorageService _mediaStorage;

  static String? nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static LotEntity lotToEntity(LotRow row) => LotEntity(
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

  static LotDesignEntity designToEntity(LotDesignRow row) => LotDesignEntity(
    id: row.id,
    lotId: row.lotId,
    designName: row.designName,
    notes: row.notes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  static DesignColourEntity colourToEntity(DesignColourRow row) =>
      DesignColourEntity(
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

  static LotAttachmentEntity attachmentToEntity(AttachmentRow row) =>
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

  static void validateColourDraft(LotColourDraftInput draft) {
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
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.lotDao.insertDesign(
        LotDesignsCompanion(
          id: Value(id),
          lotId: Value(lotId),
          designName: Value(cleanName),
          notes: Value(nullIfBlank(notes)),
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
      return designToEntity(created!);
    });
  }

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
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.lotDao.updateDesignById(
        designId,
        LotDesignsCompanion(
          designName: Value(cleanName),
          notes: Value(nullIfBlank(notes)),
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
      return designToEntity(updated!);
    });
  }

  Future<void> deleteDesign(String designId) async {
    await _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findDesignById(designId);
      if (existing == null || existing.deletedAt != null) return;
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveOptional(_db);

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
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.lotDao.insertDesignColour(
        DesignColoursCompanion(
          id: Value(id),
          lotDesignId: Value(lotDesignId),
          colourName: Value(cleanName),
          colourHex: Value(nullIfBlank(colourHex)),
          initialQuantity: Value(initialQuantity),
          unitPricePaise: Value(unitPricePaise),
          notes: Value(nullIfBlank(notes)),
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
      return colourToEntity(created!);
    });
  }

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

      if (initialQuantity < existing.initialQuantity) {
        final movementRows = await _db.stockMovementDao
            .getMovementsForDesignColour(designColourId);
        final dispatchDeltas = await PartyRepositoryImpl.loadStockDeltasByColour(
          _db,
        );
        final delta = dispatchDeltas[existing.id];
        if (movementRows.isNotEmpty || (delta != null && delta.netDispatchedQty > 0)) {
          final movements = movementRows
              .map(LedgerRowMappers.stockMovement)
              .toList();
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
                dispatchedOutQty: delta?.dispatchedOutQty ?? 0,
                buyerReturnedGoodQty: delta?.buyerReturnedGoodQty ?? 0,
                buyerReturnedDamagedQty: delta?.buyerReturnedDamagedQty ?? 0,
              );
          if (simulated.physicalAvailableInHouse < 0 ||
              simulated.totalGoodPhysicalStock < 0) {
            throw const DomainValidationException(
              'quantity_below_committed_stock',
              'Initial quantity cannot be reduced below stock already issued, dispatched, damaged, or settled.',
            );
          }
        }
      }
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.lotDao.updateDesignColourById(
        designColourId,
        DesignColoursCompanion(
          colourName: Value(cleanName),
          colourHex: Value(nullIfBlank(colourHex)),
          initialQuantity: Value(initialQuantity),
          unitPricePaise: Value(unitPricePaise),
          notes: Value(nullIfBlank(notes)),
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
      return colourToEntity(updated!);
    });
  }

  Future<void> deleteDesignColour(String designColourId) async {
    await _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findDesignColourById(designColourId);
      if (existing == null || existing.deletedAt != null) return;
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveOptional(_db);

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

  Future<LotAttachmentEntity> addLotPhoto({
    required String lotId,
    required Uint8List bytes,
    required String fileExtension,
    required String mimeType,
    String? caption,
  }) async {
    final saved = await _mediaStorage.saveBytes(
      bytes: bytes,
      category: MediaCategory.lots,
      entityId: lotId,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );

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
        final actor = await ActorResolver.resolveOptional(_db);

        await _db.attachmentAuditDao.insertAttachment(
          AttachmentsCompanion(
            id: Value(id),
            entityType: const Value('LOT'),
            entityId: Value(lotId),
            relativePath: Value(saved.relativePath),
            mimeType: Value(saved.mimeType),
            fileSizeBytes: Value(saved.fileSizeBytes),
            sha256: Value(saved.sha256Hex),
            caption: Value(nullIfBlank(caption)),
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
          caption: nullIfBlank(caption),
          createdAt: now,
        );
      });
    } catch (_) {
      await _mediaStorage.deleteIfExists(saved.relativePath);
      rethrow;
    }
  }

  Future<void> removeLotPhoto(String attachmentId) async {
    await _txRunner.runInTransaction(() async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveOptional(_db);
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

  Future<Uint8List?> readPhotoBytes(String relativePath) =>
      _mediaStorage.readBytes(relativePath);

  Future<List<LotDesignEntity>> getAllActiveDesigns() async {
    final rows = await _db.lotDao.getAllActiveDesigns();
    return rows.map(designToEntity).toList();
  }

  Future<List<DesignColourEntity>> getAllActiveDesignColours() async {
    final rows = await _db.lotDao.getAllActiveDesignColours();
    return rows.map(colourToEntity).toList();
  }
}
