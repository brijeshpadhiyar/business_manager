import 'package:business_manager/core/database/tables/lot_tables.dart';
import 'package:drift/drift.dart';

/// 2.15 `parties` — Buyers, wholesale customers, and job-work client accounts.
@DataClassName('PartyRow')
class Parties extends Table {
  @override
  String get tableName => 'parties';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get partyType => text().withDefault(const Constant('BOTH'))();
  TextColumn get gstin => text().nullable()();

  /// Positive = receivable due from party; negative = opening advance credit.
  IntColumn get openingBalancePaise =>
      integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(length(trim(name)) > 0)',
    "CHECK(party_type IN ('BUYER', 'JOB_CLIENT', 'BOTH'))",
    'CHECK(is_active IN (0, 1))',
  ];
}

/// 2.16 `dispatch_challans` — Append-only party dispatch / billing challans.
/// Corrections require an explicit `reverses_challan_id` reversal challan.
@DataClassName('DispatchChallanRow')
class DispatchChallans extends Table {
  @override
  String get tableName => 'dispatch_challans';

  TextColumn get id => text()();
  TextColumn get challanNumber => text()();
  TextColumn get partyId =>
      text().references(Parties, #id, onDelete: KeyAction.restrict)();
  TextColumn get reversesChallanId => text().nullable().references(
    DispatchChallans,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get clientRequestId => text().nullable()();
  IntColumn get grossAmountPaise => integer()();
  IntColumn get discountPaise => integer().withDefault(const Constant(0))();
  IntColumn get otherChargesPaise => integer().withDefault(const Constant(0))();
  IntColumn get netAmountPaise => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(length(trim(challan_number)) > 0)',
    'CHECK(gross_amount_paise >= 0)',
    'CHECK(discount_paise >= 0)',
    'CHECK(other_charges_paise >= 0)',
    'CHECK(net_amount_paise >= 0)',
  ];
}

/// 2.17 `dispatch_items` — Line items belonging to a `dispatch_challans` header.
@DataClassName('DispatchItemRow')
class DispatchItems extends Table {
  @override
  String get tableName => 'dispatch_items';

  TextColumn get id => text()();
  TextColumn get challanId => text().references(
    DispatchChallans,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotDesignId =>
      text().references(LotDesigns, #id, onDelete: KeyAction.restrict)();
  TextColumn get designColourId =>
      text().references(DesignColours, #id, onDelete: KeyAction.restrict)();
  IntColumn get quantity => integer()();
  IntColumn get ratePaise => integer()();
  IntColumn get lineTotalPaise => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(quantity > 0)',
    'CHECK(rate_paise >= 0)',
    'CHECK(line_total_paise >= 0)',
  ];
}

/// 2.18 `buyer_returns` — Append-only buyer return / credit note headers.
@DataClassName('BuyerReturnRow')
class BuyerReturns extends Table {
  @override
  String get tableName => 'buyer_returns';

  TextColumn get id => text()();
  TextColumn get returnNumber => text()();
  TextColumn get partyId =>
      text().references(Parties, #id, onDelete: KeyAction.restrict)();
  TextColumn get challanId => text().nullable().references(
    DispatchChallans,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get reversesReturnId => text().nullable().references(
    BuyerReturns,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get clientRequestId => text().nullable()();
  IntColumn get creditAmountPaise => integer()();
  TextColumn get reason => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(length(trim(return_number)) > 0)',
    'CHECK(credit_amount_paise >= 0)',
    'CHECK(length(trim(reason)) > 0)',
  ];
}

/// 2.19 `buyer_return_items` — Line items returned by a buyer (`GOOD` or `DAMAGED`).
@DataClassName('BuyerReturnItemRow')
class BuyerReturnItems extends Table {
  @override
  String get tableName => 'buyer_return_items';

  TextColumn get id => text()();
  TextColumn get buyerReturnId =>
      text().references(BuyerReturns, #id, onDelete: KeyAction.restrict)();
  TextColumn get dispatchItemId => text().nullable().references(
    DispatchItems,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotDesignId =>
      text().references(LotDesigns, #id, onDelete: KeyAction.restrict)();
  TextColumn get designColourId =>
      text().references(DesignColours, #id, onDelete: KeyAction.restrict)();
  TextColumn get returnCondition => text()();
  IntColumn get quantity => integer()();
  IntColumn get ratePaise => integer()();
  IntColumn get lineCreditPaise => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(return_condition IN ('GOOD', 'DAMAGED'))",
    'CHECK(quantity > 0)',
    'CHECK(rate_paise >= 0)',
    'CHECK(line_credit_paise >= 0)',
  ];
}

/// 2.20 `party_payments` — Append-only buyer receipts, advances, refunds & reversals.
@DataClassName('PartyPaymentRow')
class PartyPayments extends Table {
  @override
  String get tableName => 'party_payments';

  TextColumn get id => text()();
  TextColumn get partyId =>
      text().references(Parties, #id, onDelete: KeyAction.restrict)();
  TextColumn get challanId => text().nullable().references(
    DispatchChallans,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get reversesPaymentId => text().nullable().references(
    PartyPayments,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get clientRequestId => text().nullable()();
  TextColumn get paymentType => text()();
  TextColumn get paymentMode => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get referenceNo => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(payment_type IN ('RECEIPT', 'ADVANCE', 'REFUND', 'REVERSAL'))",
    "CHECK(payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE', 'OTHER'))",
    'CHECK(amount_paise > 0)',
  ];
}

/// 2.21 `lot_direct_costs` — Append-only non-labour direct lot expenses
/// (Fabric, Trims, Transport, Packing, Other) + audited reversals.
@DataClassName('LotDirectCostRow')
class LotDirectCosts extends Table {
  @override
  String get tableName => 'lot_direct_costs';

  TextColumn get id => text()();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get reversesCostId => text().nullable().references(
    LotDirectCosts,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get clientRequestId => text().nullable()();
  TextColumn get category => text()();
  TextColumn get description => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(category IN ('FABRIC', 'TRIMS', 'TRANSPORT', 'PACKING', 'OTHER'))",
    'CHECK(length(trim(description)) > 0)',
    'CHECK(amount_paise > 0)',
  ];
}
