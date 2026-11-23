import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';

/// Pure Dart read-only summary models for Milestone 4 Initial Quantity overview.
/// Explicitly tracks *Initial Quantity* — NOT post-movement available stock.
final class LotQuantitySummary {
  const LotQuantitySummary({
    required this.lotId,
    required this.lotNumber,
    this.title,
    required this.designCount,
    required this.colourCount,
    required this.totalInitialQuantity,
  });

  final String lotId;
  final String lotNumber;
  final String? title;
  final int designCount;
  final int colourCount;
  final int totalInitialQuantity;
}

final class DesignQuantitySummary {
  const DesignQuantitySummary({
    required this.designId,
    required this.lotId,
    required this.lotNumber,
    required this.designName,
    required this.colourCount,
    required this.totalInitialQuantity,
  });

  final String designId;
  final String lotId;
  final String lotNumber;
  final String designName;
  final int colourCount;
  final int totalInitialQuantity;
}

final class ColourQuantitySummary {
  const ColourQuantitySummary({
    required this.designColourId,
    required this.lotNumber,
    required this.designName,
    required this.colourName,
    required this.initialQuantity,
    required this.unitPricePaise,
  });

  final String designColourId;
  final String lotNumber;
  final String designName;
  final String colourName;
  final int initialQuantity;
  final int unitPricePaise;
}

final class InventoryOverview {
  const InventoryOverview({
    required this.totalActiveLots,
    required this.totalDesigns,
    required this.totalDesignColourCombinations,
    required this.totalInitialQuantity,
    required this.lotSummaries,
    required this.designSummaries,
    required this.colourSummaries,
  });

  final int totalActiveLots;
  final int totalDesigns;
  final int totalDesignColourCombinations;
  final int totalInitialQuantity;
  final List<LotQuantitySummary> lotSummaries;
  final List<DesignQuantitySummary> designSummaries;
  final List<ColourQuantitySummary> colourSummaries;
}

/// Pure deterministic Dart calculator (zero Flutter/Drift/BLoC dependencies).
abstract final class InventoryOverviewCalculator {
  static InventoryOverview calculate({
    required List<LotEntity> activeLots,
    required List<LotDesignEntity> activeDesigns,
    required List<DesignColourEntity> activeColours,
  }) {
    final lotById = {for (final l in activeLots) l.id: l};

    // Only include designs belonging to active (non-archived) lots
    final validDesigns = activeDesigns
        .where((d) => lotById.containsKey(d.lotId))
        .toList();
    final designById = {for (final d in validDesigns) d.id: d};

    // Only include colours belonging to valid designs
    final validColours = activeColours
        .where((c) => designById.containsKey(c.lotDesignId))
        .toList();

    final coloursByDesign = <String, List<DesignColourEntity>>{};
    for (final c in validColours) {
      coloursByDesign.putIfAbsent(c.lotDesignId, () => []).add(c);
    }

    final designsByLot = <String, List<LotDesignEntity>>{};
    for (final d in validDesigns) {
      designsByLot.putIfAbsent(d.lotId, () => []).add(d);
    }

    var totalInitialQty = 0;
    final colourSummaries = <ColourQuantitySummary>[];
    for (final c in validColours) {
      totalInitialQty += c.initialQuantity;
      final design = designById[c.lotDesignId]!;
      final lot = lotById[design.lotId]!;
      colourSummaries.add(
        ColourQuantitySummary(
          designColourId: c.id,
          lotNumber: lot.lotNumber,
          designName: design.designName,
          colourName: c.colourName,
          initialQuantity: c.initialQuantity,
          unitPricePaise: c.unitPricePaise,
        ),
      );
    }

    final designSummaries = validDesigns.map((d) {
      final lot = lotById[d.lotId]!;
      final colours = coloursByDesign[d.id] ?? const [];
      final qty = colours.fold<int>(0, (sum, c) => sum + c.initialQuantity);
      return DesignQuantitySummary(
        designId: d.id,
        lotId: d.lotId,
        lotNumber: lot.lotNumber,
        designName: d.designName,
        colourCount: colours.length,
        totalInitialQuantity: qty,
      );
    }).toList();

    final lotSummaries = activeLots.map((l) {
      final designs = designsByLot[l.id] ?? const [];
      var colourCount = 0;
      var qty = 0;
      for (final d in designs) {
        final colours = coloursByDesign[d.id] ?? const [];
        colourCount += colours.length;
        qty += colours.fold<int>(0, (sum, c) => sum + c.initialQuantity);
      }
      return LotQuantitySummary(
        lotId: l.id,
        lotNumber: l.lotNumber,
        title: l.title,
        designCount: designs.length,
        colourCount: colourCount,
        totalInitialQuantity: qty,
      );
    }).toList();

    return InventoryOverview(
      totalActiveLots: activeLots.length,
      totalDesigns: validDesigns.length,
      totalDesignColourCombinations: validColours.length,
      totalInitialQuantity: totalInitialQty,
      lotSummaries: lotSummaries,
      designSummaries: designSummaries,
      colourSummaries: colourSummaries,
    );
  }
}
