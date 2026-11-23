import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum WorkerLedgerStatus { initial, loading, loaded, error }

final class WorkerLedgerState {
  const WorkerLedgerState({
    this.status = WorkerLedgerStatus.initial,
    this.detail,
    this.fromUtcMillis,
    this.toUtcMillis,
    this.dateRangeErrorCode,
    this.errorMessage,
  });

  final WorkerLedgerStatus status;
  final WorkerLedgerDetail? detail;
  final int? fromUtcMillis;
  final int? toUtcMillis;
  final String? dateRangeErrorCode;
  final String? errorMessage;

  WorkerLedgerState copyWith({
    WorkerLedgerStatus? status,
    WorkerLedgerDetail? detail,
    int? fromUtcMillis,
    int? toUtcMillis,
    bool clearFrom = false,
    bool clearTo = false,
    String? dateRangeErrorCode,
    bool clearDateRangeError = false,
    String? errorMessage,
  }) {
    return WorkerLedgerState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      fromUtcMillis: clearFrom ? null : (fromUtcMillis ?? this.fromUtcMillis),
      toUtcMillis: clearTo ? null : (toUtcMillis ?? this.toUtcMillis),
      dateRangeErrorCode: clearDateRangeError
          ? null
          : (dateRangeErrorCode ?? this.dateRangeErrorCode),
      errorMessage: errorMessage,
    );
  }
}

@injectable
final class WorkerLedgerCubit extends Cubit<WorkerLedgerState> {
  WorkerLedgerCubit(this._repository) : super(const WorkerLedgerState());

  final AccountingRepository _repository;
  String? _workerId;

  Future<void> loadLedger(
    String workerId, {
    int? fromUtcMillis,
    int? toUtcMillis,
    bool clearFrom = false,
    bool clearTo = false,
  }) async {
    _workerId = workerId;
    final effectiveFrom = clearFrom
        ? null
        : (fromUtcMillis ?? state.fromUtcMillis);
    final effectiveTo = clearTo ? null : (toUtcMillis ?? state.toUtcMillis);

    final rangeCheck = AppValidators.dateRangeValidator(
      startUtcMillis: effectiveFrom,
      endUtcMillis: effectiveTo,
    );
    if (!rangeCheck.isValid) {
      emit(state.copyWith(dateRangeErrorCode: 'invalid_date_range'));
      return;
    }

    emit(
      state.copyWith(
        status: WorkerLedgerStatus.loading,
        fromUtcMillis: effectiveFrom,
        toUtcMillis: effectiveTo,
        clearFrom: clearFrom,
        clearTo: clearTo,
        clearDateRangeError: true,
      ),
    );

    try {
      final detail = await _repository.getWorkerLedgerDetail(
        workerId,
        fromUtcMillis: effectiveFrom,
        toUtcMillis: effectiveTo,
      );
      if (detail == null) {
        emit(
          state.copyWith(
            status: WorkerLedgerStatus.error,
            errorMessage: 'Worker not found.',
          ),
        );
        return;
      }
      emit(state.copyWith(status: WorkerLedgerStatus.loaded, detail: detail));
    } catch (e) {
      emit(
        state.copyWith(
          status: WorkerLedgerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> reload() async {
    if (_workerId != null) {
      await loadLedger(_workerId!);
    }
  }
}
