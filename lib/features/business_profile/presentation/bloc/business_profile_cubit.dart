import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/business_profile/domain/repositories/business_profile_repository.dart';
import 'package:business_manager/features/business_profile/presentation/bloc/business_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
final class BusinessProfileCubit extends Cubit<BusinessProfileState> {
  BusinessProfileCubit(this._repository) : super(const BusinessProfileState());

  final BusinessProfileRepository _repository;

  Future<void> loadProfile() async {
    emit(
      state.copyWith(status: BusinessProfileStatus.loading, errorMessage: null),
    );
    try {
      final profile = await _repository.getProfile();
      emit(
        state.copyWith(status: BusinessProfileStatus.loaded, profile: profile),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BusinessProfileStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> saveProfile({
    required String nameEn,
    required String nameGu,
    String? ownerName,
    String? phone,
    String? address,
    required BillingMode defaultBillingMode,
  }) async {
    if (state.status == BusinessProfileStatus.saving) return;
    emit(
      state.copyWith(status: BusinessProfileStatus.saving, errorMessage: null),
    );
    try {
      final updated = await _repository.updateProfile(
        nameEn: nameEn,
        nameGu: nameGu,
        ownerName: ownerName,
        phone: phone,
        address: address,
        defaultBillingMode: defaultBillingMode,
      );
      emit(
        state.copyWith(status: BusinessProfileStatus.saved, profile: updated),
      );
    } on DomainValidationException catch (e) {
      emit(
        state.copyWith(
          status: BusinessProfileStatus.error,
          errorMessage: e.code,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BusinessProfileStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
