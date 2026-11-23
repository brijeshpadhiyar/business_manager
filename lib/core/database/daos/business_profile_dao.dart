import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/business_profile_table.dart';
import 'package:drift/drift.dart';

part 'business_profile_dao.g.dart';

@DriftAccessor(tables: [BusinessProfiles])
class BusinessProfileDao extends DatabaseAccessor<AppDatabase>
    with _$BusinessProfileDaoMixin {
  BusinessProfileDao(super.db);

  Future<BusinessProfileRow?> getProfile() {
    return (select(
      businessProfiles,
    )..where((t) => t.id.equals('default'))).getSingleOrNull();
  }

  Stream<BusinessProfileRow?> watchProfile() {
    return (select(
      businessProfiles,
    )..where((t) => t.id.equals('default'))).watchSingleOrNull();
  }

  Future<void> upsertProfile(BusinessProfilesCompanion entry) {
    return into(businessProfiles).insertOnConflictUpdate(entry);
  }
}
