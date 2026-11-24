import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'process_list_cubit.freezed.dart';

enum ProcessListStatus { initial, loading, loaded, error }

@freezed
sealed class ProcessListState with _$ProcessListState {
  const factory ProcessListState({
    @Default(ProcessListStatus.initial) ProcessListStatus status,
    @Default([]) List<ProcessEntity> processes,
    @Default('') String searchQuery,
    bool? activeFilter,
    String? errorMessage,
  }) = _ProcessListState;
}

@injectable
final class ProcessListCubit extends Cubit<ProcessListState> {
  ProcessListCubit(this._repository) : super(const ProcessListState());

  final ProcessRepository _repository;
  int _requestSeq = 0;

  Future<void> loadProcesses({
    String? searchQuery,
    bool? activeFilter,
    bool clearActiveFilter = false,
  }) async {
    final seq = ++_requestSeq;
    final nextQuery = searchQuery ?? state.searchQuery;
    final nextFilter = clearActiveFilter
        ? null
        : (activeFilter ?? state.activeFilter);
    final showLoader =
        state.status == ProcessListStatus.initial ||
        state.status == ProcessListStatus.error;
    emit(
      state.copyWith(
        status: showLoader ? ProcessListStatus.loading : state.status,
        searchQuery: nextQuery,
        activeFilter: nextFilter,
        errorMessage: null,
      ),
    );
    try {
      final list = await _repository.getProcesses(
        searchQuery: nextQuery,
        isActiveFilter: nextFilter,
      );
      if (seq != _requestSeq || isClosed) return;
      emit(state.copyWith(status: ProcessListStatus.loaded, processes: list));
    } catch (e) {
      if (seq != _requestSeq || isClosed) return;
      emit(
        state.copyWith(
          status: ProcessListStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<String?> toggleActive(ProcessEntity process) async {
    try {
      await _repository.setProcessActive(
        processId: process.id,
        isActive: !process.isActive,
      );
      await loadProcesses();
      return null;
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }
}
