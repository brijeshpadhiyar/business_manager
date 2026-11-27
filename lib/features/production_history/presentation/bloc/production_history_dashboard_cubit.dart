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
    this.isLoadingMore = false,
  });

  final ProductionHistoryLoadStatus status;
  final ProductionHistoryFilter filter;
  final ProductionHistoryDashboardData? data;
  final ProductionHistoryFilterOptions options;
  final String? errorMessage;

  /// A next page is being fetched for the infinite-scroll feed.
  final bool isLoadingMore;

  ProductionHistoryDashboardState copyWith({
    ProductionHistoryLoadStatus? status,
    ProductionHistoryFilter? filter,
    ProductionHistoryDashboardData? data,
    ProductionHistoryFilterOptions? options,
    String? errorMessage,
    bool clearError = false,
    bool? isLoadingMore,
  }) {
    return ProductionHistoryDashboardState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      data: data ?? this.data,
      options: options ?? this.options,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

@injectable
final class ProductionHistoryDashboardCubit
    extends Cubit<ProductionHistoryDashboardState> {
  ProductionHistoryDashboardCubit(this._repo)
    : super(const ProductionHistoryDashboardState());

  final ProductionHistoryRepository _repo;

  /// Loads the first page (a refresh always starts the feed from the top).
  Future<void> load({ProductionHistoryFilter? filter}) async {
    final activeFilter = filter ?? state.filter.copyWith(page: 0);
    emit(
      state.copyWith(
        status: ProductionHistoryLoadStatus.loading,
        filter: activeFilter,
        clearError: true,
        isLoadingMore: false,
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

  /// Appends the next page to the feed (infinite scroll). Safe to call
  /// repeatedly: it ignores calls while a load is running or at the end.
  Future<void> loadMore() async {
    final data = state.data;
    if (data == null ||
        !data.hasMore ||
        state.isLoadingMore ||
        state.status == ProductionHistoryLoadStatus.loading) {
      return;
    }
    final nextFilter = state.filter.copyWith(page: state.filter.page + 1);
    emit(state.copyWith(isLoadingMore: true));
    try {
      final next = await _repo.getDashboard(filter: nextFilter);
      if (isClosed) return;
      emit(
        state.copyWith(
          filter: nextFilter,
          data: data.appendPage(next),
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      // Keep the rows already shown; the user can scroll again to retry.
      emit(state.copyWith(isLoadingMore: false, errorMessage: e.toString()));
    }
  }

  Future<void> clearFilters() => load(filter: const ProductionHistoryFilter());
}
