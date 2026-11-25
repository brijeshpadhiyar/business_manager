import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

final class ProcessHistoryState {
  const ProcessHistoryState({
    this.status = ProductionHistoryLoadStatus.initial,
    this.filter = const ProductionHistoryFilter(),
    this.processes = const [],
    this.selectedProcess,
    this.options = const ProductionHistoryFilterOptions(),
    this.errorMessage,
  });

  final ProductionHistoryLoadStatus status;
  final ProductionHistoryFilter filter;
  final List<ProcessCompleteHistory> processes;
  final ProcessCompleteHistory? selectedProcess;
  final ProductionHistoryFilterOptions options;
  final String? errorMessage;

  ProcessHistoryState copyWith({
    ProductionHistoryLoadStatus? status,
    ProductionHistoryFilter? filter,
    List<ProcessCompleteHistory>? processes,
    ProcessCompleteHistory? selectedProcess,
    ProductionHistoryFilterOptions? options,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProcessHistoryState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      processes: processes ?? this.processes,
      selectedProcess: selectedProcess ?? this.selectedProcess,
      options: options ?? this.options,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@injectable
final class ProcessHistoryCubit extends Cubit<ProcessHistoryState> {
  ProcessHistoryCubit(this._repo) : super(const ProcessHistoryState());

  final ProductionHistoryRepository _repo;

  Future<void> loadAll({ProductionHistoryFilter? filter}) async {
    final activeFilter = filter ?? state.filter;
    emit(
      state.copyWith(
        status: ProductionHistoryLoadStatus.loading,
        filter: activeFilter,
        clearError: true,
      ),
    );
    try {
      final results = await Future.wait([
        _repo.getAllProcessHistories(filter: activeFilter),
        _repo.getFilterOptions(),
      ]);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.loaded,
          processes: results[0] as List<ProcessCompleteHistory>,
          options: results[1] as ProductionHistoryFilterOptions,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadProcess(
    String processId, {
    ProductionHistoryFilter? filter,
  }) async {
    final activeFilter = (filter ?? state.filter).copyWith(processId: processId);
    emit(
      state.copyWith(
        status: ProductionHistoryLoadStatus.loading,
        filter: activeFilter,
        clearError: true,
      ),
    );
    try {
      final results = await Future.wait([
        _repo.getProcessCompleteHistory(processId, filter: activeFilter),
        _repo.getFilterOptions(),
      ]);
      if (isClosed) return;
      final detail = results[0] as ProcessCompleteHistory?;
      if (detail == null) {
        emit(
          state.copyWith(
            status: ProductionHistoryLoadStatus.error,
            errorMessage: 'Process not found.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.loaded,
          selectedProcess: detail,
          options: results[1] as ProductionHistoryFilterOptions,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
