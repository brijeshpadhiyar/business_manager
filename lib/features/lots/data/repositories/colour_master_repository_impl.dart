import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/app_colour_swatch.dart';
import 'package:business_manager/features/lots/domain/entities/colour_master_entity.dart';
import 'package:business_manager/features/lots/domain/repositories/colour_master_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ColourMasterRepository)
final class ColourMasterRepositoryImpl implements ColourMasterRepository {
  ColourMasterRepositoryImpl(this._db, this._txRunner, this._idGenerator);

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;

  ColourMasterEntity _map(ColourMasterRow r) => ColourMasterEntity(
    id: r.id,
    name: r.name,
    hexCode: r.hexCode,
    isCustom: r.isCustom == 1,
    lastUsedAt: r.lastUsedAt,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  @override
  Future<List<ColourMasterEntity>> getAllColours({String? searchQuery}) async {
    final rows = await _db.colourMasterDao.getAllActiveColours();
    final q = searchQuery?.trim().toLowerCase() ?? '';
    return rows
        .where(
          (r) =>
              q.isEmpty ||
              r.name.toLowerCase().contains(q) ||
              r.hexCode.toLowerCase().contains(q),
        )
        .map(_map)
        .toList();
  }

  @override
  Future<List<ColourMasterEntity>> getRecentColours({int limit = 8}) async {
    final rows = await _db.colourMasterDao.getRecentColours(limit: limit);
    return rows.map(_map).toList();
  }

  @override
  Future<ColourMasterEntity> createCustomColour({
    required String name,
    required String hexCode,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const DomainValidationException(
        'colour_name_required',
        'Colour name cannot be empty.',
      );
    }
    final normalizedHex = AppColourUtils.normalizeHex(hexCode);
    if (normalizedHex == null) {
      throw const DomainValidationException(
        'invalid_hex_color',
        'Enter a valid 6-digit HEX code (e.g. #DC2626).',
      );
    }

    final existing = await _db.colourMasterDao.findActiveByLowerName(
      cleanName.toLowerCase(),
    );
    if (existing != null) {
      throw const DomainValidationException(
        'duplicate_colour',
        'A colour with this name already exists.',
      );
    }

    final now = IstDateTimeHelper.nowUtcMillis();
    final id = _idGenerator.nextEntityId();

    await _txRunner.runInTransaction(() async {
      await _db.colourMasterDao.insertColour(
        ColourMastersCompanion.insert(
          id: id,
          name: cleanName,
          hexCode: normalizedHex,
          isCustom: const Value(1),
          lastUsedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    final created = await _db.colourMasterDao.findById(id);
    return _map(created!);
  }

  @override
  Future<ColourMasterEntity> updateColour({
    required String id,
    required String name,
    required String hexCode,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const DomainValidationException(
        'colour_name_required',
        'Colour name cannot be empty.',
      );
    }
    final normalizedHex = AppColourUtils.normalizeHex(hexCode);
    if (normalizedHex == null) {
      throw const DomainValidationException(
        'invalid_hex_color',
        'Enter a valid 6-digit HEX code (e.g. #DC2626).',
      );
    }

    final existing = await _db.colourMasterDao.findById(id);
    if (existing == null || existing.deletedAt != null) {
      throw const DomainValidationException(
        'colour_not_found',
        'Colour record not found.',
      );
    }

    final duplicate = await _db.colourMasterDao.findActiveByLowerName(
      cleanName.toLowerCase(),
    );
    if (duplicate != null && duplicate.id != id) {
      throw const DomainValidationException(
        'duplicate_colour',
        'Another colour already uses this name.',
      );
    }

    final now = IstDateTimeHelper.nowUtcMillis();
    await _db.colourMasterDao.updateColourById(
      id,
      ColourMastersCompanion(
        name: Value(cleanName),
        hexCode: Value(normalizedHex),
        updatedAt: Value(now),
      ),
    );
    final updated = await _db.colourMasterDao.findById(id);
    return _map(updated!);
  }

  @override
  Future<void> markColoursUsed(List<String> colourNames) async {
    if (colourNames.isEmpty) return;
    final now = IstDateTimeHelper.nowUtcMillis();
    await _txRunner.runInTransaction(() async {
      for (final raw in colourNames) {
        final match = await _db.colourMasterDao.findActiveByLowerName(
          raw.trim().toLowerCase(),
        );
        if (match != null) {
          await _db.colourMasterDao.updateColourById(
            match.id,
            ColourMastersCompanion(
              lastUsedAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });
  }
}
