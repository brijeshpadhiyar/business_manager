import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'worker_detail_cubit.freezed.dart';

enum WorkerDetailStatus { initial, loading, loaded, error }

@freezed
sealed class WorkerDetailState with _$WorkerDetailState {
  const factory WorkerDetailState({
    @Default(WorkerDetailStatus.initial) WorkerDetailStatus status,
    WorkerDetailAggregate? detail,
    String? errorMessage,
  }) = _WorkerDetailState;
}

@injectable
final class WorkerDetailCubit extends Cubit<WorkerDetailState> {
  WorkerDetailCubit(this._repository) : super(const WorkerDetailState());

  final WorkerRepository _repository;

  Future<void> loadWorker(String workerId) async {
    emit(
      state.copyWith(status: WorkerDetailStatus.loading, errorMessage: null),
    );
    try {
      final detail = await _repository.getWorkerDetail(workerId);
      if (detail == null) {
        emit(
          state.copyWith(
            status: WorkerDetailStatus.error,
            errorMessage: 'Worker not found.',
          ),
        );
        return;
      }
      emit(state.copyWith(status: WorkerDetailStatus.loaded, detail: detail));
    } catch (e) {
      emit(
        state.copyWith(
          status: WorkerDetailStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<String?> setActive(bool isActive) async {
    final current = state.detail;
    if (current == null) return null;
    try {
      await _repository.setWorkerActive(
        workerId: current.worker.id,
        isActive: isActive,
      );
      await loadWorker(current.worker.id);
      return null;
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }
}
