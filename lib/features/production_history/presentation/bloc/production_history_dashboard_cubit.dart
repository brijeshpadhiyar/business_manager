import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum ProductionHistoryLoadStatus { initial, loading, loaded, error }

final class ProductionHistoryDashboardState {
  const ProductionHistoryDashboardState({
    this.status = ProductionHistoryLoadStatus.initial,
    this.filter = const ProductionHistoryFilter(),
    this.data,
    this.options = const ProductionHistoryFilterOptions(),
    this.errorMessage,
  });

  final ProductionHistoryLoadStatus status;
  final ProductionHistoryFilter filter;
  final ProductionHistoryDashboardData? data;
  final ProductionHistoryFilterOptions options;
  final String? errorMessage;

  ProductionHistoryDashboardState copyWith({
    ProductionHistoryLoadStatus? status,
    ProductionHistoryFilter? filter,
    ProductionHistoryDashboardData? data,
    ProductionHistoryFilterOptions? options,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductionHistoryDashboardState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      data: data ?? this.data,
      options: options ?? this.options,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@injectable
final class ProductionHistoryDashboardCubit
    extends Cubit<ProductionHistoryDashboardState> {
  ProductionHistoryDashboardCubit(this._repo)
    : super(const ProductionHistoryDashboardState());

  final ProductionHistoryRepository _repo;

  Future<void> load({ProductionHistoryFilter? filter}) async {
    final activeFilter = filter ?? state.filter;
    emit(
      state.copyWith(
        status: ProductionHistoryLoadStatus.loading,
        filter: activeFilter,
        clearError: true,
      ),
    );
    try {
      final results = await Future.wait([
        _repo.getDashboard(filter: activeFilter),
        _repo.getFilterOptions(),
      ]);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.loaded,
          data: results[0] as ProductionHistoryDashboardData,
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

  Future<void> updateFilter(ProductionHistoryFilter next) {
    return load(filter: next.copyWith(page: 0));
  }

  Future<void> nextPage() {
    if (!(state.data?.hasMore ?? false)) return Future.value();
    return load(filter: state.filter.copyWith(page: state.filter.page + 1));
  }

  Future<void> previousPage() {
    if (state.filter.page <= 0) return Future.value();
    return load(filter: state.filter.copyWith(page: state.filter.page - 1));
  }

  Future<void> clearFilters() => load(filter: const ProductionHistoryFilter());
}
