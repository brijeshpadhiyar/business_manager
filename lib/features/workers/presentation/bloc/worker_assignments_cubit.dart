import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'worker_assignments_cubit.freezed.dart';

enum WorkerAssignmentsStatus { initial, loading, loaded, error }

@freezed
sealed class WorkerAssignmentsState with _$WorkerAssignmentsState {
  const factory WorkerAssignmentsState({
    @Default(WorkerAssignmentsStatus.initial) WorkerAssignmentsStatus status,
    WorkerEntity? worker,
    @Default([]) List<WorkerProcessAssignmentEntity> assignments,
    @Default([]) List<ProcessEntity> activeProcesses,
    String? errorMessage,
  }) = _WorkerAssignmentsState;
}

@injectable
final class WorkerAssignmentsCubit extends Cubit<WorkerAssignmentsState> {
  WorkerAssignmentsCubit(this._workerRepository, this._processRepository)
    : super(const WorkerAssignmentsState());

  final WorkerRepository _workerRepository;
  final ProcessRepository _processRepository;

  Future<void> load(String workerId) async {
    emit(
      state.copyWith(
        status: WorkerAssignmentsStatus.loading,
        errorMessage: null,
      ),
    );
    try {
      final detail = await _workerRepository.getWorkerDetail(workerId);
      if (detail == null) {
        emit(
          state.copyWith(
            status: WorkerAssignmentsStatus.error,
            errorMessage: 'Worker not found.',
          ),
        );
        return;
      }
      final assignments = await _workerRepository.getAssignmentsForWorker(
        workerId,
        activeOnly: true,
      );
      final activeProcesses = await _processRepository.getProcesses(
        isActiveFilter: true,
      );
      emit(
        state.copyWith(
          status: WorkerAssignmentsStatus.loaded,
          worker: detail.worker,
          assignments: assignments,
          activeProcesses: activeProcesses,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: WorkerAssignmentsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<String?> assignProcess(String processId) async {
    final worker = state.worker;
    if (worker == null) return 'Worker not found.';
    try {
      await _workerRepository.assignProcessToWorker(
        workerId: worker.id,
        processId: processId,
      );
      await load(worker.id);
      return null;
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deactivateAssignment(String processId) async {
    final worker = state.worker;
    if (worker == null) return 'Worker not found.';
    try {
      await _workerRepository.deactivateAssignment(
        workerId: worker.id,
        processId: processId,
      );
      await load(worker.id);
      return null;
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }
}
