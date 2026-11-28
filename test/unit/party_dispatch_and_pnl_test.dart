import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/backup/domain/calculators/data_health_calculator.dart';
import 'package:business_manager/features/parties/domain/calculators/lot_profit_loss_calculator.dart';
import 'package:business_manager/features/parties/domain/calculators/party_ledger_calculator.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/sync/domain/services/sync_table_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const stockCalc = StockCalculator();
  const partyCalc = PartyLedgerCalculator();
  const pnlCalc = LotProfitLossCalculator();
  const healthCalc = DataHealthCalculator();

  group('StockCalculator + DataHealthCalculator with Party Dispatch & Returns', () {
    test('Golden equation holds with dispatch outflow and good/damaged buyer returns', () {
      final balance = stockCalc.calculateDesignColourBalance(
        designColourId: 'col-1',
        lotId: 'lot-1',
        lotNumber: '1001',
        lotDesignId: 'des-1',
        designName: 'Design A',
        colourName: 'Red',
        unitPricePaise: 50000,
        initialQuantity: 100,
        allMovementsForColour: const [],
        dispatchedOutQty: 40,
        buyerReturnedGoodQty: 3,
        buyerReturnedDamagedQty: 2,
      );

      expect(balance.physicalAvailableInHouse, 63);
      expect(balance.damagedBucket, 2);
      expect(balance.netDispatchedQty, 35);

      final issues = healthCalc.evaluateStockReconciliation([
        const ColourReconciliationInput(
          designColourId: 'col-1',
          lotId: 'lot-1',
          lotNumber: '1001',
          lotDesignId: 'des-1',
          designName: 'Design A',
          colourName: 'Red',
          unitPricePaise: 50000,
          initialQuantity: 100,
          movements: [],
          pendingInspectionQuantity: 0,
          dispatchedOutQty: 40,
          buyerReturnedGoodQty: 3,
          buyerReturnedDamagedQty: 2,
        ),
      ]);
      expect(issues, isEmpty);
    });
  });

  group('PartyLedgerCalculator', () {
    const party = PartyEntity(
      id: 'p-1',
      name: 'Mehta Traders',
      partyType: PartyType.buyer,
      openingBalancePaise: 10000,
      isActive: true,
      createdAt: 1000,
      updatedAt: 1000,
    );

    test('computes receivable, advance credit, returns and reversals accurately', () {
      final challans = [
        const DispatchChallanEntity(
          id: 'dc-1',
          challanNumber: 'DC-0001',
          partyId: 'p-1',
          grossAmountPaise: 100000,
          discountPaise: 5000,
          otherChargesPaise: 2000,
          netAmountPaise: 97000,
          transactionAt: 2000,
          recordedAt: 2000,
          createdAt: 2000,
          updatedAt: 2000,
        ),
        const DispatchChallanEntity(
          id: 'dc-2',
          challanNumber: 'DC-0002',
          partyId: 'p-1',
          grossAmountPaise: 50000,
          discountPaise: 0,
          otherChargesPaise: 0,
          netAmountPaise: 50000,
          transactionAt: 2500,
          recordedAt: 2500,
          createdAt: 2500,
          updatedAt: 2500,
        ),
        const DispatchChallanEntity(
          id: 'dc-rev',
          challanNumber: 'REV-DC-0002',
          partyId: 'p-1',
          reversesChallanId: 'dc-2',
          grossAmountPaise: 50000,
          discountPaise: 0,
          otherChargesPaise: 0,
          netAmountPaise: 50000,
          reason: 'Wrong lot',
          transactionAt: 2600,
          recordedAt: 2600,
          createdAt: 2600,
          updatedAt: 2600,
        ),
      ];

      final returns = [
        const BuyerReturnEntity(
          id: 'br-1',
          returnNumber: 'BR-0001',
          partyId: 'p-1',
          challanId: 'dc-1',
          creditAmountPaise: 15000,
          reason: 'Size mismatch',
          transactionAt: 3000,
          recordedAt: 3000,
          createdAt: 3000,
          updatedAt: 3000,
        ),
      ];

      final payments = [
        const PartyPaymentEntity(
          id: 'pp-1',
          partyId: 'p-1',
          paymentType: PartyPaymentType.receipt,
          paymentMode: PartyPaymentMode.upi,
          amountPaise: 120000,
          transactionAt: 4000,
          recordedAt: 4000,
          createdAt: 4000,
          updatedAt: 4000,
        ),
      ];

      // 10000 opening + 97000 dispatch - 15000 return - 120000 receipt = -28000 (advance credit)
      final summary = partyCalc.calculatePartySummary(
        party: party,
        challans: challans,
        dispatchItems: const [],
        buyerReturns: returns,
        buyerReturnItems: const [],
        payments: payments,
      );

      expect(summary.totalDispatchedNetPaise, 97000);
      expect(summary.totalBuyerReturnsPaise, 15000);
      expect(summary.totalReceiptsPaise, 120000);
      expect(summary.outstandingReceivablePaise, 0);
      expect(summary.advanceCreditPaise, 28000);

      final entries = partyCalc.buildLedgerEntries(
        party: party,
        challans: challans,
        buyerReturns: returns,
        payments: payments,
      );
      // Most recent entry is pp-1; final running balance is -28000
      expect(entries.first.runningBalancePaise, -28000);
    });
  });

  group('LotProfitLossCalculator', () {
    test('calculates net revenue, worker labour, direct costs and margin', () {
      final bal = stockCalc.calculateDesignColourBalance(
        designColourId: 'col-1',
        lotId: 'lot-1',
        lotNumber: '1001',
        lotDesignId: 'des-1',
        designName: 'Design A',
        colourName: 'Red',
        unitPricePaise: 50000,
        initialQuantity: 100,
        allMovementsForColour: const [],
        dispatchedOutQty: 60,
        buyerReturnedGoodQty: 5,
      );

      final summary = pnlCalc.calculateForLot(
        lotId: 'lot-1',
        lotNumber: '1001',
        colourBalances: [bal],
        challans: const [
          DispatchChallanEntity(
            id: 'dc-1',
            challanNumber: 'DC-0001',
            partyId: 'p-1',
            grossAmountPaise: 3000000,
            discountPaise: 0,
            otherChargesPaise: 0,
            netAmountPaise: 3000000,
            transactionAt: 1000,
            recordedAt: 1000,
            createdAt: 1000,
            updatedAt: 1000,
          ),
        ],
        dispatchItems: const [
          DispatchItemEntity(
            id: 'di-1',
            challanId: 'dc-1',
            lotId: 'lot-1',
            lotDesignId: 'des-1',
            designColourId: 'col-1',
            quantity: 60,
            ratePaise: 50000,
            lineTotalPaise: 3000000,
            createdAt: 1000,
            updatedAt: 1000,
          ),
        ],
        buyerReturns: const [
          BuyerReturnEntity(
            id: 'br-1',
            returnNumber: 'BR-0001',
            partyId: 'p-1',
            challanId: 'dc-1',
            creditAmountPaise: 250000,
            reason: 'Extra',
            transactionAt: 2000,
            recordedAt: 2000,
            createdAt: 2000,
            updatedAt: 2000,
          ),
        ],
        buyerReturnItems: const [
          BuyerReturnItemEntity(
            id: 'bri-1',
            buyerReturnId: 'br-1',
            dispatchItemId: 'di-1',
            lotId: 'lot-1',
            lotDesignId: 'des-1',
            designColourId: 'col-1',
            returnCondition: BuyerReturnCondition.good,
            quantity: 5,
            ratePaise: 50000,
            lineCreditPaise: 250000,
            createdAt: 2000,
            updatedAt: 2000,
          ),
        ],
        labourEntries: const [
          LabourEntryEntity(
            id: 'l-1',
            stockMovementId: 'sm-1',
            memberId: 'm-1',
            processId: 'pr-1',
            lotId: 'lot-1',
            basisType: LabourBasisType.receivedGood,
            quantity: 100,
            ratePaise: 5000,
            amountPaise: 500000,
            isPayable: true,
            transactionAt: 1000,
            recordedAt: 1000,
            createdAt: 1000,
            updatedAt: 1000,
          ),
        ],
        directCosts: const [
          LotDirectCostEntity(
            id: 'c-1',
            lotId: 'lot-1',
            category: LotCostCategory.fabric,
            description: 'Cotton',
            amountPaise: 1000000,
            transactionAt: 1000,
            recordedAt: 1000,
            createdAt: 1000,
            updatedAt: 1000,
          ),
        ],
      );

      expect(summary.netDispatchedPieces, 55);
      expect(summary.availableGoodPieces, 45);
      expect(summary.netRevenuePaise, 2750000);
      expect(summary.workerLabourPaise, 500000);
      expect(summary.directCostsPaise, 1000000);
      expect(summary.netProfitPaise, 1250000);
      expect(summary.unsoldEstimatedValuePaise, 45 * 50000);
      expect(summary.profitMarginPercent, closeTo(45.45, 0.05));
    });
  });

  group('RBAC & SyncTableRegistry v1.9', () {
    test('enforces party & dispatch permissions per role', () {
      expect(
        RbacPolicy.can(BusinessRole.manager, AppPermission.createDispatchAndReturns),
        isTrue,
      );
      expect(
        RbacPolicy.can(BusinessRole.manager, AppPermission.recordPartyReceipts),
        isFalse,
      );
      expect(
        RbacPolicy.can(BusinessRole.accountant, AppPermission.recordPartyReceipts),
        isTrue,
      );
      expect(
        RbacPolicy.can(BusinessRole.accountant, AppPermission.createDispatchAndReturns),
        isFalse,
      );
      expect(
        RbacPolicy.can(BusinessRole.qcInspector, AppPermission.viewPartiesAndDispatch),
        isFalse,
      );
    });

    test('SyncTableRegistry orders party parent tables before children', () {
      expect(SyncTableRegistry.syncedTablesInPushOrder, hasLength(32));
      expect(
        SyncTableRegistry.orderOf('workshop_expenses'),
        lessThan(SyncTableRegistry.orderOf('cashbook_entries')),
      );
      expect(
        SyncTableRegistry.orderOf('parties'),
        lessThan(SyncTableRegistry.orderOf('dispatch_challans')),
      );
      expect(
        SyncTableRegistry.orderOf('dispatch_challans'),
        lessThan(SyncTableRegistry.orderOf('dispatch_items')),
      );
      expect(
        SyncTableRegistry.orderOf('buyer_returns'),
        lessThan(SyncTableRegistry.orderOf('buyer_return_items')),
      );
    });
  });
}
