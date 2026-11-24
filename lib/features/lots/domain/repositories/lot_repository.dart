import 'dart:typed_data';

import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';

/// Immutable draft colour variant input for atomic Lot or Design creation.
final class LotColourDraftInput {
  const LotColourDraftInput({
    required this.colourName,
    this.colourHex,
    required this.initialQuantity,
    required this.unitPricePaise,
    this.notes,
  });

  final String colourName;
  final String? colourHex;
  final int initialQuantity;
  final int unitPricePaise;
  final String? notes;
}

/// Immutable draft design input (with optional initial colours) for atomic Lot
/// creation. Use [kColourOnlyDesignSentinel] for colour-only lots.
final class LotDesignDraftInput {
  const LotDesignDraftInput({
    required this.designName,
    this.notes,
    this.colours = const [],
  });

  final String designName;
  final String? notes;
  final List<LotColourDraftInput> colours;
}

abstract interface class LotRepository {
  Future<List<LotEntity>> getLots({String? searchQuery, LotStatus? status});

  Future<LotDetailAggregate?> getLotDetail(String lotId);

  /// Returns sorted distinct non-sentinel design names across active lots
  /// for searchable design reuse during Lot/Design creation.
  Future<List<String>> getDistinctDesignNames();

  Future<LotEntity> createLot({
    required String lotNumber,
    String? title,
    String? notes,
    required int transactionAtUtcMillis,
  });

  /// Creates a Lot together with zero, one, or multiple Designs and their
  /// Colour variants + prices inside a single atomic database transaction
  /// (zero partial saves on validation or constraint error).
  Future<LotEntity> createLotComplete({
    required String lotNumber,
    String? title,
    String? notes,
    required int transactionAtUtcMillis,
    required List<LotDesignDraftInput> designs,
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

  /// Atomically creates a Design on an existing Lot along with any initial
  /// Colour variants and direct unit prices in one transaction.
  Future<LotDesignEntity> createDesignWithColours({
    required String lotId,
    required String designName,
    String? notes,
    required List<LotColourDraftInput> colours,
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

  /// Atomically adds multiple Colour variants with direct per-colour prices
  /// to either a specific Design ([lotDesignId]) or directly to a Colour-Only
  /// Lot ([lotDesignId] == null) without modifying any other existing variant.
  Future<List<DesignColourEntity>> createDesignColoursBatch({
    required String lotId,
    String? lotDesignId,
    required List<LotColourDraftInput> colours,
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
