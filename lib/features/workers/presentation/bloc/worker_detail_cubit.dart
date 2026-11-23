import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
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
    WorkerLedgerDetail? ledgerDetail,
    @Default([]) List<OpenIssueSummary> openIssues,
    String? errorMessage,
  }) = _WorkerDetailState;
}

@injectable
final class WorkerDetailCubit extends Cubit<WorkerDetailState> {
  WorkerDetailCubit(
    this._repository,
    this._accountingRepository,
    this._stockMovementRepository,
  ) : super(const WorkerDetailState());

  final WorkerRepository _repository;
  final AccountingRepository _accountingRepository;
  final StockMovementRepository _stockMovementRepository;

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
      final results = await Future.wait([
        _accountingRepository.getWorkerLedgerDetail(workerId),
        _stockMovementRepository.getOpenIssues(workerId: workerId),
      ]);
      final ledger = results[0] as WorkerLedgerDetail?;
      final openIssues = results[1] as List<OpenIssueSummary>;

      emit(
        state.copyWith(
          status: WorkerDetailStatus.loaded,
          detail: detail,
          ledgerDetail: ledger,
          openIssues: openIssues,
        ),
      );
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
