import 'package:business_manager/core/database/app_database.dart';

/// Resolves the actor string for append-only audit logs and transactions.
abstract final class ActorResolver {
  static Future<String> resolveRequired(
    AppDatabase db, {
    String? explicit,
    String fallback = 'local_owner',
  }) async {
    final trimmed = explicit?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    final profile = await db.businessProfileDao.getProfile();
    final owner = profile?.ownerName?.trim();
    return (owner != null && owner.isNotEmpty) ? owner : fallback;
  }

  static Future<String?> resolveOptional(AppDatabase db) async {
    final profile = await db.businessProfileDao.getProfile();
    return profile?.ownerName;
  }
}
