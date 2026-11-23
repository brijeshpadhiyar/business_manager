import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/business_profile/domain/repositories/business_profile_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: BusinessProfileRepository)
final class BusinessProfileRepositoryImpl implements BusinessProfileRepository {
  BusinessProfileRepositoryImpl(this._db, this._txRunner, this._idGenerator);

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;

  @override
  Future<BusinessProfileEntity> getProfile() async {
    final row = await _db.businessProfileDao.getProfile();
    if (row == null) {
      throw const LocalStorageException('Default business profile not found.');
    }
    return _toEntity(row);
  }

  @override
  Future<BusinessProfileEntity> updateProfile({
    required String nameEn,
    required String nameGu,
    String? ownerName,
    String? phone,
    String? address,
    required BillingMode defaultBillingMode,
  }) async {
    final trimmedEn = nameEn.trim();
    final trimmedGu = nameGu.trim();
    if (trimmedEn.isEmpty) {
      throw ArgumentError('Business English name cannot be empty.');
    }
    if (trimmedGu.isEmpty) {
      throw ArgumentError('Business Gujarati name cannot be empty.');
    }
    if (trimmedEn.length > ValidationLimits.maxPersonNameLength ||
        trimmedGu.length > ValidationLimits.maxPersonNameLength ||
        (ownerName?.trim().length ?? 0) > ValidationLimits.maxPersonNameLength ||
        (address?.trim().length ?? 0) > ValidationLimits.maxAddressLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Entered text exceeds maximum allowed length.',
      );
    }
    final phoneRes = AppValidators.mobileNumberValidator(phone);
    if (!phoneRes.isValid) {
      final code = switch (phoneRes.code) {
        ValidationErrorCode.mobileInvalidChars => 'mobile_invalid_chars',
        ValidationErrorCode.mobileInvalidInternational =>
          'mobile_invalid_international',
        _ => 'mobile_invalid_indian',
      };
      throw DomainValidationException(code, 'Invalid mobile number.');
    }

    return _txRunner.runInTransaction(() async {
      final existing = await _db.businessProfileDao.getProfile();
      if (existing == null) {
        throw const LocalStorageException(
          'Default business profile not found.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final cleanOwner = _nullIfBlank(ownerName);
      final cleanPhone = _nullIfBlank(phone);
      final cleanAddress = _nullIfBlank(address);

      await _db.businessProfileDao.upsertProfile(
        BusinessProfilesCompanion(
          id: const Value('default'),
          nameEn: Value(trimmedEn),
          nameGu: Value(trimmedGu),
          ownerName: Value(cleanOwner),
          phone: Value(cleanPhone),
          address: Value(cleanAddress),
          logoAttachmentId: Value(existing.logoAttachmentId),
          defaultBillingMode: Value(defaultBillingMode.dbValue),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('business_profile'),
          entityId: const Value('default'),
          actionType: const Value('UPDATE'),
          actor: Value(cleanOwner ?? existing.ownerName),
          previousValueJson: Value(
            jsonEncode({
              'name_en': existing.nameEn,
              'name_gu': existing.nameGu,
              'owner_name': existing.ownerName,
              'phone': existing.phone,
              'address': existing.address,
              'default_billing_mode': existing.defaultBillingMode,
            }),
          ),
          newValueJson: Value(
            jsonEncode({
              'name_en': trimmedEn,
              'name_gu': trimmedGu,
              'owner_name': cleanOwner,
              'phone': cleanPhone,
              'address': cleanAddress,
              'default_billing_mode': defaultBillingMode.dbValue,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final updated = await _db.businessProfileDao.getProfile();
      return _toEntity(updated!);
    });
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  BusinessProfileEntity _toEntity(BusinessProfileRow row) {
    return BusinessProfileEntity(
      id: row.id,
      nameEn: row.nameEn,
      nameGu: row.nameGu,
      ownerName: row.ownerName,
      phone: row.phone,
      address: row.address,
      logoAttachmentId: row.logoAttachmentId,
      defaultBillingMode: BillingMode.fromDbValue(row.defaultBillingMode),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
