import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum AccountingOverviewStatus { initial, loading, loaded, error }

final class AccountingOverviewState {
  const AccountingOverviewState({
    this.status = AccountingOverviewStatus.initial,
    this.workerSummaries = const [],
    this.recentPayments = const [],
    this.labourEntries = const [],
    this.totalEarnedPaise = 0,
    this.totalOutstandingPaise = 0,
    this.totalAdvanceCreditPaise = 0,
    this.totalPaidPaise = 0,
    this.searchQuery = '',
    this.errorMessage,
  });

  final AccountingOverviewStatus status;
  final List<WorkerFinancialSummary> workerSummaries;
  final List<PaymentView> recentPayments;
  final List<LabourEntryView> labourEntries;
  final int totalEarnedPaise;
  final int totalOutstandingPaise;
  final int totalAdvanceCreditPaise;
  final int totalPaidPaise;
  final String searchQuery;
  final String? errorMessage;

  List<WorkerFinancialSummary> get filteredSummaries {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return workerSummaries;
    return workerSummaries
        .where(
          (w) =>
              w.workerName.toLowerCase().contains(q) ||
              (w.workerPhone?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  AccountingOverviewState copyWith({
    AccountingOverviewStatus? status,
    List<WorkerFinancialSummary>? workerSummaries,
    List<PaymentView>? recentPayments,
    List<LabourEntryView>? labourEntries,
    int? totalEarnedPaise,
    int? totalOutstandingPaise,
    int? totalAdvanceCreditPaise,
    int? totalPaidPaise,
    String? searchQuery,
    String? errorMessage,
  }) {
    return AccountingOverviewState(
      status: status ?? this.status,
      workerSummaries: workerSummaries ?? this.workerSummaries,
      recentPayments: recentPayments ?? this.recentPayments,
      labourEntries: labourEntries ?? this.labourEntries,
      totalEarnedPaise: totalEarnedPaise ?? this.totalEarnedPaise,
      totalOutstandingPaise:
          totalOutstandingPaise ?? this.totalOutstandingPaise,
      totalAdvanceCreditPaise:
          totalAdvanceCreditPaise ?? this.totalAdvanceCreditPaise,
      totalPaidPaise: totalPaidPaise ?? this.totalPaidPaise,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

@injectable
final class AccountingOverviewCubit extends Cubit<AccountingOverviewState> {
  AccountingOverviewCubit(this._repository)
    : super(const AccountingOverviewState());

  final AccountingRepository _repository;

  Future<void> load() async {
    if (state.status == AccountingOverviewStatus.initial ||
        state.status == AccountingOverviewStatus.error) {
      emit(state.copyWith(status: AccountingOverviewStatus.loading));
    }
    try {
      final results = await Future.wait([
        _repository.getAllWorkerSummaries(),
        _repository.getPayments(),
        _repository.getLabourEntries(),
      ]);
      if (isClosed) return;
      final summaries = results[0] as List<WorkerFinancialSummary>;
      var totalEarned = 0;
      var totalOutstanding = 0;
      var totalAdvanceCredit = 0;
      var totalPaid = 0;
      for (final w in summaries) {
        totalEarned += w.earnedLabourPaise;
        totalOutstanding += w.outstandingPayablePaise;
        totalAdvanceCredit += w.advanceCreditBalancePaise;
        totalPaid += w.netPaidToWorkerPaise;
      }
      emit(
        state.copyWith(
          status: AccountingOverviewStatus.loaded,
          workerSummaries: summaries,
          recentPayments: results[1] as List<PaymentView>,
          labourEntries: results[2] as List<LabourEntryView>,
          totalEarnedPaise: totalEarned,
          totalOutstandingPaise: totalOutstanding,
          totalAdvanceCreditPaise: totalAdvanceCredit,
          totalPaidPaise: totalPaid,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountingOverviewStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void updateSearch(String query) {
    if (query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: query));
  }
}
