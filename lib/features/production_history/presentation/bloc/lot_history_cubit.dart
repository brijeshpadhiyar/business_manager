import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

final class LotHistoryState {
  const LotHistoryState({
    this.status = ProductionHistoryLoadStatus.initial,
    this.history,
    this.errorMessage,
  });

  final ProductionHistoryLoadStatus status;
  final LotCompleteHistory? history;
  final String? errorMessage;

  LotHistoryState copyWith({
    ProductionHistoryLoadStatus? status,
    LotCompleteHistory? history,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LotHistoryState(
      status: status ?? this.status,
      history: history ?? this.history,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@injectable
final class LotHistoryCubit extends Cubit<LotHistoryState> {
  LotHistoryCubit(this._repo) : super(const LotHistoryState());

  final ProductionHistoryRepository _repo;

  Future<void> loadLot(String lotId) async {
    emit(
      state.copyWith(
        status: ProductionHistoryLoadStatus.loading,
        clearError: true,
      ),
    );
    try {
      final history = await _repo.getLotCompleteHistory(lotId);
      if (isClosed) return;
      if (history == null) {
        emit(
          state.copyWith(
            status: ProductionHistoryLoadStatus.error,
            errorMessage: 'Lot not found.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.loaded,
          history: history,
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
