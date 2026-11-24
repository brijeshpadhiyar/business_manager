import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

final class TransactionDetailState {
  const TransactionDetailState({
    this.status = ProductionHistoryLoadStatus.initial,
    this.detail,
    this.errorMessage,
  });

  final ProductionHistoryLoadStatus status;
  final ProductionTransactionDetail? detail;
  final String? errorMessage;

  TransactionDetailState copyWith({
    ProductionHistoryLoadStatus? status,
    ProductionTransactionDetail? detail,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransactionDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@injectable
final class TransactionDetailCubit extends Cubit<TransactionDetailState> {
  TransactionDetailCubit(this._repo) : super(const TransactionDetailState());

  final ProductionHistoryRepository _repo;

  Future<void> load({
    required ProductionTransactionKind kind,
    required String id,
  }) async {
    emit(
      state.copyWith(
        status: ProductionHistoryLoadStatus.loading,
        clearError: true,
      ),
    );
    try {
      final detail = await _repo.getTransactionDetail(kind: kind, id: id);
      if (isClosed) return;
      if (detail == null) {
        emit(
          state.copyWith(
            status: ProductionHistoryLoadStatus.error,
            errorMessage: 'Transaction not found.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.loaded,
          detail: detail,
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
