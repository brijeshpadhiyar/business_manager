import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/lots/domain/entities/colour_master_entity.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/colour_master_repository.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cross-lot design summary aggregated from existing `lots`, `lot_designs`, and
/// `design_colours` tables without duplicating business data.
final class DesignCatalogItem {
  const DesignCatalogItem({
    required this.designName,
    required this.lotCount,
    required this.colourVariantCount,
    required this.totalInitialQuantity,
    required this.minUnitPricePaise,
    required this.maxUnitPricePaise,
    required this.latestLotId,
    required this.latestLotNumber,
    required this.latestTransactionAt,
    required this.colourNames,
    required this.lotRefs,
  });

  final String designName;
  final int lotCount;
  final int colourVariantCount;
  final int totalInitialQuantity;
  final int minUnitPricePaise;
  final int maxUnitPricePaise;
  final String latestLotId;
  final String latestLotNumber;
  final int latestTransactionAt;
  final List<String> colourNames;
  final List<DesignLotLink> lotRefs;
}

final class DesignLotLink {
  const DesignLotLink({
    required this.lotId,
    required this.lotNumber,
    required this.colourName,
    this.colourHex,
    required this.initialQuantity,
    required this.unitPricePaise,
    required this.transactionAt,
  });

  final String lotId;
  final String lotNumber;
  final String colourName;
  final String? colourHex;
  final int initialQuantity;
  final int unitPricePaise;
  final int transactionAt;
}

/// Colour Master entry enriched with historical usage & price range across lots.
final class ColourCatalogItem {
  const ColourCatalogItem({
    required this.master,
    required this.usageCount,
    required this.totalQuantity,
    required this.minUnitPricePaise,
    required this.maxUnitPricePaise,
    required this.relatedDesigns,
  });

  final ColourMasterEntity master;
  final int usageCount;
  final int totalQuantity;
  final int minUnitPricePaise;
  final int maxUnitPricePaise;
  final List<String> relatedDesigns;
}

enum DesignsColoursStatus { initial, loading, loaded, error }

final class DesignsColoursState {
  const DesignsColoursState({
    this.status = DesignsColoursStatus.initial,
    this.searchQuery = '',
    this.designs = const [],
    this.colours = const [],
    this.errorMessage,
  });

  final DesignsColoursStatus status;
  final String searchQuery;
  final List<DesignCatalogItem> designs;
  final List<ColourCatalogItem> colours;
  final String? errorMessage;

  DesignsColoursState copyWith({
    DesignsColoursStatus? status,
    String? searchQuery,
    List<DesignCatalogItem>? designs,
    List<ColourCatalogItem>? colours,
    String? errorMessage,
  }) {
    return DesignsColoursState(
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
      designs: designs ?? this.designs,
      colours: colours ?? this.colours,
      errorMessage: errorMessage,
    );
  }
}

final class DesignsColoursCubit extends Cubit<DesignsColoursState> {
  DesignsColoursCubit(this._lotRepository, this._colourRepository)
    : super(const DesignsColoursState());

  final LotRepository _lotRepository;
  final ColourMasterRepository _colourRepository;

  Future<void> load({String? searchQuery}) async {
    final query = (searchQuery ?? state.searchQuery).trim();
    emit(
      state.copyWith(
        status: DesignsColoursStatus.loading,
        searchQuery: query,
      ),
    );

    try {
      final results = await Future.wait([
        _lotRepository.getAllActiveLots(),
        _lotRepository.getAllActiveDesigns(),
        _lotRepository.getAllActiveDesignColours(),
        _colourRepository.getAllColours(),
      ]);

      final lots = results[0] as List<LotEntity>;
      final lotDesigns = results[1] as List<LotDesignEntity>;
      final designColours = results[2] as List<DesignColourEntity>;
      final colourMasters = results[3] as List<ColourMasterEntity>;

      final lotById = {for (final l in lots) l.id: l};
      final designById = {for (final d in lotDesigns) d.id: d};

      // Group designs by normalized design name (skipping colour-only sentinel).
      final designGroups = <String, List<LotDesignEntity>>{};
      for (final d in lotDesigns) {
        if (d.designName == kColourOnlyDesignSentinel) continue;
        final key = d.designName.trim().toLowerCase();
        designGroups.putIfAbsent(key, () => []).add(d);
      }

      final coloursByDesignId = <String, List<DesignColourEntity>>{};
      final usagesByColourKey = <String, List<DesignColourEntity>>{};
      for (final c in designColours) {
        coloursByDesignId.putIfAbsent(c.lotDesignId, () => []).add(c);
        usagesByColourKey
            .putIfAbsent(c.colourName.trim().toLowerCase(), () => [])
            .add(c);
      }

      final qLower = query.toLowerCase();
      final designItems = <DesignCatalogItem>[];
      for (final entry in designGroups.entries) {
        final group = entry.value;
        final displayName = group.first.designName;
        final uniqueLotIds = <String>{};
        final uniqueColours = <String>{};
        final lotRefs = <DesignLotLink>[];
        var totalQty = 0;
        var minPrice = 0;
        var maxPrice = 0;
        LotEntity? latestLot;

        for (final d in group) {
          final lot = lotById[d.lotId];
          if (lot == null) continue;
          uniqueLotIds.add(lot.id);
          if (latestLot == null || lot.transactionAt > latestLot.transactionAt) {
            latestLot = lot;
          }
          for (final c in coloursByDesignId[d.id] ?? const <DesignColourEntity>[]) {
            uniqueColours.add(c.colourName);
            totalQty += c.initialQuantity;
            if (c.unitPricePaise > 0) {
              minPrice = minPrice == 0
                  ? c.unitPricePaise
                  : (c.unitPricePaise < minPrice ? c.unitPricePaise : minPrice);
              if (c.unitPricePaise > maxPrice) maxPrice = c.unitPricePaise;
            }
            lotRefs.add(
              DesignLotLink(
                lotId: lot.id,
                lotNumber: lot.lotNumber,
                colourName: c.colourName,
                colourHex: c.colourHex,
                initialQuantity: c.initialQuantity,
                unitPricePaise: c.unitPricePaise,
                transactionAt: lot.transactionAt,
              ),
            );
          }
        }
        if (latestLot == null) continue;

        final matches = qLower.isEmpty ||
            displayName.toLowerCase().contains(qLower) ||
            uniqueColours.any((c) => c.toLowerCase().contains(qLower)) ||
            lotRefs.any((r) => r.lotNumber.toLowerCase().contains(qLower));
        if (!matches) continue;

        lotRefs.sort((a, b) => b.transactionAt.compareTo(a.transactionAt));
        designItems.add(
          DesignCatalogItem(
            designName: displayName,
            lotCount: uniqueLotIds.length,
            colourVariantCount: lotRefs.length,
            totalInitialQuantity: totalQty,
            minUnitPricePaise: minPrice,
            maxUnitPricePaise: maxPrice,
            latestLotId: latestLot.id,
            latestLotNumber: latestLot.lotNumber,
            latestTransactionAt: latestLot.transactionAt,
            colourNames: uniqueColours.toList()..sort(),
            lotRefs: lotRefs,
          ),
        );
      }
      designItems.sort(
        (a, b) => b.latestTransactionAt.compareTo(a.latestTransactionAt),
      );

      final colourItems = <ColourCatalogItem>[];
      for (final m in colourMasters) {
        final key = m.name.trim().toLowerCase();
        final usages = usagesByColourKey[key] ?? const <DesignColourEntity>[];
        var totalQty = 0;
        var minPrice = 0;
        var maxPrice = 0;
        final relatedDesigns = <String>{};
        for (final u in usages) {
          totalQty += u.initialQuantity;
          if (u.unitPricePaise > 0) {
            minPrice = minPrice == 0
                ? u.unitPricePaise
                : (u.unitPricePaise < minPrice ? u.unitPricePaise : minPrice);
            if (u.unitPricePaise > maxPrice) maxPrice = u.unitPricePaise;
          }
          final d = designById[u.lotDesignId];
          if (d != null && d.designName != kColourOnlyDesignSentinel) {
            relatedDesigns.add(d.designName);
          }
        }
        final matches = qLower.isEmpty ||
            m.name.toLowerCase().contains(qLower) ||
            m.hexCode.toLowerCase().contains(qLower) ||
            relatedDesigns.any((d) => d.toLowerCase().contains(qLower));
        if (!matches) continue;

        colourItems.add(
          ColourCatalogItem(
            master: m,
            usageCount: usages.length,
            totalQuantity: totalQty,
            minUnitPricePaise: minPrice,
            maxUnitPricePaise: maxPrice,
            relatedDesigns: relatedDesigns.toList()..sort(),
          ),
        );
      }

      emit(
        state.copyWith(
          status: DesignsColoursStatus.loaded,
          designs: designItems,
          colours: colourItems,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DesignsColoursStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> saveColour({
    String? id,
    required String name,
    required String hexCode,
  }) async {
    if (id == null) {
      await _colourRepository.createCustomColour(name: name, hexCode: hexCode);
    } else {
      await _colourRepository.updateColour(
        id: id,
        name: name,
        hexCode: hexCode,
      );
    }
    await load();
  }
}
