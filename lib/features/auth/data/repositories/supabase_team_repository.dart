import 'dart:math';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/team/domain/entities/team_entities.dart';
import 'package:business_manager/features/team/domain/repositories/team_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Supabase-backed + SQLite-cached implementation of [TeamRepository].
///
/// Lives under `lib/features/auth/data/repositories/` strictly obeying
/// `AGENT_RULES.md` #3 (Supabase cloud layer isolation).
@LazySingleton(as: TeamRepository)
final class SupabaseTeamRepository implements TeamRepository {
  SupabaseTeamRepository(
    this._config,
    this._db,
    this._idGenerator,
    this._logger,
  );

  final AppConfig _config;
  final AppDatabase _db;
  final IdGenerator _idGenerator;
  final AppLogger _logger;

  static const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _rng = Random.secure();

  @override
  bool get isCloudConfigured => _config.isCloudConfigured;

  supa.SupabaseClient get _client => supa.Supabase.instance.client;

  /// Pure deterministic-format helper generating an 8-character code (`XXXX-XXXX`).
  static String generateInviteCode() {
    final chars = List<String>.generate(
      8,
      (_) => _codeAlphabet[_rng.nextInt(_codeAlphabet.length)],
    );
    return '${chars.sublist(0, 4).join()}-${chars.sublist(4, 8).join()}';
  }

  @override
  Future<List<TeamMemberInfo>> loadMembers(String businessId) async {
    if (isCloudConfigured && !isFlutterTestEnv) {
      try {
        final rows = await _client
            .from('business_members')
            .select()
            .eq('business_id', businessId)
            .order('joined_at', ascending: true);

        final parsed = <TeamMemberInfo>[];
        await _db.transaction(() async {
          for (final raw in rows) {
            final map = Map<String, Object?>.from(raw);
            final info = TeamMemberInfo(
              userId: map['user_id']?.toString() ?? '',
              businessId: map['business_id']?.toString() ?? businessId,
              role: BusinessRole.fromDbValue(map['role']?.toString()),
              status: map['status']?.toString() ?? 'ACTIVE',
              displayName: map['display_name']?.toString(),
              email: map['email']?.toString(),
              phone: map['phone']?.toString(),
              updatedAtUtcMillis:
                  (map['updated_at'] as num?)?.toInt() ??
                  IstDateTimeHelper.nowUtcMillis(),
            );
            parsed.add(info);
            await _db.into(_db.cachedTeamMembers).insertOnConflictUpdate(
              CachedTeamMembersCompanion(
                userId: Value(info.userId),
                businessId: Value(info.businessId),
                role: Value(info.role.dbValue),
                status: Value(info.status),
                displayName: Value(info.displayName),
                email: Value(info.email),
                phone: Value(info.phone),
                updatedAt: Value(info.updatedAtUtcMillis),
              ),
            );
          }
        });
        return parsed;
      } catch (e) {
        _logger.warning('Falling back to cached offline team members: $e');
      }
    }

    final cached = await (_db.select(_db.cachedTeamMembers)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
    return cached
        .map(
          (r) => TeamMemberInfo(
            userId: r.userId,
            businessId: r.businessId,
            role: BusinessRole.fromDbValue(r.role),
            status: r.status,
            displayName: r.displayName,
            email: r.email,
            phone: r.phone,
            updatedAtUtcMillis: r.updatedAt,
          ),
        )
        .toList();
  }

  @override
  Future<List<BusinessInviteInfo>> loadInvites(String businessId) async {
    if (!isCloudConfigured || isFlutterTestEnv) return const [];
    final rows = await _client
        .from('business_invites')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map((raw) {
      final m = Map<String, Object?>.from(raw);
      return BusinessInviteInfo(
        id: m['id']?.toString() ?? '',
        businessId: m['business_id']?.toString() ?? businessId,
        code: m['code']?.toString() ?? '',
        role: BusinessRole.fromDbValue(m['role']?.toString()),
        status: m['status']?.toString() ?? 'PENDING',
        expiresAtUtcMillis: (m['expires_at'] as num?)?.toInt() ?? 0,
        createdAtUtcMillis: (m['created_at'] as num?)?.toInt() ?? 0,
        targetPhone: m['target_phone']?.toString(),
        targetEmail: m['target_email']?.toString(),
      );
    }).toList();
  }

  @override
  Future<BusinessInviteInfo> createInvite({
    required String businessId,
    required BusinessRole role,
    String? targetPhone,
    String? targetEmail,
    int validDays = 7,
  }) async {
    if (role == BusinessRole.owner) {
      throw ArgumentError('Cannot create invite with OWNER role.');
    }
    final now = IstDateTimeHelper.nowUtcMillis();
    final expiresAt = now + Duration(days: validDays).inMilliseconds;
    final id = _idGenerator.nextEntityId();
    final code = generateInviteCode();

    if (isCloudConfigured && !isFlutterTestEnv) {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('Sign in required to create cloud team invites.');
      }
      await _client.from('business_invites').insert({
        'id': id,
        'business_id': businessId,
        'code': code,
        'role': role.dbValue,
        'target_phone': targetPhone?.trim().isEmpty == true
            ? null
            : targetPhone?.trim(),
        'target_email': targetEmail?.trim().isEmpty == true
            ? null
            : targetEmail?.trim(),
        'expires_at': expiresAt,
        'created_by': userId,
        'status': 'PENDING',
        'created_at': now,
        'updated_at': now,
      });
    }

    return BusinessInviteInfo(
      id: id,
      businessId: businessId,
      code: code,
      role: role,
      status: 'PENDING',
      expiresAtUtcMillis: expiresAt,
      createdAtUtcMillis: now,
      targetPhone: targetPhone,
      targetEmail: targetEmail,
    );
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    if (!isCloudConfigured || isFlutterTestEnv) return;
    await _client
        .from('business_invites')
        .update({
          'status': 'REVOKED',
          'updated_at': IstDateTimeHelper.nowUtcMillis(),
        })
        .eq('id', inviteId);
  }

  @override
  Future<void> updateMemberRole({
    required String businessId,
    required String userId,
    required BusinessRole role,
  }) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    if (isCloudConfigured && !isFlutterTestEnv) {
      await _client
          .from('business_members')
          .update({'role': role.dbValue, 'updated_at': now})
          .eq('business_id', businessId)
          .eq('user_id', userId);
    }
    await (_db.update(_db.cachedTeamMembers)
          ..where(
            (t) => t.businessId.equals(businessId) & t.userId.equals(userId),
          ))
        .write(
          CachedTeamMembersCompanion(
            role: Value(role.dbValue),
            updatedAt: Value(now),
          ),
        );
  }

  @override
  Future<void> revokeMember({
    required String businessId,
    required String userId,
  }) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    if (isCloudConfigured && !isFlutterTestEnv) {
      await _client
          .from('business_members')
          .update({'status': 'REVOKED', 'updated_at': now})
          .eq('business_id', businessId)
          .eq('user_id', userId);
    }
    await (_db.update(_db.cachedTeamMembers)
          ..where(
            (t) => t.businessId.equals(businessId) & t.userId.equals(userId),
          ))
        .write(
          CachedTeamMembersCompanion(
            status: const Value('REVOKED'),
            updatedAt: Value(now),
          ),
        );
  }

  @override
  Future<RedeemedInviteResult> redeemInviteCode(String code) async {
    if (!isCloudConfigured || isFlutterTestEnv) {
      throw StateError('Cloud sync must be configured to join a team.');
    }
    final dynamic res = await _client.rpc(
      'stitchflow_redeem_invite',
      params: {'p_code': code.trim().toUpperCase()},
    );
    final list = res is List ? res : [res];
    if (list.isEmpty || list.first is! Map) {
      throw StateError('Invalid invite redemption response.');
    }
    final row = Map<String, Object?>.from(list.first as Map);
    final businessId = row['business_id']?.toString() ?? '';
    final role = BusinessRole.fromDbValue(row['role']?.toString());
    final nameEn = row['business_name_en']?.toString();
    final nameGu = row['business_name_gu']?.toString();
    await cacheActiveRole(role, businessName: nameEn);
    return RedeemedInviteResult(
      businessId: businessId,
      role: role,
      businessNameEn: nameEn,
      businessNameGu: nameGu,
    );
  }

  @override
  Future<void> cacheActiveRole(
    BusinessRole role, {
    String? businessName,
  }) async {
    await _db.syncDao.getSessionState();
    await (_db.update(_db.syncSessionStates)..where((t) => t.id.equals(1)))
        .write(
          SyncSessionStatesCompanion(
            activeRole: Value(role.dbValue),
            activeBusinessName: businessName != null
                ? Value(businessName)
                : const Value.absent(),
            updatedAt: Value(IstDateTimeHelper.nowUtcMillis()),
          ),
        );
  }
}
