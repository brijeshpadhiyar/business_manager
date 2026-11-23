import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_profile_state.freezed.dart';

enum BusinessProfileStatus { initial, loading, loaded, saving, saved, error }

@freezed
sealed class BusinessProfileState with _$BusinessProfileState {
  const factory BusinessProfileState({
    @Default(BusinessProfileStatus.initial) BusinessProfileStatus status,
    BusinessProfileEntity? profile,
    String? errorMessage,
  }) = _BusinessProfileState;
}
