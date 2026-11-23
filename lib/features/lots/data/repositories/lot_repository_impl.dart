import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
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
    final designsWithColours = <DesignWithColours>[];
    for (final d in designRows) {
      final colourRows = await _db.lotDao.getColoursForDesign(d.id);
      designsWithColours.add(
        DesignWithColours(
          design: _designToEntity(d),
          colours: colourRows.map(_colourToEntity).toList(),
        ),
      );
    }

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

    return _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findLotById(lotId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Lot not found.');
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

    return _txRunner.runInTransaction(() async {
      final existing = await _db.lotDao.findDesignColourById(designColourId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Design colour not found.');
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
}
