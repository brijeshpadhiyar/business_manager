import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/mappers/actor_resolver.dart';
import 'package:business_manager/core/database/mappers/ledger_row_mappers.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/parties/domain/calculators/lot_profit_loss_calculator.dart';
import 'package:business_manager/features/parties/domain/calculators/party_ledger_calculator.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:business_manager/features/production_history/data/repositories/production_history_dataset_loader.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_history_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PartyRepository)
final class PartyRepositoryImpl implements PartyRepository {
  PartyRepositoryImpl(this._db, this._txRunner, this._idGenerator);

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;

  static const PartyLedgerCalculator _partyCalc = PartyLedgerCalculator();
  static const LotProfitLossCalculator _pnlCalc = LotProfitLossCalculator();
  static const StockCalculator _stockCalc = StockCalculator();
  static const ProductionHistoryCalculator _prodCalc =
      ProductionHistoryCalculator();

  /// Loads aggregated dispatch & buyer-return stock deltas keyed by
  /// `design_colour_id` from active (non-reversed) rows.
  static Future<Map<String, PartyDispatchStockDelta>> loadStockDeltasByColour(
    AppDatabase db,
  ) async {
    final challans = (await db.partyDispatchDao.getAllChallans())
        .map(LedgerRowMappers.dispatchChallan)
        .toList();
    if (challans.isEmpty) return const {};
    final items = (await db.partyDispatchDao.getAllDispatchItems())
        .map(LedgerRowMappers.dispatchItem)
        .toList();
    final returns = (await db.partyDispatchDao.getAllBuyerReturns())
        .map(LedgerRowMappers.buyerReturn)
        .toList();
    final returnItems = (await db.partyDispatchDao.getAllBuyerReturnItems())
        .map(LedgerRowMappers.buyerReturnItem)
        .toList();
    return _partyCalc.buildStockDeltasByColour(
      challans: challans,
      dispatchItems: items,
      buyerReturns: returns,
      buyerReturnItems: returnItems,
    );
  }

  @override
  Future<List<PartyFinancialSummary>> getAllPartySummaries({
    String? searchQuery,
    bool includeInactive = true,
  }) async {
    final parties = (await _db.partyDispatchDao.getNonDeletedParties())
        .map(LedgerRowMappers.party)
        .toList();
    final challans = (await _db.partyDispatchDao.getAllChallans())
        .map(LedgerRowMappers.dispatchChallan)
        .toList();
    final items = (await _db.partyDispatchDao.getAllDispatchItems())
        .map(LedgerRowMappers.dispatchItem)
        .toList();
    final returns = (await _db.partyDispatchDao.getAllBuyerReturns())
        .map(LedgerRowMappers.buyerReturn)
        .toList();
    final returnItems = (await _db.partyDispatchDao.getAllBuyerReturnItems())
        .map(LedgerRowMappers.buyerReturnItem)
        .toList();
    final payments = (await _db.partyDispatchDao.getAllPartyPayments())
        .map(LedgerRowMappers.partyPayment)
        .toList();

    final query = searchQuery?.trim().toLowerCase() ?? '';
    final list = <PartyFinancialSummary>[];
    for (final p in parties) {
      if (!includeInactive && !p.isActive) continue;
      if (query.isNotEmpty) {
        final match =
            p.name.toLowerCase().contains(query) ||
            (p.phone?.toLowerCase().contains(query) ?? false) ||
            (p.gstin?.toLowerCase().contains(query) ?? false);
        if (!match) continue;
      }
      list.add(
        _partyCalc.calculatePartySummary(
          party: p,
          challans: challans,
          dispatchItems: items,
          buyerReturns: returns,
          buyerReturnItems: returnItems,
          payments: payments,
        ),
      );
    }
    list.sort((a, b) {
      final outCmp = b.outstandingReceivablePaise.compareTo(
        a.outstandingReceivablePaise,
      );
      if (outCmp != 0) return outCmp;
      return a.partyName.toLowerCase().compareTo(b.partyName.toLowerCase());
    });
    return list;
  }

  @override
  Future<PartyEntity?> getPartyById(String partyId) async {
    final row = await _db.partyDispatchDao.findPartyById(partyId);
    if (row == null || row.deletedAt != null) return null;
    return LedgerRowMappers.party(row);
  }

  @override
  Future<PartyLedgerDetail?> getPartyLedgerDetail(
    String partyId, {
    int? fromUtcMillis,
    int? toUtcMillis,
  }) async {
    final party = await getPartyById(partyId);
    if (party == null) return null;

    final challanRows = await _db.partyDispatchDao.getChallansForParty(partyId);
    final challans = challanRows.map(LedgerRowMappers.dispatchChallan).toList();
    final allItems = await _db.partyDispatchDao.getAllDispatchItems();
    final returnRows = await _db.partyDispatchDao.getBuyerReturnsForParty(
      partyId,
    );
    final returns = returnRows.map(LedgerRowMappers.buyerReturn).toList();
    final allReturnItems = await _db.partyDispatchDao.getAllBuyerReturnItems();
    final payments = (await _db.partyDispatchDao.getPartyPaymentsForParty(
      partyId,
    )).map(LedgerRowMappers.partyPayment).toList();

    final lookups = await _loadLotLookups();
    final mappedItems = allItems
        .map((r) => _mapDispatchItemWithLookup(r, lookups))
        .toList();
    final mappedReturnItems = allReturnItems
        .map((r) => _mapReturnItemWithLookup(r, lookups))
        .toList();

    final summary = _partyCalc.calculatePartySummary(
      party: party,
      challans: challans,
      dispatchItems: mappedItems,
      buyerReturns: returns,
      buyerReturnItems: mappedReturnItems,
      payments: payments,
    );

    final entries = _partyCalc.buildLedgerEntries(
      party: party,
      challans: challans,
      buyerReturns: returns,
      payments: payments,
      fromUtcMillis: fromUtcMillis,
      toUtcMillis: toUtcMillis,
    );

    final challanViews = _buildChallanViews(
      challans: challans,
      items: mappedItems,
      returns: returns,
      returnItems: mappedReturnItems,
      partiesById: {party.id: party},
    );
    final returnViews = _buildReturnViews(
      returns: returns,
      items: mappedReturnItems,
      challansById: {for (final c in challans) c.id: c},
      partiesById: {party.id: party},
    );

    return PartyLedgerDetail(
      party: party,
      summary: summary,
      entries: entries,
      challans: challanViews,
      buyerReturns: returnViews,
      payments: payments,
    );
  }

  @override
  Future<PartyEntity> createParty({
    required String name,
    String? phone,
    String? address,
    PartyType partyType = PartyType.both,
    String? gstin,
    int openingBalancePaise = 0,
    String? notes,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const DomainValidationException(
        'party_name_required',
        'Party name is required.',
      );
    }
    if (cleanName.length > ValidationLimits.maxPersonNameLength ||
        (notes != null && notes.trim().length > ValidationLimits.maxNotesLength)) {
      throw const DomainValidationException(
        'text_too_long',
        'Input exceeds maximum allowed length.',
      );
    }
    if (openingBalancePaise.abs() > ValidationLimits.maxAmountPaise) {
      throw const DomainValidationException(
        'amount_too_large',
        'Opening balance exceeds maximum allowed limit.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final existing = await _db.partyDispatchDao.getNonDeletedParties();
      final duplicate = existing.any(
        (p) => p.name.trim().toLowerCase() == cleanName.toLowerCase(),
      );
      if (duplicate) {
        throw const DomainValidationException(
          'duplicate_party_name',
          'A party with this name already exists.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final id = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.partyDispatchDao.insertParty(
        PartiesCompanion(
          id: Value(id),
          name: Value(cleanName),
          phone: Value(_nullIfBlank(phone)),
          address: Value(_nullIfBlank(address)),
          partyType: Value(partyType.dbValue),
          gstin: Value(_nullIfBlank(gstin)?.toUpperCase()),
          openingBalancePaise: Value(openingBalancePaise),
          notes: Value(_nullIfBlank(notes)),
          isActive: const Value(1),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _insertAudit(
        entityType: 'parties',
        entityId: id,
        actionType: 'CREATE',
        afterValues: {'name': cleanName, 'partyType': partyType.dbValue},
        actor: actor,
        now: now,
      );

      return LedgerRowMappers.party(
        (await _db.partyDispatchDao.findPartyById(id))!,
      );
    });
  }

  @override
  Future<PartyEntity> updateParty({
    required String partyId,
    required String name,
    String? phone,
    String? address,
    required PartyType partyType,
    String? gstin,
    required int openingBalancePaise,
    String? notes,
    required bool isActive,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const DomainValidationException(
        'party_name_required',
        'Party name is required.',
      );
    }
    if (openingBalancePaise.abs() > ValidationLimits.maxAmountPaise) {
      throw const DomainValidationException(
        'amount_too_large',
        'Opening balance exceeds maximum allowed limit.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final existing = await _db.partyDispatchDao.findPartyById(partyId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Party not found.');
      }

      final allParties = await _db.partyDispatchDao.getNonDeletedParties();
      final duplicate = allParties.any(
        (p) =>
            p.id != partyId &&
            p.name.trim().toLowerCase() == cleanName.toLowerCase(),
      );
      if (duplicate) {
        throw const DomainValidationException(
          'duplicate_party_name',
          'A party with this name already exists.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveOptional(_db);
      await _db.partyDispatchDao.updateParty(
        partyId,
        PartiesCompanion(
          name: Value(cleanName),
          phone: Value(_nullIfBlank(phone)),
          address: Value(_nullIfBlank(address)),
          partyType: Value(partyType.dbValue),
          gstin: Value(_nullIfBlank(gstin)?.toUpperCase()),
          openingBalancePaise: Value(openingBalancePaise),
          notes: Value(_nullIfBlank(notes)),
          isActive: Value(isActive ? 1 : 0),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _insertAudit(
        entityType: 'parties',
        entityId: partyId,
        actionType: 'UPDATE',
        beforeValues: {'name': existing.name, 'isActive': existing.isActive},
        afterValues: {'name': cleanName, 'isActive': isActive ? 1 : 0},
        actor: actor,
        now: now,
      );

      return LedgerRowMappers.party(
        (await _db.partyDispatchDao.findPartyById(partyId))!,
      );
    });
  }

  @override
  Future<String> suggestNextChallanNumber() async {
    final rows = await _db.partyDispatchDao.getAllChallans();
    var maxNum = 0;
    final regex = RegExp(r'^DC-(\d+)$', caseSensitive: false);
    for (final r in rows) {
      final match = regex.firstMatch(r.challanNumber.trim());
      if (match != null) {
        final parsed = int.tryParse(match.group(1)!) ?? 0;
        if (parsed > maxNum) maxNum = parsed;
      }
    }
    return 'DC-${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  @override
  Future<String> suggestNextReturnNumber() async {
    final rows = await _db.partyDispatchDao.getAllBuyerReturns();
    var maxNum = 0;
    final regex = RegExp(r'^BR-(\d+)$', caseSensitive: false);
    for (final r in rows) {
      final match = regex.firstMatch(r.returnNumber.trim());
      if (match != null) {
        final parsed = int.tryParse(match.group(1)!) ?? 0;
        if (parsed > maxNum) maxNum = parsed;
      }
    }
    return 'BR-${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  @override
  Future<List<DispatchChallanView>> getDispatchChallans({
    String? partyId,
  }) async {
    final challanRows = partyId != null
        ? await _db.partyDispatchDao.getChallansForParty(partyId)
        : await _db.partyDispatchDao.getAllChallans();
    final challans = challanRows.map(LedgerRowMappers.dispatchChallan).toList();
    final allItems = await _db.partyDispatchDao.getAllDispatchItems();
    final returns = (await _db.partyDispatchDao.getAllBuyerReturns())
        .map(LedgerRowMappers.buyerReturn)
        .toList();
    final returnItems = (await _db.partyDispatchDao.getAllBuyerReturnItems())
        .map(LedgerRowMappers.buyerReturnItem)
        .toList();
    final parties = (await _db.partyDispatchDao.getNonDeletedParties())
        .map(LedgerRowMappers.party)
        .toList();
    final lookups = await _loadLotLookups();

    return _buildChallanViews(
      challans: challans,
      items: allItems
          .map((r) => _mapDispatchItemWithLookup(r, lookups))
          .toList(),
      returns: returns,
      returnItems: returnItems,
      partiesById: {for (final p in parties) p.id: p},
    );
  }

  @override
  Future<DispatchChallanView?> getDispatchChallanDetail(
    String challanId,
  ) async {
    final row = await _db.partyDispatchDao.findChallanById(challanId);
    if (row == null || row.deletedAt != null) return null;
    final all = await getDispatchChallans(partyId: row.partyId);
    for (final view in all) {
      if (view.challan.id == challanId) return view;
    }
    return null;
  }

  @override
  Future<DispatchChallanView> createDispatchChallan({
    required String partyId,
    required String challanNumber,
    required List<DispatchLineDraft> items,
    int discountPaise = 0,
    int otherChargesPaise = 0,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  }) async {
    final cleanNumber = challanNumber.trim();
    if (cleanNumber.isEmpty) {
      throw const DomainValidationException(
        'challan_number_required',
        'Challan number is required.',
      );
    }
    if (items.isEmpty) {
      throw const DomainValidationException(
        'dispatch_items_required',
        'Add at least one item to dispatch.',
      );
    }
    if (discountPaise < 0 || otherChargesPaise < 0) {
      throw const DomainValidationException(
        'invalid_amount',
        'Discount and extra charges cannot be negative.',
      );
    }

    final reqId = clientRequestId ?? _idGenerator.nextRequestId();

    final createdId = await _txRunner.runInTransaction(() async {
      final existingReplay = await _db.partyDispatchDao
          .findChallanByClientRequestId(reqId);
      if (existingReplay != null) {
        return existingReplay.id;
      }

      final party = await _db.partyDispatchDao.findPartyById(partyId);
      if (party == null || party.deletedAt != null || party.isActive != 1) {
        throw const DomainValidationException(
          'inactive_or_missing_party',
          'Selected party is inactive or does not exist.',
        );
      }

      final existingChallans = await _db.partyDispatchDao.getAllChallans();
      if (existingChallans.any(
        (c) => c.challanNumber.trim().toLowerCase() == cleanNumber.toLowerCase(),
      )) {
        throw const DomainValidationException(
          'duplicate_challan_number',
          'A dispatch challan with this number already exists.',
        );
      }

      // Verify available in-house good stock per colour inside the transaction
      // so concurrent/multi-line dispatches can never over-dispatch.
      final requestedByColour = <String, int>{};
      var grossAmountPaise = 0;
      for (final line in items) {
        if (line.quantity <= 0 || line.quantity > ValidationLimits.maxQuantity) {
          throw const DomainValidationException(
            'invalid_quantity',
            'Dispatch quantity must be greater than zero.',
          );
        }
        if (line.ratePaise < 0 ||
            line.ratePaise > ValidationLimits.maxAmountPaise) {
          throw const DomainValidationException(
            'invalid_rate',
            'Rate is out of valid range.',
          );
        }
        requestedByColour.update(
          line.designColourId,
          (v) => v + line.quantity,
          ifAbsent: () => line.quantity,
        );
        grossAmountPaise += line.quantity * line.ratePaise;
      }

      final deltasByColour = await loadStockDeltasByColour(_db);
      for (final entry in requestedByColour.entries) {
        final available = await _computeLiveAvailableForColour(
          entry.key,
          deltasByColour[entry.key],
        );
        if (entry.value > available) {
          throw DomainValidationException(
            'insufficient_stock_for_dispatch',
            'Insufficient physical good stock (available: $available, requested: ${entry.value}).',
          );
        }
      }

      final netAmountPaise = grossAmountPaise - discountPaise + otherChargesPaise;
      if (netAmountPaise < 0) {
        throw const DomainValidationException(
          'discount_exceeds_gross',
          'Discount cannot exceed challan total.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final challanId = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.partyDispatchDao.insertDispatchChallan(
        DispatchChallansCompanion(
          id: Value(challanId),
          challanNumber: Value(cleanNumber),
          partyId: Value(partyId),
          clientRequestId: Value(reqId),
          grossAmountPaise: Value(grossAmountPaise),
          discountPaise: Value(discountPaise),
          otherChargesPaise: Value(otherChargesPaise),
          netAmountPaise: Value(netAmountPaise),
          notes: Value(_nullIfBlank(notes)),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      for (final line in items) {
        final itemId = _idGenerator.nextEntityId();
        await _db.partyDispatchDao.insertDispatchItem(
          DispatchItemsCompanion(
            id: Value(itemId),
            challanId: Value(challanId),
            lotId: Value(line.lotId),
            lotDesignId: Value(line.lotDesignId),
            designColourId: Value(line.designColourId),
            quantity: Value(line.quantity),
            ratePaise: Value(line.ratePaise),
            lineTotalPaise: Value(line.quantity * line.ratePaise),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      await _insertAudit(
        entityType: 'dispatch_challans',
        entityId: challanId,
        actionType: 'CREATE',
        afterValues: {
          'challanNumber': cleanNumber,
          'partyId': partyId,
          'netAmountPaise': netAmountPaise,
          'itemCount': items.length,
        },
        actor: actor,
        now: now,
      );

      return challanId;
    });

    return (await getDispatchChallanDetail(createdId))!;
  }

  @override
  Future<DispatchChallanEntity> reverseDispatchChallan({
    required String challanId,
    required String reason,
    String? notes,
    int? transactionAtUtcMillis,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw const DomainValidationException(
        'reason_required',
        'A reversal reason is required.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final target = await _db.partyDispatchDao.findChallanById(challanId);
      if (target == null || target.deletedAt != null) {
        throw const LocalStorageException('Dispatch challan not found.');
      }
      if (target.reversesChallanId != null) {
        throw const DomainValidationException(
          'cannot_reverse_reversal',
          'Cannot reverse a reversal challan.',
        );
      }
      final existingRev = await _db.partyDispatchDao.findReversalForChallan(
        challanId,
      );
      if (existingRev != null) {
        throw const DomainValidationException(
          'already_reversed',
          'This dispatch challan has already been reversed.',
        );
      }

      // Block challan reversal if an active buyer return references this challan.
      final allReturns = (await _db.partyDispatchDao.getAllBuyerReturns())
          .map(LedgerRowMappers.buyerReturn)
          .toList();
      final revReturnIds = _partyCalc.reversedBuyerReturnIds(allReturns);
      final hasActiveReturn = allReturns.any(
        (r) =>
            r.challanId == challanId &&
            !r.isReversal &&
            !revReturnIds.contains(r.id),
      );
      if (hasActiveReturn) {
        throw const DomainValidationException(
          'active_buyer_return_exists',
          'Reverse active buyer returns linked to this challan first.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final revId = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);
      final revNumber = 'REV-${target.challanNumber}-$now';

      await _db.partyDispatchDao.insertDispatchChallan(
        DispatchChallansCompanion(
          id: Value(revId),
          challanNumber: Value(revNumber),
          partyId: Value(target.partyId),
          reversesChallanId: Value(target.id),
          grossAmountPaise: Value(target.grossAmountPaise),
          discountPaise: Value(target.discountPaise),
          otherChargesPaise: Value(target.otherChargesPaise),
          netAmountPaise: Value(target.netAmountPaise),
          reason: Value(cleanReason),
          notes: Value(_nullIfBlank(notes)),
          transactionAt: Value(transactionAtUtcMillis ?? now),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _insertAudit(
        entityType: 'dispatch_challans',
        entityId: revId,
        actionType: 'REVERSAL',
        reason: cleanReason,
        beforeValues: {'reversesChallanId': target.id},
        actor: actor,
        now: now,
      );

      return LedgerRowMappers.dispatchChallan(
        (await _db.partyDispatchDao.findChallanById(revId))!,
      );
    });
  }

  @override
  Future<BuyerReturnView> createBuyerReturn({
    required String partyId,
    String? challanId,
    required String returnNumber,
    required List<BuyerReturnLineDraft> items,
    required String reason,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  }) async {
    final cleanNumber = returnNumber.trim();
    final cleanReason = reason.trim();
    if (cleanNumber.isEmpty) {
      throw const DomainValidationException(
        'return_number_required',
        'Return number is required.',
      );
    }
    if (cleanReason.isEmpty) {
      throw const DomainValidationException(
        'reason_required',
        'Return reason is required.',
      );
    }
    if (items.isEmpty) {
      throw const DomainValidationException(
        'return_items_required',
        'Add at least one returned item.',
      );
    }

    final reqId = clientRequestId ?? _idGenerator.nextRequestId();

    final createdId = await _txRunner.runInTransaction(() async {
      final existingReplay = await _db.partyDispatchDao
          .findBuyerReturnByClientRequestId(reqId);
      if (existingReplay != null) {
        return existingReplay.id;
      }

      final party = await _db.partyDispatchDao.findPartyById(partyId);
      if (party == null || party.deletedAt != null) {
        throw const LocalStorageException('Party not found.');
      }

      final allReturns = (await _db.partyDispatchDao.getAllBuyerReturns())
          .map(LedgerRowMappers.buyerReturn)
          .toList();
      if (allReturns.any(
        (r) =>
            r.returnNumber.trim().toLowerCase() == cleanNumber.toLowerCase(),
      )) {
        throw const DomainValidationException(
          'duplicate_return_number',
          'A buyer return with this number already exists.',
        );
      }

      final challans = (await _db.partyDispatchDao.getChallansForParty(partyId))
          .map(LedgerRowMappers.dispatchChallan)
          .toList();
      final revChallans = _partyCalc.reversedChallanIds(challans);
      final activeChallanIds = {
        for (final c in challans)
          if (!c.isReversal && !revChallans.contains(c.id)) c.id,
      };
      if (challanId != null && !activeChallanIds.contains(challanId)) {
        throw const DomainValidationException(
          'invalid_challan_for_return',
          'Selected dispatch challan is inactive or reversed.',
        );
      }

      final allDispatchItems = (await _db.partyDispatchDao.getAllDispatchItems())
          .map(LedgerRowMappers.dispatchItem)
          .toList();
      final revReturnIds = _partyCalc.reversedBuyerReturnIds(allReturns);
      final activeReturnIds = {
        for (final r in allReturns)
          if (r.partyId == partyId && !r.isReversal && !revReturnIds.contains(r.id))
            r.id,
      };
      final allReturnItems = (await _db.partyDispatchDao.getAllBuyerReturnItems())
          .map(LedgerRowMappers.buyerReturnItem)
          .toList();

      // Validate per colour (and per challan if scoped) that return qty
      // does not exceed net dispatched qty to this party.
      final dispatchedByColour = <String, int>{};
      for (final d in allDispatchItems) {
        if (!activeChallanIds.contains(d.challanId)) continue;
        if (challanId != null && d.challanId != challanId) continue;
        dispatchedByColour.update(
          d.designColourId,
          (v) => v + d.quantity,
          ifAbsent: () => d.quantity,
        );
      }
      final alreadyReturnedByColour = <String, int>{};
      for (final r in allReturnItems) {
        if (!activeReturnIds.contains(r.buyerReturnId)) continue;
        alreadyReturnedByColour.update(
          r.designColourId,
          (v) => v + r.quantity,
          ifAbsent: () => r.quantity,
        );
      }

      final requestedByColour = <String, int>{};
      var totalCreditPaise = 0;
      for (final line in items) {
        if (line.quantity <= 0) {
          throw const DomainValidationException(
            'invalid_quantity',
            'Return quantity must be greater than zero.',
          );
        }
        if (line.ratePaise < 0) {
          throw const DomainValidationException(
            'invalid_rate',
            'Return rate cannot be negative.',
          );
        }
        requestedByColour.update(
          line.designColourId,
          (v) => v + line.quantity,
          ifAbsent: () => line.quantity,
        );
        totalCreditPaise += line.quantity * line.ratePaise;
      }

      for (final entry in requestedByColour.entries) {
        final maxReturnable =
            (dispatchedByColour[entry.key] ?? 0) -
            (challanId == null ? (alreadyReturnedByColour[entry.key] ?? 0) : 0);
        if (entry.value > maxReturnable) {
          throw DomainValidationException(
            'return_exceeds_dispatched',
            'Return quantity (${entry.value}) exceeds remaining dispatched quantity ($maxReturnable).',
          );
        }
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final returnId = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.partyDispatchDao.insertBuyerReturn(
        BuyerReturnsCompanion(
          id: Value(returnId),
          returnNumber: Value(cleanNumber),
          partyId: Value(partyId),
          challanId: Value(challanId),
          clientRequestId: Value(reqId),
          creditAmountPaise: Value(totalCreditPaise),
          reason: Value(cleanReason),
          notes: Value(_nullIfBlank(notes)),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      for (final line in items) {
        await _db.partyDispatchDao.insertBuyerReturnItem(
          BuyerReturnItemsCompanion(
            id: Value(_idGenerator.nextEntityId()),
            buyerReturnId: Value(returnId),
            dispatchItemId: Value(line.dispatchItemId),
            lotId: Value(line.lotId),
            lotDesignId: Value(line.lotDesignId),
            designColourId: Value(line.designColourId),
            returnCondition: Value(line.returnCondition.dbValue),
            quantity: Value(line.quantity),
            ratePaise: Value(line.ratePaise),
            lineCreditPaise: Value(line.quantity * line.ratePaise),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      await _insertAudit(
        entityType: 'buyer_returns',
        entityId: returnId,
        actionType: 'CREATE',
        reason: cleanReason,
        afterValues: {
          'returnNumber': cleanNumber,
          'partyId': partyId,
          'creditAmountPaise': totalCreditPaise,
        },
        actor: actor,
        now: now,
      );

      return returnId;
    });

    final row = (await _db.partyDispatchDao.findBuyerReturnById(createdId))!;
    final party = (await getPartyById(row.partyId))!;
    final lookups = await _loadLotLookups();
    final returnItems = (await _db.partyDispatchDao.getBuyerReturnItemsForReturn(
      createdId,
    )).map((r) => _mapReturnItemWithLookup(r, lookups)).toList();
    String? challanNum;
    if (row.challanId != null) {
      challanNum = (await _db.partyDispatchDao.findChallanById(
        row.challanId!,
      ))?.challanNumber;
    }

    return BuyerReturnView(
      buyerReturn: LedgerRowMappers.buyerReturn(row),
      partyName: party.name,
      challanNumber: challanNum,
      items: returnItems,
      isReversed: false,
    );
  }

  @override
  Future<BuyerReturnEntity> reverseBuyerReturn({
    required String buyerReturnId,
    required String reason,
    String? notes,
    int? transactionAtUtcMillis,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw const DomainValidationException(
        'reason_required',
        'A reversal reason is required.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final target = await _db.partyDispatchDao.findBuyerReturnById(
        buyerReturnId,
      );
      if (target == null || target.deletedAt != null) {
        throw const LocalStorageException('Buyer return not found.');
      }
      if (target.reversesReturnId != null) {
        throw const DomainValidationException(
          'cannot_reverse_reversal',
          'Cannot reverse a reversal row.',
        );
      }
      final existingRev = await _db.partyDispatchDao
          .findReversalForBuyerReturn(buyerReturnId);
      if (existingRev != null) {
        throw const DomainValidationException(
          'already_reversed',
          'This buyer return has already been reversed.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final revId = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.partyDispatchDao.insertBuyerReturn(
        BuyerReturnsCompanion(
          id: Value(revId),
          returnNumber: Value('REV-${target.returnNumber}-$now'),
          partyId: Value(target.partyId),
          challanId: Value(target.challanId),
          reversesReturnId: Value(target.id),
          creditAmountPaise: Value(target.creditAmountPaise),
          reason: Value(cleanReason),
          notes: Value(_nullIfBlank(notes)),
          transactionAt: Value(transactionAtUtcMillis ?? now),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _insertAudit(
        entityType: 'buyer_returns',
        entityId: revId,
        actionType: 'REVERSAL',
        reason: cleanReason,
        beforeValues: {'reversesReturnId': target.id},
        actor: actor,
        now: now,
      );

      return LedgerRowMappers.buyerReturn(
        (await _db.partyDispatchDao.findBuyerReturnById(revId))!,
      );
    });
  }

  @override
  Future<PartyPaymentEntity> recordPartyPayment({
    required String partyId,
    String? challanId,
    required PartyPaymentType paymentType,
    required PartyPaymentMode paymentMode,
    required int amountPaise,
    String? referenceNo,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  }) async {
    if (paymentType == PartyPaymentType.reversal) {
      throw const DomainValidationException(
        'invalid_payment_type',
        'Use reversePartyPayment for reversals.',
      );
    }
    if (amountPaise <= 0 || amountPaise > ValidationLimits.maxAmountPaise) {
      throw const DomainValidationException(
        'invalid_amount',
        'Payment amount must be greater than zero.',
      );
    }

    final reqId = clientRequestId ?? _idGenerator.nextRequestId();

    return _txRunner.runInTransaction(() async {
      final replay = await _db.partyDispatchDao
          .findPartyPaymentByClientRequestId(reqId);
      if (replay != null) return LedgerRowMappers.partyPayment(replay);

      final party = await _db.partyDispatchDao.findPartyById(partyId);
      if (party == null || party.deletedAt != null) {
        throw const LocalStorageException('Party not found.');
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final id = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.partyDispatchDao.insertPartyPayment(
        PartyPaymentsCompanion(
          id: Value(id),
          partyId: Value(partyId),
          challanId: Value(challanId),
          clientRequestId: Value(reqId),
          paymentType: Value(paymentType.dbValue),
          paymentMode: Value(paymentMode.dbValue),
          amountPaise: Value(amountPaise),
          referenceNo: Value(_nullIfBlank(referenceNo)),
          notes: Value(_nullIfBlank(notes)),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _insertAudit(
        entityType: 'party_payments',
        entityId: id,
        actionType: 'CREATE',
        afterValues: {
          'partyId': partyId,
          'paymentType': paymentType.dbValue,
          'paymentMode': paymentMode.dbValue,
          'amountPaise': amountPaise,
        },
        actor: actor,
        now: now,
      );

      return LedgerRowMappers.partyPayment(
        (await _db.partyDispatchDao.findPartyPaymentById(id))!,
      );
    });
  }

  @override
  Future<PartyPaymentEntity> reversePartyPayment({
    required String paymentId,
    required String reason,
    String? notes,
    int? transactionAtUtcMillis,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw const DomainValidationException(
        'reason_required',
        'A reversal reason is required.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final target = await _db.partyDispatchDao.findPartyPaymentById(paymentId);
      if (target == null || target.deletedAt != null) {
        throw const LocalStorageException('Party payment not found.');
      }
      if (target.paymentType == PartyPaymentType.reversal.dbValue) {
        throw const DomainValidationException(
          'cannot_reverse_reversal',
          'Cannot reverse a reversal entry.',
        );
      }
      final existingRev = await _db.partyDispatchDao
          .findReversalForPartyPayment(paymentId);
      if (existingRev != null) {
        throw const DomainValidationException(
          'already_reversed',
          'This payment has already been reversed.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final revId = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.partyDispatchDao.insertPartyPayment(
        PartyPaymentsCompanion(
          id: Value(revId),
          partyId: Value(target.partyId),
          challanId: Value(target.challanId),
          reversesPaymentId: Value(target.id),
          paymentType: Value(PartyPaymentType.reversal.dbValue),
          paymentMode: Value(target.paymentMode),
          amountPaise: Value(target.amountPaise),
          referenceNo: Value(target.referenceNo),
          reason: Value(cleanReason),
          notes: Value(_nullIfBlank(notes)),
          transactionAt: Value(transactionAtUtcMillis ?? now),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _insertAudit(
        entityType: 'party_payments',
        entityId: revId,
        actionType: 'REVERSAL',
        reason: cleanReason,
        beforeValues: {'reversesPaymentId': target.id},
        actor: actor,
        now: now,
      );

      return LedgerRowMappers.partyPayment(
        (await _db.partyDispatchDao.findPartyPaymentById(revId))!,
      );
    });
  }

  @override
  Future<List<LotDirectCostEntity>> getLotDirectCosts(String lotId) async {
    return (await _db.partyDispatchDao.getDirectCostsForLot(lotId))
        .map(LedgerRowMappers.lotDirectCost)
        .toList();
  }

  @override
  Future<LotDirectCostEntity> addLotDirectCost({
    required String lotId,
    required LotCostCategory category,
    required String description,
    required int amountPaise,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  }) async {
    final cleanDesc = description.trim();
    if (cleanDesc.isEmpty) {
      throw const DomainValidationException(
        'description_required',
        'Cost description is required.',
      );
    }
    if (amountPaise <= 0 || amountPaise > ValidationLimits.maxAmountPaise) {
      throw const DomainValidationException(
        'invalid_amount',
        'Cost amount must be greater than zero.',
      );
    }

    final reqId = clientRequestId ?? _idGenerator.nextRequestId();

    return _txRunner.runInTransaction(() async {
      final replay = await _db.partyDispatchDao
          .findLotDirectCostByClientRequestId(reqId);
      if (replay != null) return LedgerRowMappers.lotDirectCost(replay);

      final lot = await _db.lotDao.findLotById(lotId);
      if (lot == null || lot.deletedAt != null) {
        throw const LocalStorageException('Lot not found.');
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final id = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.partyDispatchDao.insertLotDirectCost(
        LotDirectCostsCompanion(
          id: Value(id),
          lotId: Value(lotId),
          clientRequestId: Value(reqId),
          category: Value(category.dbValue),
          description: Value(cleanDesc),
          amountPaise: Value(amountPaise),
          notes: Value(_nullIfBlank(notes)),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _insertAudit(
        entityType: 'lot_direct_costs',
        entityId: id,
        actionType: 'CREATE',
        afterValues: {
          'lotId': lotId,
          'category': category.dbValue,
          'description': cleanDesc,
          'amountPaise': amountPaise,
        },
        actor: actor,
        now: now,
      );

      return LedgerRowMappers.lotDirectCost(
        (await _db.partyDispatchDao.findLotDirectCostById(id))!,
      );
    });
  }

  @override
  Future<LotDirectCostEntity> reverseLotDirectCost({
    required String costId,
    required String reason,
    String? notes,
    int? transactionAtUtcMillis,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw const DomainValidationException(
        'reason_required',
        'A reversal reason is required.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final target = await _db.partyDispatchDao.findLotDirectCostById(costId);
      if (target == null || target.deletedAt != null) {
        throw const LocalStorageException('Direct cost record not found.');
      }
      if (target.reversesCostId != null) {
        throw const DomainValidationException(
          'cannot_reverse_reversal',
          'Cannot reverse a reversal row.',
        );
      }
      final existingRev = await _db.partyDispatchDao
          .findReversalForLotDirectCost(costId);
      if (existingRev != null) {
        throw const DomainValidationException(
          'already_reversed',
          'This cost entry has already been reversed.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final revId = _idGenerator.nextEntityId();
      final actor = await ActorResolver.resolveOptional(_db);

      await _db.partyDispatchDao.insertLotDirectCost(
        LotDirectCostsCompanion(
          id: Value(revId),
          lotId: Value(target.lotId),
          reversesCostId: Value(target.id),
          category: Value(target.category),
          description: Value('Reversal: ${target.description}'),
          amountPaise: Value(target.amountPaise),
          reason: Value(cleanReason),
          notes: Value(_nullIfBlank(notes)),
          transactionAt: Value(transactionAtUtcMillis ?? now),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _insertAudit(
        entityType: 'lot_direct_costs',
        entityId: revId,
        actionType: 'REVERSAL',
        reason: cleanReason,
        beforeValues: {'reversesCostId': target.id},
        actor: actor,
        now: now,
      );

      return LedgerRowMappers.lotDirectCost(
        (await _db.partyDispatchDao.findLotDirectCostById(revId))!,
      );
    });
  }

  @override
  Future<LotProfitLossSummary?> getLotProfitLoss(String lotId) async {
    final lot = await _db.lotDao.findLotById(lotId);
    if (lot == null || lot.deletedAt != null) return null;
    final all = await getAllLotProfitLoss();
    for (final item in all) {
      if (item.lotId == lotId) return item;
    }
    return null;
  }

  @override
  Future<List<LotProfitLossSummary>> getAllLotProfitLoss() async {
    final lots = await _db.lotDao.getActiveLots();
    final designs = await _db.lotDao.getAllActiveDesigns();
    final colours = await _db.lotDao.getAllActiveDesignColours();
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(LedgerRowMappers.stockMovement)
        .toList();
    final returnsRows = (await _db.productionTrackingDao.getAllReturns())
        .map(ProductionHistoryDatasetLoader.mapReturn)
        .toList();
    final inspectionRows = (await _db.productionTrackingDao.getAllInspections())
        .map(ProductionHistoryDatasetLoader.mapInspection)
        .toList();
    final pendingByColour = _prodCalc.pendingInspectionByDesignColour(
      returns: returnsRows,
      inspections: inspectionRows,
      reversedMovementIds: _stockCalc.reversedMovementIds(allMovements),
    );
    final challans = (await _db.partyDispatchDao.getAllChallans())
        .map(LedgerRowMappers.dispatchChallan)
        .toList();
    final dispatchItems = (await _db.partyDispatchDao.getAllDispatchItems())
        .map(LedgerRowMappers.dispatchItem)
        .toList();
    final buyerReturns = (await _db.partyDispatchDao.getAllBuyerReturns())
        .map(LedgerRowMappers.buyerReturn)
        .toList();
    final buyerReturnItems =
        (await _db.partyDispatchDao.getAllBuyerReturnItems())
            .map(LedgerRowMappers.buyerReturnItem)
            .toList();
    final labourEntries = (await _db.labourEntryDao.getAllEntries())
        .map(LedgerRowMappers.labourEntry)
        .toList();
    final directCosts = (await _db.partyDispatchDao.getAllLotDirectCosts())
        .map(LedgerRowMappers.lotDirectCost)
        .toList();

    final deltas = _partyCalc.buildStockDeltasByColour(
      challans: challans,
      dispatchItems: dispatchItems,
      buyerReturns: buyerReturns,
      buyerReturnItems: buyerReturnItems,
    );

    final lotById = {for (final l in lots) l.id: l};
    final designById = {for (final d in designs) d.id: d};
    final movementsByColour = <String, List<StockMovementEntity>>{};
    for (final m in allMovements) {
      movementsByColour.putIfAbsent(m.designColourId, () => []).add(m);
    }

    final balances = <DesignColourStockBalance>[];
    for (final c in colours) {
      final d = designById[c.lotDesignId];
      if (d == null) continue;
      final l = lotById[d.lotId];
      if (l == null) continue;
      final delta = deltas[c.id];
      balances.add(
        _stockCalc.calculateDesignColourBalance(
          designColourId: c.id,
          lotId: l.id,
          lotNumber: l.lotNumber,
          lotDesignId: d.id,
          designName: d.designName,
          colourName: c.colourName,
          colourHex: c.colourHex,
          unitPricePaise: c.unitPricePaise,
          initialQuantity: c.initialQuantity,
          allMovementsForColour: movementsByColour[c.id] ?? const [],
          pendingInspectionQuantity: pendingByColour[c.id] ?? 0,
          dispatchedOutQty: delta?.dispatchedOutQty ?? 0,
          buyerReturnedGoodQty: delta?.buyerReturnedGoodQty ?? 0,
          buyerReturnedDamagedQty: delta?.buyerReturnedDamagedQty ?? 0,
        ),
      );
    }

    final summaries = lots
        .map(
          (l) => _pnlCalc.calculateForLot(
            lotId: l.id,
            lotNumber: l.lotNumber,
            lotTitle: l.title,
            colourBalances: balances,
            challans: challans,
            dispatchItems: dispatchItems,
            buyerReturns: buyerReturns,
            buyerReturnItems: buyerReturnItems,
            labourEntries: labourEntries,
            directCosts: directCosts,
          ),
        )
        .toList();

    summaries.sort((a, b) => b.netProfitPaise.compareTo(a.netProfitPaise));
    return summaries;
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<int> _computeLiveAvailableForColour(
    String designColourId,
    PartyDispatchStockDelta? delta,
  ) async {
    final c = await _db.lotDao.findDesignColourById(designColourId);
    if (c == null || c.deletedAt != null) {
      throw const LocalStorageException('Design colour not found.');
    }
    final d = await _db.lotDao.findDesignById(c.lotDesignId);
    if (d == null || d.deletedAt != null) {
      throw const LocalStorageException('Design not found.');
    }
    final l = await _db.lotDao.findLotById(d.lotId);
    if (l == null || l.deletedAt != null) {
      throw const LocalStorageException('Lot not found.');
    }

    final movements = (await _db.stockMovementDao.getMovementsForDesignColour(
      designColourId,
    )).map(LedgerRowMappers.stockMovement).toList();

    final balance = _stockCalc.calculateDesignColourBalance(
      designColourId: c.id,
      lotId: l.id,
      lotNumber: l.lotNumber,
      lotDesignId: d.id,
      designName: d.designName,
      colourName: c.colourName,
      colourHex: c.colourHex,
      unitPricePaise: c.unitPricePaise,
      initialQuantity: c.initialQuantity,
      allMovementsForColour: movements,
      dispatchedOutQty: delta?.dispatchedOutQty ?? 0,
      buyerReturnedGoodQty: delta?.buyerReturnedGoodQty ?? 0,
      buyerReturnedDamagedQty: delta?.buyerReturnedDamagedQty ?? 0,
    );
    return balance.physicalAvailableInHouse;
  }

  Future<
    ({
      Map<String, LotRow> lots,
      Map<String, LotDesignRow> designs,
      Map<String, DesignColourRow> colours,
    })
  >
  _loadLotLookups() async {
    final lots = await _db.select(_db.lots).get();
    final designs = await _db.select(_db.lotDesigns).get();
    final colours = await _db.select(_db.designColours).get();
    return (
      lots: {for (final l in lots) l.id: l},
      designs: {for (final d in designs) d.id: d},
      colours: {for (final c in colours) c.id: c},
    );
  }

  DispatchItemEntity _mapDispatchItemWithLookup(
    DispatchItemRow row,
    ({
      Map<String, LotRow> lots,
      Map<String, LotDesignRow> designs,
      Map<String, DesignColourRow> colours,
    })
    lookups,
  ) {
    final lot = lookups.lots[row.lotId];
    final design = lookups.designs[row.lotDesignId];
    final colour = lookups.colours[row.designColourId];
    return LedgerRowMappers.dispatchItem(
      row,
      lotNumber: lot?.lotNumber ?? '',
      designName: design?.designName ?? '',
      colourName: colour?.colourName ?? '',
      colourHex: colour?.colourHex,
    );
  }

  BuyerReturnItemEntity _mapReturnItemWithLookup(
    BuyerReturnItemRow row,
    ({
      Map<String, LotRow> lots,
      Map<String, LotDesignRow> designs,
      Map<String, DesignColourRow> colours,
    })
    lookups,
  ) {
    final lot = lookups.lots[row.lotId];
    final design = lookups.designs[row.lotDesignId];
    final colour = lookups.colours[row.designColourId];
    return LedgerRowMappers.buyerReturnItem(
      row,
      lotNumber: lot?.lotNumber ?? '',
      designName: design?.designName ?? '',
      colourName: colour?.colourName ?? '',
    );
  }

  List<DispatchChallanView> _buildChallanViews({
    required List<DispatchChallanEntity> challans,
    required List<DispatchItemEntity> items,
    required List<BuyerReturnEntity> returns,
    required List<BuyerReturnItemEntity> returnItems,
    required Map<String, PartyEntity> partiesById,
  }) {
    final revMap = <String, String>{};
    for (final c in challans) {
      if (c.reversesChallanId != null) {
        revMap[c.reversesChallanId!] = c.id;
      }
    }
    final itemsByChallan = <String, List<DispatchItemEntity>>{};
    for (final item in items) {
      itemsByChallan.putIfAbsent(item.challanId, () => []).add(item);
    }

    final revReturnIds = _partyCalc.reversedBuyerReturnIds(returns);
    final activeReturnIds = {
      for (final r in returns)
        if (!r.isReversal && !revReturnIds.contains(r.id)) r.id,
    };
    final returnedQtyByItem = <String, int>{};
    for (final ri in returnItems) {
      if (!activeReturnIds.contains(ri.buyerReturnId)) continue;
      if (ri.dispatchItemId == null) continue;
      returnedQtyByItem.update(
        ri.dispatchItemId!,
        (v) => v + ri.quantity,
        ifAbsent: () => ri.quantity,
      );
    }

    return challans.map((c) {
      final party = partiesById[c.partyId];
      final cItems = itemsByChallan[c.id] ?? const [];
      final itemReturnMap = <String, int>{
        for (final it in cItems)
          if (returnedQtyByItem.containsKey(it.id))
            it.id: returnedQtyByItem[it.id]!,
      };
      return DispatchChallanView(
        challan: c,
        partyName: party?.name ?? c.partyId,
        partyPhone: party?.phone,
        partyAddress: party?.address,
        items: cItems,
        isReversed: revMap.containsKey(c.id),
        reversedByChallanId: revMap[c.id],
        returnedQtyByItemId: itemReturnMap,
      );
    }).toList();
  }

  List<BuyerReturnView> _buildReturnViews({
    required List<BuyerReturnEntity> returns,
    required List<BuyerReturnItemEntity> items,
    required Map<String, DispatchChallanEntity> challansById,
    required Map<String, PartyEntity> partiesById,
  }) {
    final revIds = _partyCalc.reversedBuyerReturnIds(returns);
    final itemsByReturn = <String, List<BuyerReturnItemEntity>>{};
    for (final item in items) {
      itemsByReturn.putIfAbsent(item.buyerReturnId, () => []).add(item);
    }
    return returns.map((r) {
      final party = partiesById[r.partyId];
      final challan = r.challanId != null ? challansById[r.challanId!] : null;
      return BuyerReturnView(
        buyerReturn: r,
        partyName: party?.name ?? r.partyId,
        challanNumber: challan?.challanNumber,
        items: itemsByReturn[r.id] ?? const [],
        isReversed: revIds.contains(r.id),
      );
    }).toList();
  }

  Future<void> _insertAudit({
    required String entityType,
    required String entityId,
    required String actionType,
    String? reason,
    Map<String, Object?>? beforeValues,
    Map<String, Object?>? afterValues,
    String? actor,
    required int now,
  }) {
    return _db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion(
        id: Value(_idGenerator.nextEntityId()),
        entityType: Value(entityType),
        entityId: Value(entityId),
        actionType: Value(actionType),
        actor: Value(actor),
        previousValueJson: Value(
          beforeValues == null ? null : jsonEncode(beforeValues),
        ),
        newValueJson: Value(
          afterValues == null ? null : jsonEncode(afterValues),
        ),
        reason: Value(reason),
        transactionAt: Value(now),
        recordedAt: Value(now),
      ),
    );
  }

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
