import 'package:business_manager/features/inventory/domain/calculators/inventory_overview_calculator.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const now = 1795324800000;

  test('computes accurate Initial Quantity totals and lot/design/colour summaries', () {
    const lots = [
      LotEntity(
        id: 'lot-1',
        lotNumber: 'LOT-001',
        status: LotStatus.active,
        transactionAt: now,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      LotEntity(
        id: 'lot-2',
        lotNumber: 'LOT-002',
        status: LotStatus.active,
        transactionAt: now,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    const designs = [
      LotDesignEntity(
        id: 'd-1',
        lotId: 'lot-1',
        designName: 'D-101',
        createdAt: now,
        updatedAt: now,
      ),
      LotDesignEntity(
        id: 'd-2',
        lotId: 'lot-2',
        designName: 'D-201',
        createdAt: now,
        updatedAt: now,
      ),
      // Design belonging to an archived lot not in activeLots — must be ignored
      LotDesignEntity(
        id: 'd-orphan',
        lotId: 'lot-archived',
        designName: 'D-OLD',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    const colours = [
      DesignColourEntity(
        id: 'c-1',
        lotDesignId: 'd-1',
        colourName: 'Red',
        initialQuantity: 100,
        unitPricePaise: 25000,
        createdAt: now,
        updatedAt: now,
      ),
      DesignColourEntity(
        id: 'c-2',
        lotDesignId: 'd-1',
        colourName: 'Blue',
        initialQuantity: 80,
        unitPricePaise: 25000,
        createdAt: now,
        updatedAt: now,
      ),
      DesignColourEntity(
        id: 'c-3',
        lotDesignId: 'd-1',
        colourName: 'Black',
        initialQuantity: 120,
        unitPricePaise: 27500,
        createdAt: now,
        updatedAt: now,
      ),
      DesignColourEntity(
        id: 'c-4',
        lotDesignId: 'd-2',
        colourName: 'White',
        initialQuantity: 50,
        unitPricePaise: 30000,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final overview = InventoryOverviewCalculator.calculate(
      activeLots: lots,
      activeDesigns: designs,
      activeColours: colours,
    );

    expect(overview.totalActiveLots, 2);
    expect(overview.totalDesigns, 2);
    expect(overview.totalDesignColourCombinations, 4);
    expect(overview.totalInitialQuantity, 350);

    expect(overview.lotSummaries[0].totalInitialQuantity, 300);
    expect(overview.lotSummaries[1].totalInitialQuantity, 50);
    expect(overview.designSummaries[0].totalInitialQuantity, 300);
    expect(overview.designSummaries[1].totalInitialQuantity, 50);
    expect(overview.colourSummaries.length, 4);
  });
}
