import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/reports/domain/repositories/reports_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum DashboardStatus { initial, loading, loaded, error }

final class DashboardState {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.snapshot,
    this.errorMessage,
    this.weekTrend = const [],
  });

  final DashboardStatus status;
  final DashboardSnapshot? snapshot;
  final String? errorMessage;

  /// Daily issued vs good-returned points for this IST week (chart).
  final List<ProductionTrendPoint> weekTrend;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSnapshot? snapshot,
    String? errorMessage,
    List<ProductionTrendPoint>? weekTrend,
  }) {
    return DashboardState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: errorMessage,
      weekTrend: weekTrend ?? this.weekTrend,
    );
  }
}

@injectable
final class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardState());

  final ReportsRepository _repository;

  Future<void> loadDashboard() async {
    if (state.snapshot == null) {
      emit(state.copyWith(status: DashboardStatus.loading));
    }
    try {
      final snapshot = await _repository.getDashboardSnapshot();
      if (isClosed) return;
      emit(state.copyWith(status: DashboardStatus.loaded, snapshot: snapshot));
      await _loadWeekTrend();
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: DashboardStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// The chart is a nice-to-have: if it fails, the dashboard still works.
  Future<void> _loadWeekTrend() async {
    try {
      final bundle = await _repository.getAdvancedReports(
        ReportFilter.forPreset(ReportDatePreset.thisWeek),
      );
      if (isClosed) return;
      emit(state.copyWith(weekTrend: bundle.insights.trendPoints));
    } catch (_) {
      // Keep the previous chart (or none).
    }
  }
}
