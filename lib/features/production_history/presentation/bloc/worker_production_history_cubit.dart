import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

final class WorkerProductionHistoryState {
  const WorkerProductionHistoryState({
    this.status = ProductionHistoryLoadStatus.initial,
    this.filter = const ProductionHistoryFilter(),
    this.profiles = const [],
    this.selectedProfile,
    this.options = const ProductionHistoryFilterOptions(),
    this.includeInactive = true,
    this.errorMessage,
  });

  final ProductionHistoryLoadStatus status;
  final ProductionHistoryFilter filter;
  final List<WorkerCompleteProfile> profiles;
  final WorkerCompleteProfile? selectedProfile;
  final ProductionHistoryFilterOptions options;
  final bool includeInactive;
  final String? errorMessage;

  WorkerProductionHistoryState copyWith({
    ProductionHistoryLoadStatus? status,
    ProductionHistoryFilter? filter,
    List<WorkerCompleteProfile>? profiles,
    WorkerCompleteProfile? selectedProfile,
    ProductionHistoryFilterOptions? options,
    bool? includeInactive,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WorkerProductionHistoryState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      profiles: profiles ?? this.profiles,
      selectedProfile: selectedProfile ?? this.selectedProfile,
      options: options ?? this.options,
      includeInactive: includeInactive ?? this.includeInactive,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@injectable
final class WorkerProductionHistoryCubit
    extends Cubit<WorkerProductionHistoryState> {
  WorkerProductionHistoryCubit(this._repo)
      : super(const WorkerProductionHistoryState());

  final ProductionHistoryRepository _repo;

  Future<void> loadAll({
    ProductionHistoryFilter? filter,
    bool? includeInactive,
  }) async {
    final activeFilter = filter ?? state.filter;
    final showInactive = includeInactive ?? state.includeInactive;
    emit(
      state.copyWith(
        status: ProductionHistoryLoadStatus.loading,
        filter: activeFilter,
        includeInactive: showInactive,
        clearError: true,
      ),
    );
    try {
      final results = await Future.wait([
        _repo.getAllWorkerProfiles(filter: activeFilter),
        _repo.getFilterOptions(),
      ]);
      if (isClosed) return;
      final allProfiles = results[0] as List<WorkerCompleteProfile>;
      final filtered = showInactive
          ? allProfiles
          : allProfiles.where((p) => p.isActive).toList();
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.loaded,
          profiles: filtered,
          options: results[1] as ProductionHistoryFilterOptions,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadWorker(
    String workerId, {
    ProductionHistoryFilter? filter,
  }) async {
    emit(
      state.copyWith(
        status: ProductionHistoryLoadStatus.loading,
        clearError: true,
      ),
    );
    try {
      final profile = await _repo.getWorkerCompleteProfile(
        workerId,
        filter: filter,
      );
      if (isClosed) return;
      if (profile == null) {
        emit(
          state.copyWith(
            status: ProductionHistoryLoadStatus.error,
            errorMessage: 'Worker not found.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.loaded,
          selectedProfile: profile,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
