import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum StockMovementsStatus { initial, loading, loaded, error }

final class StockMovementsState {
  const StockMovementsState({
    this.status = StockMovementsStatus.initial,
    this.colourBalances = const [],
    this.openIssues = const [],
    this.history = const [],
    this.workerSummaries = const [],
    this.processSummaries = const [],
    this.filter = const StockMovementFilter(),
    this.errorMessage,
  });

  final StockMovementsStatus status;
  final List<DesignColourStockBalance> colourBalances;
  final List<OpenIssueSummary> openIssues;
  final List<StockMovementView> history;
  final List<WorkerStockSummary> workerSummaries;
  final List<ProcessStockSummary> processSummaries;
  final StockMovementFilter filter;
  final String? errorMessage;

  StockMovementsState copyWith({
    StockMovementsStatus? status,
    List<DesignColourStockBalance>? colourBalances,
    List<OpenIssueSummary>? openIssues,
    List<StockMovementView>? history,
    List<WorkerStockSummary>? workerSummaries,
    List<ProcessStockSummary>? processSummaries,
    StockMovementFilter? filter,
    String? errorMessage,
  }) {
    return StockMovementsState(
      status: status ?? this.status,
      colourBalances: colourBalances ?? this.colourBalances,
      openIssues: openIssues ?? this.openIssues,
      history: history ?? this.history,
      workerSummaries: workerSummaries ?? this.workerSummaries,
      processSummaries: processSummaries ?? this.processSummaries,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }
}

@injectable
final class StockMovementsCubit extends Cubit<StockMovementsState> {
  StockMovementsCubit(this._repository) : super(const StockMovementsState());

  final StockMovementRepository _repository;

  Future<void> loadAll({StockMovementFilter? filter}) async {
    final effectiveFilter = filter ?? state.filter;
    emit(
      state.copyWith(
        status: StockMovementsStatus.loading,
        filter: effectiveFilter,
      ),
    );
    try {
      final results = await Future.wait([
        _repository.getAllDesignColourBalances(lotId: effectiveFilter.lotId),
        _repository.getOpenIssues(
          lotId: effectiveFilter.lotId,
          workerId: effectiveFilter.memberId,
          processId: effectiveFilter.processId,
        ),
        _repository.getMovementHistory(filter: effectiveFilter),
        _repository.getWorkerStockSummaries(),
        _repository.getProcessStockSummaries(),
      ]);

      emit(
        state.copyWith(
          status: StockMovementsStatus.loaded,
          colourBalances: results[0] as List<DesignColourStockBalance>,
          openIssues: results[1] as List<OpenIssueSummary>,
          history: results[2] as List<StockMovementView>,
          workerSummaries: results[3] as List<WorkerStockSummary>,
          processSummaries: results[4] as List<ProcessStockSummary>,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StockMovementsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
