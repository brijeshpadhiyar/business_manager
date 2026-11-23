import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

abstract interface class StockMovementRepository {
  /// Previews the historical rate for `(workerId, processId)` on [transactionAtUtcMillis]
  /// using `MemberProcessRateResolver` (IST business date).
  Future<RateResolutionResult> previewRate({
    required String workerId,
    required String processId,
    required int transactionAtUtcMillis,
  });

  /// Returns live stock balance for a single `design_colour_id`.
  Future<DesignColourStockBalance?> getDesignColourBalance(
    String designColourId,
  );

  /// Returns live stock balances across all active (non-deleted) design colours.
  Future<List<DesignColourStockBalance>> getAllDesignColourBalances({
    String? lotId,
    bool onlyWithDamaged = false,
  });

  /// Returns open issues that still have `remainingPending > 0`, optionally
  /// filtered by worker, process, or lot.
  Future<List<OpenIssueSummary>> getOpenIssues({
    String? workerId,
    String? processId,
    String? lotId,
    String? designColourId,
  });

  /// Returns detailed view of a single issue and all its child settlements.
  Future<OpenIssueSummary?> getIssueDetail(String issueId);

  /// Returns enriched movement history matching [filter], newest first.
  Future<List<StockMovementView>> getMovementHistory({
    StockMovementFilter filter = const StockMovementFilter(),
  });

  /// Returns worker-wise issued/returned/pending stock totals.
  Future<List<WorkerStockSummary>> getWorkerStockSummaries();

  /// Returns process-wise issued/returned/pending stock totals.
  Future<List<ProcessStockSummary>> getProcessStockSummaries();

  /// Atomically validates 5-point pre-issue rules, resolves/locks historical
  /// rate and billing configuration, inserts `ISSUE`, inserts matching
  /// `labour_entries`, and records `audit_logs`.
  Future<StockMovementEntity> issueStock({
    required String designColourId,
    required String processId,
    required String workerId,
    required int quantity,
    required int transactionAtUtcMillis,
    String? notes,
    bool allowRateOverride = false,
    int? overrideRatePaise,
    String? overrideReason,
    String? clientRequestId,
  });

  /// Atomically records partial or complete returns/settlements
  /// (`RETURN_GOOD`, `RETURN_DAMAGED`, `SETTLEMENT_LOST`, `SETTLEMENT_SHORTAGE`)
  /// inheriting the parent issue's locked rate and billing configuration.
  Future<SettlementBatchResult> recordSettlement({
    required String parentIssueId,
    required int goodQuantity,
    required int damagedQuantity,
    required int lostQuantity,
    required int shortageQuantity,
    required int transactionAtUtcMillis,
    String? reason,
    String? notes,
    String? clientRequestId,
  });

  /// Atomically converts repaired pieces from the Damaged Stock bucket back
  /// into Good Physical Stock (`ADJUSTMENT_DAMAGED_TO_GOOD`) with audit trail.
  Future<StockMovementEntity> recordDamagedToGoodAdjustment({
    required String designColourId,
    required int quantity,
    required String reason,
    required int transactionAtUtcMillis,
    String? notes,
    String? clientRequestId,
  });

  /// Atomically validates chronological prefix replay safety, inserts a
  /// `REVERSAL` movement, inserts offsetting `REVERSAL` labour entries if any,
  /// and writes a `REVERSAL` audit log.
  Future<StockMovementEntity> reverseMovement({
    required String movementId,
    required String reason,
    required int transactionAtUtcMillis,
    String? notes,
  });
}
