import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/domain/repositories/process_routing_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum JobRoutingStatus { initial, loading, loaded, error }

final class JobRoutingState {
  const JobRoutingState({
    this.status = JobRoutingStatus.initial,
    this.overview,
    this.isSubmitting = false,
    this.errorMessage,
    this.feedbackMessage,
  });

  final JobRoutingStatus status;
  final JobRoutingOverview? overview;
  final bool isSubmitting;
  final String? errorMessage;
  final String? feedbackMessage;

  JobRoutingState copyWith({
    JobRoutingStatus? status,
    JobRoutingOverview? overview,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? feedbackMessage,
    bool clearFeedback = false,
  }) {
    return JobRoutingState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      feedbackMessage: clearFeedback
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }
}

/// BLoC / Cubit orchestrating Multi-Process operations, Direct Transfers,
/// Factory Returns, Reassignments, Dynamic Pricing, Additional Charges,
/// Payments, and Timeline history.
@injectable
final class JobRoutingCubit extends Cubit<JobRoutingState> {
  JobRoutingCubit(this._repo, this._idGenerator)
    : super(const JobRoutingState());

  final ProcessRoutingRepository _repo;
  final IdGenerator _idGenerator;

  String? _currentLotId;

  Future<void> load(String lotId) async {
    _currentLotId = lotId;
    emit(
      state.copyWith(
        status: state.overview == null
            ? JobRoutingStatus.loading
            : JobRoutingStatus.loaded,
        clearError: true,
      ),
    );
    try {
      final overview = await _repo.getJobRoutingOverview(lotId);
      if (overview == null) {
        emit(
          state.copyWith(
            status: JobRoutingStatus.error,
            errorMessage: 'job_not_found',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: JobRoutingStatus.loaded,
          overview: overview,
          isSubmitting: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: JobRoutingStatus.error,
          isSubmitting: false,
          errorMessage: _friendlyError(e),
        ),
      );
    }
  }

  Future<String?> addProcess({
    required String designColourId,
    required String processId,
    required String workerId,
    required int quantity,
    required bool dispatchImmediately,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
  }) async {
    final lotId = _currentLotId;
    if (lotId == null || state.isSubmitting) return 'not_ready';
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repo.addJobProcess(
        lotId: lotId,
        designColourId: designColourId,
        processId: processId,
        workerId: workerId,
        quantity: quantity,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        dispatchImmediately: dispatchImmediately,
        agreedRatePaise: agreedRatePaise,
        pricingUnit: pricingUnit,
        rateOverrideReason: rateOverrideReason,
        notes: notes,
        clientRequestId: _idGenerator.nextRequestId(),
      );
      await load(lotId);
      return null;
    } catch (e) {
      final msg = _friendlyError(e);
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return msg;
    }
  }

  Future<String?> editProcess({
    required String jobProcessId,
    String? workerId,
    int? plannedQuantity,
    String? notes,
  }) async {
    final lotId = _currentLotId;
    if (lotId == null || state.isSubmitting) return 'not_ready';
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repo.editJobProcess(
        jobProcessId: jobProcessId,
        workerId: workerId,
        plannedQuantity: plannedQuantity,
        notes: notes,
      );
      await load(lotId);
      return null;
    } catch (e) {
      final msg = _friendlyError(e);
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return msg;
    }
  }

  Future<String?> dispatchProcess({
    required String jobProcessId,
    required int quantity,
    String? notes,
  }) async {
    final lotId = _currentLotId;
    if (lotId == null || state.isSubmitting) return 'not_ready';
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repo.dispatchJobProcess(
        jobProcessId: jobProcessId,
        quantity: quantity,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        notes: notes,
        clientRequestId: _idGenerator.nextRequestId(),
      );
      await load(lotId);
      return null;
    } catch (e) {
      final msg = _friendlyError(e);
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return msg;
    }
  }

  Future<String?> confirmReceipt({
    required String handoverId,
    required int receivedQuantity,
  }) async {
    final lotId = _currentLotId;
    if (lotId == null || state.isSubmitting) return 'not_ready';
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repo.confirmHandoverReceipt(
        handoverId: handoverId,
        receivedQuantity: receivedQuantity,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      );
      await load(lotId);
      return null;
    } catch (e) {
      final msg = _friendlyError(e);
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return msg;
    }
  }

  Future<String?> directTransfer({
    required String sourceJobProcessId,
    required String destinationProcessId,
    required String destinationWorkerId,
    required int quantity,
    bool autoConfirmReceipt = false,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
  }) async {
    final lotId = _currentLotId;
    if (lotId == null || state.isSubmitting) return 'not_ready';
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repo.directTransfer(
        sourceJobProcessId: sourceJobProcessId,
        destinationProcessId: destinationProcessId,
        destinationWorkerId: destinationWorkerId,
        quantity: quantity,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        autoConfirmReceipt: autoConfirmReceipt,
        agreedRatePaise: agreedRatePaise,
        pricingUnit: pricingUnit,
        rateOverrideReason: rateOverrideReason,
        notes: notes,
        clientRequestId: _idGenerator.nextRequestId(),
      );
      await load(lotId);
      return null;
    } catch (e) {
      final msg = _friendlyError(e);
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return msg;
    }
  }

  Future<String?> returnToFactory({
    required String sourceJobProcessId,
    required int goodQuantity,
    int damagedQuantity = 0,
    String? reason,
    String? notes,
  }) async {
    final lotId = _currentLotId;
    if (lotId == null || state.isSubmitting) return 'not_ready';
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repo.returnToFactory(
        sourceJobProcessId: sourceJobProcessId,
        goodQuantity: goodQuantity,
        damagedQuantity: damagedQuantity,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        reason: reason,
        notes: notes,
        clientRequestId: _idGenerator.nextRequestId(),
      );
      await load(lotId);
      return null;
    } catch (e) {
      final msg = _friendlyError(e);
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return msg;
    }
  }

  Future<String?> reassignFromFactory({
    required String designColourId,
    required String targetProcessId,
    required String targetWorkerId,
    required int quantity,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
  }) async {
    final lotId = _currentLotId;
    if (lotId == null || state.isSubmitting) return 'not_ready';
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repo.reassignFromFactory(
        lotId: lotId,
        designColourId: designColourId,
        targetProcessId: targetProcessId,
        targetWorkerId: targetWorkerId,
        quantity: quantity,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        agreedRatePaise: agreedRatePaise,
        pricingUnit: pricingUnit,
        rateOverrideReason: rateOverrideReason,
        notes: notes,
        clientRequestId: _idGenerator.nextRequestId(),
      );
      await load(lotId);
      return null;
    } catch (e) {
      final msg = _friendlyError(e);
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return msg;
    }
  }

  Future<String?> addAdditionalCharge({
    required String jobProcessId,
    required ProcessChargeType chargeType,
    required String description,
    required int amountPaise,
  }) async {
    final lotId = _currentLotId;
    if (lotId == null || state.isSubmitting) return 'not_ready';
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repo.addAdditionalCharge(
        jobProcessId: jobProcessId,
        chargeType: chargeType,
        description: description,
        amountPaise: amountPaise,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        clientRequestId: _idGenerator.nextRequestId(),
      );
      await load(lotId);
      return null;
    } catch (e) {
      final msg = _friendlyError(e);
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return msg;
    }
  }

  Future<String?> markCompleted(String jobProcessId) async {
    final lotId = _currentLotId;
    if (lotId == null || state.isSubmitting) return 'not_ready';
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repo.markProcessCompleted(
        jobProcessId: jobProcessId,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      );
      await load(lotId);
      return null;
    } catch (e) {
      final msg = _friendlyError(e);
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return msg;
    }
  }

  Future<String?> cancelProcess({
    required String jobProcessId,
    required String reason,
  }) async {
    final lotId = _currentLotId;
    if (lotId == null || state.isSubmitting) return 'not_ready';
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repo.cancelJobProcess(
        jobProcessId: jobProcessId,
        reason: reason,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      );
      await load(lotId);
      return null;
    } catch (e) {
      final msg = _friendlyError(e);
      emit(state.copyWith(isSubmitting: false, errorMessage: msg));
      return msg;
    }
  }

  String _friendlyError(Object e) {
    return e is DomainValidationException ? e.code : e.toString();
  }
}
