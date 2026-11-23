import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/rates/domain/repositories/rate_repository.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'rate_history_cubit.freezed.dart';

enum RateHistoryStatus { initial, loading, loaded, error }

@freezed
sealed class RateHistoryState with _$RateHistoryState {
  const factory RateHistoryState({
    @Default(RateHistoryStatus.initial) RateHistoryStatus status,
    WorkerEntity? worker,
    @Default([]) List<ProcessEntity> processes,
    String? selectedProcessId,
    @Default([]) List<MemberProcessRateEntity> rates,
    MemberProcessRateEntity? currentRate,
    String? errorMessage,
  }) = _RateHistoryState;
}

@injectable
final class RateHistoryCubit extends Cubit<RateHistoryState> {
  RateHistoryCubit(
    this._workerRepository,
    this._processRepository,
    this._rateRepository,
  ) : super(const RateHistoryState());

  final WorkerRepository _workerRepository;
  final ProcessRepository _processRepository;
  final RateRepository _rateRepository;

  Future<void> load({required String workerId, String? processId}) async {
    emit(state.copyWith(status: RateHistoryStatus.loading, errorMessage: null));
    try {
      final detail = await _workerRepository.getWorkerDetail(workerId);
      if (detail == null) {
        emit(
          state.copyWith(
            status: RateHistoryStatus.error,
            errorMessage: 'Worker not found.',
          ),
        );
        return;
      }

      final allProcesses = await _processRepository.getProcesses();
      final selectedProcId =
          processId ??
          state.selectedProcessId ??
          (detail.assignedProcesses.isNotEmpty
              ? detail.assignedProcesses.first.assignment.processId
              : (allProcesses.isNotEmpty ? allProcesses.first.id : null));

      List<MemberProcessRateEntity> rates = const [];
      MemberProcessRateEntity? currentRate;
      if (selectedProcId != null) {
        rates = await _rateRepository.getRateHistory(
          workerId: workerId,
          processId: selectedProcId,
        );
        final resolved = await _rateRepository.resolveRate(
          workerId: workerId,
          processId: selectedProcId,
          transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        );
        if (resolved is RateResolutionFound) {
          currentRate = resolved.rate;
        }
      }

      emit(
        state.copyWith(
          status: RateHistoryStatus.loaded,
          worker: detail.worker,
          processes: allProcesses,
          selectedProcessId: selectedProcId,
          rates: rates,
          currentRate: currentRate,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RateHistoryStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
