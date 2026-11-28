import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/cashbook/domain/calculators/cashbook_calculator.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(IstDateTimeHelper.initialize);

  const calc = CashbookCalculator();

  group('CashbookCalculator', () {
    test(
      'computes unified Cash & Bank balances across payments, receipts, expenses, transfers, and bills',
      () {
        const t1 = 1795500000000;
        const t2 = 1795510000000;

        final entries = [
          const CashbookEntryEntity(
            id: 'cb-open-cash',
            entryType: CashbookEntryType.openingCash,
            accountBucket: CashbookAccountBucket.cash,
            paymentMode: PaymentMode.cash,
            amountPaise: 100000, // ₹1,000
            transactionAt: t1,
            recordedAt: t1,
            createdAt: t1,
            updatedAt: t1,
          ),
          const CashbookEntryEntity(
            id: 'cb-open-bank',
            entryType: CashbookEntryType.openingBank,
            accountBucket: CashbookAccountBucket.bank,
            paymentMode: PaymentMode.bankTransfer,
            amountPaise: 500000, // ₹5,000
            transactionAt: t1,
            recordedAt: t1,
            createdAt: t1,
            updatedAt: t1,
          ),
          // Cash -> Bank deposit ₹300
          const CashbookEntryEntity(
            id: 'cb-c2b',
            entryType: CashbookEntryType.cashToBank,
            accountBucket: CashbookAccountBucket.both,
            paymentMode: PaymentMode.bankTransfer,
            amountPaise: 30000,
            transactionAt: t2,
            recordedAt: t2,
            createdAt: t2,
            updatedAt: t2,
          ),
          // Settle unpaid expense via UPI ₹150
          const CashbookEntryEntity(
            id: 'cb-settle',
            entryType: CashbookEntryType.expenseSettlement,
            accountBucket: CashbookAccountBucket.bank,
            paymentMode: PaymentMode.upi,
            amountPaise: 15000,
            linkedExpenseId: 'exp-unpaid',
            transactionAt: t2,
            recordedAt: t2,
            createdAt: t2,
            updatedAt: t2,
          ),
        ];

        final workerPayments = [
          // Cash outflow ₹200
          const PaymentEntity(
            id: 'wp-1',
            memberId: 'm-1',
            paymentType: PaymentType.regular,
            amountPaise: 20000,
            paymentMode: PaymentMode.cash,
            transactionAt: t2,
            recordedAt: t2,
            createdAt: t2,
            updatedAt: t2,
          ),
          // Reversed payment + reversal (net zero)
          const PaymentEntity(
            id: 'wp-2',
            memberId: 'm-1',
            paymentType: PaymentType.advance,
            amountPaise: 99900,
            paymentMode: PaymentMode.upi,
            transactionAt: t2,
            recordedAt: t2,
            createdAt: t2,
            updatedAt: t2,
          ),
          const PaymentEntity(
            id: 'wp-2-rev',
            memberId: 'm-1',
            paymentType: PaymentType.reversal,
            reversesPaymentId: 'wp-2',
            amountPaise: 99900,
            paymentMode: PaymentMode.upi,
            transactionAt: t2,
            recordedAt: t2,
            createdAt: t2,
            updatedAt: t2,
          ),
        ];

        final partyPayments = [
          // Bank UPI inflow ₹800
          const PartyPaymentEntity(
            id: 'pp-1',
            partyId: 'party-1',
            paymentType: PartyPaymentType.receipt,
            paymentMode: PartyPaymentMode.upi,
            amountPaise: 80000,
            transactionAt: t2,
            recordedAt: t2,
            createdAt: t2,
            updatedAt: t2,
          ),
        ];

        final expenses = [
          // Immediate Paid Cash ₹100
          const WorkshopExpenseEntity(
            id: 'exp-paid',
            category: ExpenseCategory.refreshments,
            title: 'Chai',
            amountPaise: 10000,
            paymentStatus: ExpensePaymentStatus.paid,
            paymentMode: PaymentMode.cash,
            transactionAt: t2,
            recordedAt: t2,
            createdAt: t2,
            updatedAt: t2,
          ),
          // Unpaid Bill ₹250 (₹150 settled above, ₹100 still pending)
          const WorkshopExpenseEntity(
            id: 'exp-unpaid',
            category: ExpenseCategory.electricity,
            title: 'Electricity Bill',
            amountPaise: 25000,
            paymentStatus: ExpensePaymentStatus.unpaid,
            transactionAt: t2,
            recordedAt: t2,
            createdAt: t2,
            updatedAt: t2,
          ),
        ];

        final summary = calc.calculateSummary(
          expenses: expenses,
          cashbookEntries: entries,
          workerPayments: workerPayments,
          partyPayments: partyPayments,
          referenceNowUtcMillis: t2,
        );

        // Cash: 1000 - 300 (c2b) - 200 (wp) - 100 (exp) = ₹400 (40000 paise)
        expect(summary.currentCashBalancePaise, 40000);
        // Bank: 5000 + 300 (c2b) + 800 (pp) - 150 (settle) = ₹5,950 (595000 paise)
        expect(summary.currentBankBalancePaise, 595000);
        expect(summary.totalExpensesPaidPaise, 25000); // 100 + 150
        expect(summary.totalExpensesUnpaidPaise, 10000); // 250 - 150
        expect(summary.todayExpensesPaise, 35000); // 100 + 250
        expect(summary.pendingBills, hasLength(1));
        expect(summary.pendingBills.first.remainingUnpaidPaise, 10000);
      },
    );

    test(
      'calculates True Workshop Net Profit excluding reversed items',
      () {
        const t1 = 1795500000000;
        final pnl = calc.calculateTrueNetProfit(
          challans: const [
            DispatchChallanEntity(
              id: 'dc-1',
              challanNumber: 'CH-1',
              partyId: 'p-1',
              grossAmountPaise: 100000,
              discountPaise: 0,
              otherChargesPaise: 0,
              netAmountPaise: 100000,
              transactionAt: t1,
              recordedAt: t1,
              createdAt: t1,
              updatedAt: t1,
            ),
          ],
          buyerReturns: const [
            BuyerReturnEntity(
              id: 'br-1',
              returnNumber: 'BR-1',
              partyId: 'p-1',
              creditAmountPaise: 10000,
              reason: 'Size mismatch',
              transactionAt: t1,
              recordedAt: t1,
              createdAt: t1,
              updatedAt: t1,
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
              quantity: 10,
              ratePaise: 2000,
              amountPaise: 20000,
              isPayable: true,
              transactionAt: t1,
              recordedAt: t1,
              createdAt: t1,
              updatedAt: t1,
            ),
          ],
          workerAdjustments: const [],
          lotDirectCosts: const [
            LotDirectCostEntity(
              id: 'dcost-1',
              lotId: 'lot-1',
              category: LotCostCategory.fabric,
              description: 'Cotton',
              amountPaise: 15000,
              transactionAt: t1,
              recordedAt: t1,
              createdAt: t1,
              updatedAt: t1,
            ),
          ],
          workshopExpenses: const [
            WorkshopExpenseEntity(
              id: 'we-1',
              category: ExpenseCategory.rent,
              title: 'Shop Rent',
              amountPaise: 12000,
              paymentStatus: ExpensePaymentStatus.paid,
              paymentMode: PaymentMode.bankTransfer,
              transactionAt: t1,
              recordedAt: t1,
              createdAt: t1,
              updatedAt: t1,
            ),
            WorkshopExpenseEntity(
              id: 'we-2',
              category: ExpenseCategory.other,
              title: 'Mistake',
              amountPaise: 50000,
              paymentStatus: ExpensePaymentStatus.paid,
              paymentMode: PaymentMode.cash,
              transactionAt: t1,
              recordedAt: t1,
              createdAt: t1,
              updatedAt: t1,
            ),
            WorkshopExpenseEntity(
              id: 'we-2-rev',
              category: ExpenseCategory.other,
              title: 'Mistake',
              amountPaise: 50000,
              paymentStatus: ExpensePaymentStatus.paid,
              paymentMode: PaymentMode.cash,
              reversesExpenseId: 'we-2',
              reason: 'Wrong',
              transactionAt: t1,
              recordedAt: t1,
              createdAt: t1,
              updatedAt: t1,
            ),
          ],
          cashbookEntries: const [],
        );

        // Net Sales = 1000 - 100 = 900; Labour = 200; Direct = 150; Overhead = 120
        // True Net Profit = 900 - 200 - 150 - 120 = 430 (43000 paise)
        expect(pnl.netDispatchedSalesPaise, 90000);
        expect(pnl.workerLabourPaise, 20000);
        expect(pnl.lotDirectCostsPaise, 15000);
        expect(pnl.workshopOverheadExpensesPaise, 12000);
        expect(pnl.trueNetProfitPaise, 43000);
      },
    );

    test(
      'computes negated timeline deltas for cashbook entry reversals, avoids duplicate settlement subtitle, and isolates period inflows/outflows',
      () {
        const tDay1 = 1795500000000;
        const tDay2 = 1795590000000;

        final entries = [
          const CashbookEntryEntity(
            id: 'cb-cap',
            entryType: CashbookEntryType.capitalIn,
            accountBucket: CashbookAccountBucket.cash,
            paymentMode: PaymentMode.cash,
            amountPaise: 50000,
            transactionAt: tDay1,
            recordedAt: tDay1,
            createdAt: tDay1,
            updatedAt: tDay1,
          ),
          const CashbookEntryEntity(
            id: 'cb-c2b',
            entryType: CashbookEntryType.cashToBank,
            accountBucket: CashbookAccountBucket.both,
            paymentMode: PaymentMode.bankTransfer,
            amountPaise: 20000,
            transactionAt: tDay2,
            recordedAt: tDay2,
            createdAt: tDay2,
            updatedAt: tDay2,
          ),
          const CashbookEntryEntity(
            id: 'cb-c2b-rev',
            entryType: CashbookEntryType.reversal,
            accountBucket: CashbookAccountBucket.both,
            paymentMode: PaymentMode.bankTransfer,
            amountPaise: 20000,
            reversesEntryId: 'cb-c2b',
            reason: 'Wrong amount',
            transactionAt: tDay2 + 1000,
            recordedAt: tDay2 + 1000,
            createdAt: tDay2 + 1000,
            updatedAt: tDay2 + 1000,
          ),
          const CashbookEntryEntity(
            id: 'cb-settle',
            entryType: CashbookEntryType.expenseSettlement,
            accountBucket: CashbookAccountBucket.bank,
            paymentMode: PaymentMode.upi,
            amountPaise: 10000,
            linkedExpenseId: 'exp-bill',
            transactionAt: tDay2 + 2000,
            recordedAt: tDay2 + 2000,
            createdAt: tDay2 + 2000,
            updatedAt: tDay2 + 2000,
          ),
        ];

        const bill = WorkshopExpenseEntity(
          id: 'exp-bill',
          category: ExpenseCategory.electricity,
          title: 'Power Bill',
          amountPaise: 10000,
          paymentStatus: ExpensePaymentStatus.unpaid,
          transactionAt: tDay1,
          recordedAt: tDay1,
          createdAt: tDay1,
          updatedAt: tDay1,
        );

        final summary = calc.calculateSummary(
          expenses: const [bill],
          cashbookEntries: entries,
          workerPayments: const [],
          partyPayments: const [],
          fromUtcMillis: tDay2,
          toUtcMillis: tDay2 + 5000,
          referenceNowUtcMillis: tDay2,
        );

        // Live balances still include Day 1 capital (+50000) minus Day 2 settlement (-10000).
        expect(summary.currentCashBalancePaise, 50000);
        expect(summary.currentBankBalancePaise, -10000);
        // Period inflows/outflows exclude Day 1 capital and reversed transfer.
        expect(summary.cashInflowPaise, 0);
        expect(summary.bankOutflowPaise, 10000);

        final revItem = summary.timeline.firstWhere(
          (i) => i.id == 'cb-c2b-rev',
        );
        expect(revItem.cashDeltaPaise, 20000);
        expect(revItem.bankDeltaPaise, -20000);
        expect(revItem.subtitle, 'Wrong amount');

        final settleItem = summary.timeline.firstWhere(
          (i) => i.id == 'cb-settle',
        );
        expect(settleItem.title, 'Power Bill');
        expect(settleItem.subtitle, isNull);
      },
    );
  });
}
