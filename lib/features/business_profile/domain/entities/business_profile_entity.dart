import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_profile_entity.freezed.dart';

enum BillingMode {
  receivedQty('RECEIVED_QTY'),
  givenQty('GIVEN_QTY');

  const BillingMode(this.dbValue);
  final String dbValue;

  static BillingMode fromDbValue(String raw) {
    return BillingMode.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => BillingMode.receivedQty,
    );
  }
}

@freezed
sealed class BusinessProfileEntity with _$BusinessProfileEntity {
  const factory BusinessProfileEntity({
    required String id,
    required String nameEn,
    required String nameGu,
    String? ownerName,
    String? phone,
    String? address,
    String? logoAttachmentId,
    required BillingMode defaultBillingMode,
    required int createdAt,
    required int updatedAt,
  }) = _BusinessProfileEntity;
}
