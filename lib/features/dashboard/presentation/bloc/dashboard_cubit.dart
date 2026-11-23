import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/domain/repositories/reports_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum DashboardStatus { initial, loading, loaded, error }

final class DashboardState {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.snapshot,
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardSnapshot? snapshot;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSnapshot? snapshot,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: errorMessage,
    );
  }
}

@injectable
final class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardState());

  final ReportsRepository _repository;

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final snapshot = await _repository.getDashboardSnapshot();
      emit(state.copyWith(status: DashboardStatus.loaded, snapshot: snapshot));
    } catch (e) {
      emit(
        state.copyWith(
          status: DashboardStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
