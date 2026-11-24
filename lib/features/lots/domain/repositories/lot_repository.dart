import 'dart:typed_data';

import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';

abstract interface class LotRepository {
  Future<List<LotEntity>> getLots({String? searchQuery, LotStatus? status});

  Future<LotDetailAggregate?> getLotDetail(String lotId);

  Future<LotEntity> createLot({
    required String lotNumber,
    String? title,
    String? notes,
    required int transactionAtUtcMillis,
  });

  Future<LotEntity> updateLot({
    required String lotId,
    required String lotNumber,
    String? title,
    String? notes,
    required LotStatus status,
    required int transactionAtUtcMillis,
  });

  Future<void> archiveLot(String lotId);

  Future<LotDesignEntity> createDesign({
    required String lotId,
    required String designName,
    String? notes,
  });

  Future<LotDesignEntity> updateDesign({
    required String designId,
    required String designName,
    String? notes,
  });

  Future<void> deleteDesign(String designId);

  Future<DesignColourEntity> createDesignColour({
    required String lotDesignId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  });

  /// Adds a colour variant directly to a Colour-Only Lot without requiring the
  /// user to create a Design first (automatically manages the implicit group).
  Future<DesignColourEntity> addColourDirectlyToLot({
    required String lotId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  });

  Future<DesignColourEntity> updateDesignColour({
    required String designColourId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  });

  Future<void> deleteDesignColour(String designColourId);

  /// Saves image bytes into private storage, inserts an `attachments` record
  /// + audit log atomically, and cleans up the saved file if DB insertion fails.
  Future<LotAttachmentEntity> addLotPhoto({
    required String lotId,
    required Uint8List bytes,
    required String fileExtension,
    required String mimeType,
    String? caption,
  });

  Future<void> removeLotPhoto(String attachmentId);

  Future<Uint8List?> readPhotoBytes(String relativePath);

  /// Raw active rows for read-only Inventory Overview calculation.
  Future<List<LotEntity>> getAllActiveLots();
  Future<List<LotDesignEntity>> getAllActiveDesigns();
  Future<List<DesignColourEntity>> getAllActiveDesignColours();
}
