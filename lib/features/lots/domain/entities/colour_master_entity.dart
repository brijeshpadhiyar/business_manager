/// Offline-first colour entry stored in `colour_master`.
final class ColourMasterEntity {
  const ColourMasterEntity({
    required this.id,
    required this.name,
    required this.hexCode,
    required this.isCustom,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String hexCode;
  final bool isCustom;
  final int? lastUsedAt;
  final int createdAt;
  final int updatedAt;
}

/// Output item returned by the Visual Multi-Select Colour Picker Sheet.
final class SelectedColourVariantInput {
  const SelectedColourVariantInput({
    required this.colourName,
    required this.hexCode,
    required this.quantity,
    this.unitPricePaise = 0,
  });

  final String colourName;
  final String hexCode;
  final int quantity;
  final int unitPricePaise;
}
