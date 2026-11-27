import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum PartiesStatus { initial, loading, loaded, error }

enum PartyListFilter { all, receivableDue, advanceCredit }

final class PartiesState {
  const PartiesState({
    this.status = PartiesStatus.initial,
    this.summaries = const [],
    this.searchQuery = '',
    this.filter = PartyListFilter.all,
    this.errorMessage,
  });

  final PartiesStatus status;
  final List<PartyFinancialSummary> summaries;
  final String searchQuery;
  final PartyListFilter filter;
  final String? errorMessage;

  int get totalReceivablePaise => summaries.fold<int>(
    0,
    (sum, s) => sum + s.outstandingReceivablePaise,
  );

  int get totalAdvanceCreditPaise =>
      summaries.fold<int>(0, (sum, s) => sum + s.advanceCreditPaise);

  List<PartyFinancialSummary> get filteredSummaries {
    final q = searchQuery.trim().toLowerCase();
    return summaries.where((s) {
      if (filter == PartyListFilter.receivableDue &&
          s.outstandingReceivablePaise <= 0) {
        return false;
      }
      if (filter == PartyListFilter.advanceCredit &&
          s.advanceCreditPaise <= 0) {
        return false;
      }
      if (q.isEmpty) return true;
      return s.partyName.toLowerCase().contains(q) ||
          (s.partyPhone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  PartiesState copyWith({
    PartiesStatus? status,
    List<PartyFinancialSummary>? summaries,
    String? searchQuery,
    PartyListFilter? filter,
    String? errorMessage,
  }) => PartiesState(
    status: status ?? this.status,
    summaries: summaries ?? this.summaries,
    searchQuery: searchQuery ?? this.searchQuery,
    filter: filter ?? this.filter,
    errorMessage: errorMessage,
  );
}

@injectable
final class PartiesCubit extends Cubit<PartiesState> {
  PartiesCubit(this._repo) : super(const PartiesState());

  final PartyRepository _repo;

  Future<void> loadParties() async {
    emit(state.copyWith(status: PartiesStatus.loading, errorMessage: null));
    try {
      final list = await _repo.getAllPartySummaries();
      emit(state.copyWith(status: PartiesStatus.loaded, summaries: list));
    } catch (e) {
      emit(
        state.copyWith(
          status: PartiesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setFilter(PartyListFilter filter) {
    emit(state.copyWith(filter: filter));
  }
}
