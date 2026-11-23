import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'process_detail_cubit.freezed.dart';

enum ProcessDetailStatus { initial, loading, loaded, error }

@freezed
sealed class ProcessDetailState with _$ProcessDetailState {
  const factory ProcessDetailState({
    @Default(ProcessDetailStatus.initial) ProcessDetailStatus status,
    ProcessDetailAggregate? detail,
    String? errorMessage,
  }) = _ProcessDetailState;
}

@injectable
final class ProcessDetailCubit extends Cubit<ProcessDetailState> {
  ProcessDetailCubit(this._repository) : super(const ProcessDetailState());

  final ProcessRepository _repository;

  Future<void> loadProcess(String processId) async {
    emit(
      state.copyWith(status: ProcessDetailStatus.loading, errorMessage: null),
    );
    try {
      final detail = await _repository.getProcessDetail(processId);
      if (detail == null) {
        emit(
          state.copyWith(
            status: ProcessDetailStatus.error,
            errorMessage: 'Process not found.',
          ),
        );
        return;
      }
      emit(state.copyWith(status: ProcessDetailStatus.loaded, detail: detail));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProcessDetailStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<String?> setActive(bool isActive) async {
    final current = state.detail;
    if (current == null) return null;
    try {
      await _repository.setProcessActive(
        processId: current.process.id,
        isActive: isActive,
      );
      await loadProcess(current.process.id);
      return null;
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }
}
