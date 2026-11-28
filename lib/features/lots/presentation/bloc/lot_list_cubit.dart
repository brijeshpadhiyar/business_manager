import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'lot_list_cubit.freezed.dart';

enum LotListStatus { initial, loading, loaded, error }

@freezed
sealed class LotListState with _$LotListState {
  const factory LotListState({
    @Default(LotListStatus.initial) LotListStatus status,
    @Default([]) List<LotEntity> lots,
    @Default('') String searchQuery,
    LotStatus? statusFilter,
    String? errorMessage,
  }) = _LotListState;
}

@injectable
final class LotListCubit extends Cubit<LotListState> {
  LotListCubit(this._repository) : super(const LotListState());

  final LotRepository _repository;
  int _requestSeq = 0;

  Future<void> loadLots({
    String? searchQuery,
    LotStatus? statusFilter,
    bool clearStatusFilter = false,
  }) async {
    final seq = ++_requestSeq;
    final nextQuery = searchQuery ?? state.searchQuery;
    final nextStatus = clearStatusFilter
        ? null
        : (statusFilter ?? state.statusFilter);
    final showLoader =
        state.status == LotListStatus.initial ||
        state.status == LotListStatus.error;
    emit(
      state.copyWith(
        status: showLoader ? LotListStatus.loading : state.status,
        searchQuery: nextQuery,
        statusFilter: nextStatus,
        errorMessage: null,
      ),
    );
    try {
      final lots = await _repository.getLots(
        searchQuery: nextQuery,
        status: nextStatus,
      );
      if (seq != _requestSeq || isClosed) return;
      emit(state.copyWith(status: LotListStatus.loaded, lots: lots));
    } catch (e) {
      if (seq != _requestSeq || isClosed) return;
      emit(
        state.copyWith(status: LotListStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<String?> createLot({
    required String lotNumber,
    String? title,
    String? notes,
    required int transactionAtUtcMillis,
  }) async {
    try {
      await _repository.createLot(
        lotNumber: lotNumber,
        title: title,
        notes: notes,
        transactionAtUtcMillis: transactionAtUtcMillis,
      );
      await loadLots();
      return null;
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> unarchiveLot(String lotId) async {
    await _repository.unarchiveLot(lotId);
    await loadLots();
  }
}
