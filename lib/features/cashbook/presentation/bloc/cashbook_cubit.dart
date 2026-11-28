import 'dart:typed_data';

import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/cashbook/domain/repositories/cashbook_repository.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum CashbookStatus { initial, loading, loaded, error }

final class CashbookState {
  const CashbookState({
    this.status = CashbookStatus.initial,
    this.summary,
    this.errorMessage,
    this.activeTab = 0,
    this.bucketFilter,
    this.sourceFilter,
    this.categoryFilter,
    this.datePreset = ReportDatePreset.allTime,
    this.searchQuery = '',
    this.fromUtcMillis,
    this.toUtcMillis,
  });

  final CashbookStatus status;
  final CashbookSummary? summary;
  final String? errorMessage;
  final int activeTab;
  final CashbookAccountBucket? bucketFilter;
  final CashbookTimelineSource? sourceFilter;
  final ExpenseCategory? categoryFilter;
  final ReportDatePreset datePreset;
  final String searchQuery;
  final int? fromUtcMillis;
  final int? toUtcMillis;

  CashbookState copyWith({
    CashbookStatus? status,
    CashbookSummary? summary,
    String? errorMessage,
    int? activeTab,
    CashbookAccountBucket? bucketFilter,
    bool clearBucketFilter = false,
    CashbookTimelineSource? sourceFilter,
    bool clearSourceFilter = false,
    ExpenseCategory? categoryFilter,
    bool clearCategoryFilter = false,
    ReportDatePreset? datePreset,
    String? searchQuery,
    int? fromUtcMillis,
    int? toUtcMillis,
    bool clearDateRange = false,
  }) {
    return CashbookState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
      activeTab: activeTab ?? this.activeTab,
      bucketFilter: clearBucketFilter
          ? null
          : (bucketFilter ?? this.bucketFilter),
      sourceFilter: clearSourceFilter
          ? null
          : (sourceFilter ?? this.sourceFilter),
      categoryFilter: clearCategoryFilter
          ? null
          : (categoryFilter ?? this.categoryFilter),
      datePreset: datePreset ?? this.datePreset,
      searchQuery: searchQuery ?? this.searchQuery,
      fromUtcMillis: clearDateRange
          ? null
          : (fromUtcMillis ?? this.fromUtcMillis),
      toUtcMillis: clearDateRange ? null : (toUtcMillis ?? this.toUtcMillis),
    );
  }
}

@injectable
final class CashbookCubit extends Cubit<CashbookState> {
  CashbookCubit(this._repository) : super(const CashbookState());

  final CashbookRepository _repository;

  Future<void> load() async {
    if (state.summary == null) {
      emit(state.copyWith(status: CashbookStatus.loading));
    }
    try {
      final summary = await _repository.getCashbookSummary(
        fromUtcMillis: state.fromUtcMillis,
        toUtcMillis: state.toUtcMillis,
      );
      if (isClosed) return;
      emit(state.copyWith(status: CashbookStatus.loaded, summary: summary));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CashbookStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void selectTab(int tab) {
    emit(state.copyWith(activeTab: tab));
  }

  void setBucketFilter(CashbookAccountBucket? bucket) {
    emit(
      state.copyWith(
        bucketFilter: bucket,
        clearBucketFilter: bucket == null,
      ),
    );
  }

  void setSourceFilter(CashbookTimelineSource? source) {
    emit(
      state.copyWith(
        sourceFilter: source,
        clearSourceFilter: source == null,
      ),
    );
  }

  void setCategoryFilter(ExpenseCategory? category) {
    emit(
      state.copyWith(
        categoryFilter: category,
        clearCategoryFilter: category == null,
      ),
    );
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> setDatePreset(
    ReportDatePreset preset, {
    int? customFromUtcMillis,
    int? customToUtcMillis,
  }) async {
    if (preset == ReportDatePreset.allTime) {
      emit(
        state.copyWith(
          datePreset: ReportDatePreset.allTime,
          clearDateRange: true,
        ),
      );
      await load();
      return;
    }

    if (preset == ReportDatePreset.custom) {
      emit(
        state.copyWith(
          datePreset: ReportDatePreset.custom,
          fromUtcMillis: customFromUtcMillis,
          toUtcMillis: customToUtcMillis,
          clearDateRange:
              customFromUtcMillis == null && customToUtcMillis == null,
        ),
      );
      await load();
      return;
    }

    final resolved = IstDateRangePresets.resolve(preset);
    emit(
      state.copyWith(
        datePreset: preset,
        fromUtcMillis: resolved.fromUtcMillis,
        toUtcMillis: resolved.toUtcMillis,
      ),
    );
    await load();
  }

  Future<void> markExpensePaid({
    required String expenseId,
    required PaymentMode paymentMode,
    required int amountPaise,
    String? referenceNo,
    String? notes,
    required int transactionAtUtcMillis,
  }) async {
    await _repository.markExpensePaid(
      expenseId: expenseId,
      paymentMode: paymentMode,
      amountPaise: amountPaise,
      referenceNo: referenceNo,
      notes: notes,
      transactionAtUtcMillis: transactionAtUtcMillis,
    );
    await load();
  }

  Future<void> reverseExpense({
    required String expenseId,
    required String reason,
    required int transactionAtUtcMillis,
  }) async {
    await _repository.reverseExpense(
      expenseId: expenseId,
      reason: reason,
      transactionAtUtcMillis: transactionAtUtcMillis,
    );
    await load();
  }

  Future<void> reverseCashbookEntry({
    required String entryId,
    required String reason,
    required int transactionAtUtcMillis,
  }) async {
    await _repository.reverseCashbookEntry(
      entryId: entryId,
      reason: reason,
      transactionAtUtcMillis: transactionAtUtcMillis,
    );
    await load();
  }

  Future<void> setOpeningBalances({
    required int openingCashPaise,
    required int openingBankPaise,
    required int transactionAtUtcMillis,
  }) async {
    await _repository.setOpeningBalances(
      openingCashPaise: openingCashPaise,
      openingBankPaise: openingBankPaise,
      transactionAtUtcMillis: transactionAtUtcMillis,
    );
    await load();
  }

  Future<Uint8List?> readReceiptBytes(String expenseId) {
    return _repository.readExpenseReceiptBytes(expenseId);
  }

  Future<List<CashbookEntryEntity>> getExpenseSettlements(String expenseId) {
    return _repository.getExpenseSettlements(expenseId);
  }

  Future<void> attachExpenseReceipt({
    required String expenseId,
    required Uint8List receiptBytes,
    String fileExtension = 'jpg',
    String mimeType = 'image/jpeg',
  }) async {
    await _repository.attachExpenseReceipt(
      expenseId: expenseId,
      receiptBytes: receiptBytes,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );
    await load();
  }
}
