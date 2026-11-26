import 'package:business_manager/features/backup/data/services/data_health_service.dart';
import 'package:business_manager/features/backup/domain/entities/data_health_entities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@immutable
final class DataHealthState {
  const DataHealthState({
    this.isLoading = false,
    this.isMaintenanceBusy = false,
    this.report,
    this.errorMessage,
    this.lastActionMessage,
  });

  final bool isLoading;
  final bool isMaintenanceBusy;
  final DataHealthReport? report;
  final String? errorMessage;
  final String? lastActionMessage;

  DataHealthState copyWith({
    bool? isLoading,
    bool? isMaintenanceBusy,
    DataHealthReport? report,
    String? errorMessage,
    bool clearError = false,
    String? lastActionMessage,
    bool clearActionMessage = false,
  }) {
    return DataHealthState(
      isLoading: isLoading ?? this.isLoading,
      isMaintenanceBusy: isMaintenanceBusy ?? this.isMaintenanceBusy,
      report: report ?? this.report,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastActionMessage: clearActionMessage
          ? null
          : (lastActionMessage ?? this.lastActionMessage),
    );
  }
}

@injectable
final class DataHealthCubit extends Cubit<DataHealthState> {
  DataHealthCubit(this._service) : super(const DataHealthState());

  final DataHealthService _service;

  Future<void> runDiagnostics() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final report = await _service.runFullDiagnostics();
      emit(state.copyWith(isLoading: false, report: report));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> runWalCheckpoint() async {
    emit(
      state.copyWith(
        isMaintenanceBusy: true,
        clearError: true,
        clearActionMessage: true,
      ),
    );
    try {
      await _service.runWalCheckpoint();
      final report = await _service.runFullDiagnostics();
      emit(
        state.copyWith(
          isMaintenanceBusy: false,
          report: report,
          lastActionMessage: 'wal_checkpoint',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isMaintenanceBusy: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<int> cleanOrphanMedia() async {
    emit(
      state.copyWith(
        isMaintenanceBusy: true,
        clearError: true,
        clearActionMessage: true,
      ),
    );
    try {
      final deleted = await _service.cleanOrphanMediaFiles();
      final report = await _service.runFullDiagnostics();
      emit(
        state.copyWith(
          isMaintenanceBusy: false,
          report: report,
          lastActionMessage: 'orphan_clean:$deleted',
        ),
      );
      return deleted;
    } catch (error) {
      emit(
        state.copyWith(
          isMaintenanceBusy: false,
          errorMessage: error.toString(),
        ),
      );
      return 0;
    }
  }

  Future<int> retryFailedSync() async {
    emit(
      state.copyWith(
        isMaintenanceBusy: true,
        clearError: true,
        clearActionMessage: true,
      ),
    );
    try {
      final reset = await _service.retryFailedSyncEntries();
      final report = await _service.runFullDiagnostics();
      emit(
        state.copyWith(
          isMaintenanceBusy: false,
          report: report,
          lastActionMessage: 'sync_retry:$reset',
        ),
      );
      return reset;
    } catch (error) {
      emit(
        state.copyWith(
          isMaintenanceBusy: false,
          errorMessage: error.toString(),
        ),
      );
      return 0;
    }
  }

  String? buildExportText() {
    final r = state.report;
    if (r == null) return null;
    return _service.formatExportText(r);
  }
}
