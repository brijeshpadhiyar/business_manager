import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';

abstract interface class BusinessProfileRepository {
  Future<BusinessProfileEntity> getProfile();

  Future<BusinessProfileEntity> updateProfile({
    required String nameEn,
    required String nameGu,
    String? ownerName,
    String? phone,
    String? address,
    required BillingMode defaultBillingMode,
  });
}
