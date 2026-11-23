import 'package:freezed_annotation/freezed_annotation.dart';

part 'lot_entities.freezed.dart';

enum LotStatus {
  active('ACTIVE'),
  completed('COMPLETED'),
  archived('ARCHIVED');

  const LotStatus(this.dbValue);
  final String dbValue;

  static LotStatus fromDbValue(String raw) {
    return LotStatus.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => LotStatus.active,
    );
  }
}

@freezed
sealed class LotEntity with _$LotEntity {
  const factory LotEntity({
    required String id,
    required String lotNumber,
    String? title,
    String? notes,
    required LotStatus status,
    required int transactionAt,
    required int recordedAt,
    required int createdAt,
    required int updatedAt,
  }) = _LotEntity;
}

@freezed
sealed class LotDesignEntity with _$LotDesignEntity {
  const factory LotDesignEntity({
    required String id,
    required String lotId,
    required String designName,
    String? notes,
    required int createdAt,
    required int updatedAt,
  }) = _LotDesignEntity;
}

@freezed
sealed class DesignColourEntity with _$DesignColourEntity {
  const factory DesignColourEntity({
    required String id,
    required String lotDesignId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
    required int createdAt,
    required int updatedAt,
  }) = _DesignColourEntity;
}

@freezed
sealed class LotAttachmentEntity with _$LotAttachmentEntity {
  const factory LotAttachmentEntity({
    required String id,
    required String lotId,
    required String relativePath,
    required String mimeType,
    required int fileSizeBytes,
    required String sha256,
    String? caption,
    required int createdAt,
  }) = _LotAttachmentEntity;
}

@freezed
sealed class DesignWithColours with _$DesignWithColours {
  const factory DesignWithColours({
    required LotDesignEntity design,
    required List<DesignColourEntity> colours,
  }) = _DesignWithColours;
}

@freezed
sealed class LotDetailAggregate with _$LotDetailAggregate {
  const factory LotDetailAggregate({
    required LotEntity lot,
    required List<DesignWithColours> designs,
    required List<LotAttachmentEntity> photos,
  }) = _LotDetailAggregate;
}
