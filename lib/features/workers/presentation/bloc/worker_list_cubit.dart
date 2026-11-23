import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'worker_list_cubit.freezed.dart';

enum WorkerListStatus { initial, loading, loaded, error }

@freezed
sealed class WorkerListState with _$WorkerListState {
  const factory WorkerListState({
    @Default(WorkerListStatus.initial) WorkerListStatus status,
    @Default([]) List<WorkerEntity> workers,
    @Default('') String searchQuery,
    bool? activeFilter,
    String? errorMessage,
  }) = _WorkerListState;
}

@injectable
final class WorkerListCubit extends Cubit<WorkerListState> {
  WorkerListCubit(this._repository) : super(const WorkerListState());

  final WorkerRepository _repository;

  Future<void> loadWorkers({
    String? searchQuery,
    bool? activeFilter,
    bool clearActiveFilter = false,
  }) async {
    final nextQuery = searchQuery ?? state.searchQuery;
    final nextFilter = clearActiveFilter
        ? null
        : (activeFilter ?? state.activeFilter);
    emit(
      state.copyWith(
        status: WorkerListStatus.loading,
        searchQuery: nextQuery,
        activeFilter: nextFilter,
        errorMessage: null,
      ),
    );
    try {
      final list = await _repository.getWorkers(
        searchQuery: nextQuery,
        isActiveFilter: nextFilter,
      );
      emit(state.copyWith(status: WorkerListStatus.loaded, workers: list));
    } catch (e) {
      emit(
        state.copyWith(
          status: WorkerListStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<String?> toggleActive(WorkerEntity worker) async {
    try {
      await _repository.setWorkerActive(
        workerId: worker.id,
        isActive: !worker.isActive,
      );
      await loadWorkers();
      return null;
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }
}
