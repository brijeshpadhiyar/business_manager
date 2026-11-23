import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/domain/repositories/reports_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum ReportsStatus { initial, loading, loaded, error }

final class ReportsState {
  const ReportsState({
    this.status = ReportsStatus.initial,
    this.bundle,
    this.fromUtcMillis,
    this.toUtcMillis,
    this.lotId,
    this.workerId,
    this.processId,
    this.searchQuery = '',
    this.errorMessage,
  });

  final ReportsStatus status;
  final BusinessReportsBundle? bundle;
  final int? fromUtcMillis;
  final int? toUtcMillis;
  final String? lotId;
  final String? workerId;
  final String? processId;
  final String searchQuery;
  final String? errorMessage;

  ReportsState copyWith({
    ReportsStatus? status,
    BusinessReportsBundle? bundle,
    int? fromUtcMillis,
    int? toUtcMillis,
    String? lotId,
    String? workerId,
    String? processId,
    String? searchQuery,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearLot = false,
    bool clearWorker = false,
    bool clearProcess = false,
    String? errorMessage,
  }) {
    return ReportsState(
      status: status ?? this.status,
      bundle: bundle ?? this.bundle,
      fromUtcMillis: clearFrom ? null : (fromUtcMillis ?? this.fromUtcMillis),
      toUtcMillis: clearTo ? null : (toUtcMillis ?? this.toUtcMillis),
      lotId: clearLot ? null : (lotId ?? this.lotId),
      workerId: clearWorker ? null : (workerId ?? this.workerId),
      processId: clearProcess ? null : (processId ?? this.processId),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

@injectable
final class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._repository) : super(const ReportsState());

  final ReportsRepository _repository;

  Future<void> loadReports({
    int? fromUtcMillis,
    int? toUtcMillis,
    String? lotId,
    String? workerId,
    String? processId,
    String? searchQuery,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearLot = false,
    bool clearWorker = false,
    bool clearProcess = false,
  }) async {
    final next = state.copyWith(
      status: ReportsStatus.loading,
      fromUtcMillis: fromUtcMillis,
      toUtcMillis: toUtcMillis,
      lotId: lotId,
      workerId: workerId,
      processId: processId,
      searchQuery: searchQuery,
      clearFrom: clearFrom,
      clearTo: clearTo,
      clearLot: clearLot,
      clearWorker: clearWorker,
      clearProcess: clearProcess,
    );
    emit(next);
    try {
      final bundle = await _repository.getBusinessReports(
        fromUtcMillis: next.fromUtcMillis,
        toUtcMillis: next.toUtcMillis,
        lotId: next.lotId,
        workerId: next.workerId,
        processId: next.processId,
        searchQuery: next.searchQuery,
      );
      emit(next.copyWith(status: ReportsStatus.loaded, bundle: bundle));
    } catch (e) {
      emit(
        next.copyWith(status: ReportsStatus.error, errorMessage: e.toString()),
      );
    }
  }
}
