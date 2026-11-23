import 'package:business_manager/features/inventory/domain/calculators/inventory_overview_calculator.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'inventory_overview_cubit.freezed.dart';

enum InventoryOverviewStatus { initial, loading, loaded, error }

@freezed
sealed class InventoryOverviewState with _$InventoryOverviewState {
  const factory InventoryOverviewState({
    @Default(InventoryOverviewStatus.initial) InventoryOverviewStatus status,
    InventoryOverview? overview,
    String? errorMessage,
  }) = _InventoryOverviewState;
}

@injectable
final class InventoryOverviewCubit extends Cubit<InventoryOverviewState> {
  InventoryOverviewCubit(this._lotRepository)
    : super(const InventoryOverviewState());

  final LotRepository _lotRepository;

  Future<void> loadOverview() async {
    emit(
      state.copyWith(
        status: InventoryOverviewStatus.loading,
        errorMessage: null,
      ),
    );
    try {
      final activeLots = await _lotRepository.getAllActiveLots();
      final activeDesigns = await _lotRepository.getAllActiveDesigns();
      final activeColours = await _lotRepository.getAllActiveDesignColours();
      final overview = InventoryOverviewCalculator.calculate(
        activeLots: activeLots,
        activeDesigns: activeDesigns,
        activeColours: activeColours,
      );
      emit(
        state.copyWith(
          status: InventoryOverviewStatus.loaded,
          overview: overview,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InventoryOverviewStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
