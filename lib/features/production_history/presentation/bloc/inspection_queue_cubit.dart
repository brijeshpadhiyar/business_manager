import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

final class InspectionQueueState {
  const InspectionQueueState({
    this.status = ProductionHistoryLoadStatus.initial,
    this.pendingReturns = const [],
    this.rejections = const [],
    this.showOnlyOpenRejections = true,
    this.busy = false,
    this.errorMessage,
  });

  final ProductionHistoryLoadStatus status;
  final List<PendingReturnView> pendingReturns;
  final List<RejectionRecordView> rejections;
  final bool showOnlyOpenRejections;
  final bool busy;
  final String? errorMessage;

  InspectionQueueState copyWith({
    ProductionHistoryLoadStatus? status,
    List<PendingReturnView>? pendingReturns,
    List<RejectionRecordView>? rejections,
    bool? showOnlyOpenRejections,
    bool? busy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InspectionQueueState(
      status: status ?? this.status,
      pendingReturns: pendingReturns ?? this.pendingReturns,
      rejections: rejections ?? this.rejections,
      showOnlyOpenRejections:
          showOnlyOpenRejections ?? this.showOnlyOpenRejections,
      busy: busy ?? this.busy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@injectable
final class InspectionQueueCubit extends Cubit<InspectionQueueState> {
  InspectionQueueCubit(this._repo) : super(const InspectionQueueState());

  final ProductionHistoryRepository _repo;

  Future<void> load({bool? onlyOpenRejections}) async {
    final onlyOpen = onlyOpenRejections ?? state.showOnlyOpenRejections;
    emit(
      state.copyWith(
        status: ProductionHistoryLoadStatus.loading,
        showOnlyOpenRejections: onlyOpen,
        clearError: true,
      ),
    );
    try {
      final results = await Future.wait([
        _repo.getPendingReturns(),
        _repo.getRejectionRecords(onlyOpen: onlyOpen),
      ]);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductionHistoryLoadStatus.loaded,
          pendingReturns: results[0] as List<PendingReturnView>,
          rejections: results[1] as List<RejectionRecordView>,
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

  Future<String?> approveReturn({
    required String productionReturnId,
    required int acceptedQuantity,
    required int rejectedQuantity,
    String? rejectionReason,
    String? notes,
    String? approvedBy,
    required bool authorizedViaPin,
    String? clientRequestId,
  }) async {
    emit(state.copyWith(busy: true));
    try {
      await _repo.approveReturnInspection(
        productionReturnId: productionReturnId,
        acceptedQuantity: acceptedQuantity,
        rejectedQuantity: rejectedQuantity,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        rejectionReason: rejectionReason,
        notes: notes,
        inspectedBy: approvedBy,
        approvedBy: approvedBy,
        authorizedViaPin: authorizedViaPin,
        clientRequestId: clientRequestId,
      );
      await load();
      if (!isClosed) emit(state.copyWith(busy: false));
      return null;
    } on DomainValidationException catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return e.code;
    } catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return e.toString();
    }
  }

  Future<String?> recordRepair({
    required String rejectionRecordId,
    required int repairedQuantity,
    required RepairSource repairSource,
    String? notes,
    String? clientRequestId,
  }) async {
    emit(state.copyWith(busy: true));
    try {
      await _repo.recordRejectionRepair(
        rejectionRecordId: rejectionRecordId,
        repairedQuantity: repairedQuantity,
        repairSource: repairSource,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        notes: notes,
        clientRequestId: clientRequestId,
      );
      await load();
      if (!isClosed) emit(state.copyWith(busy: false));
      return null;
    } on DomainValidationException catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return e.code;
    } catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return e.toString();
    }
  }

  Future<String?> approveReinspection({
    required String rejectionRepairId,
    required int acceptedQuantity,
    required int rejectedAgainQuantity,
    String? rejectionReason,
    String? notes,
    String? approvedBy,
    required bool authorizedViaPin,
    String? clientRequestId,
  }) async {
    emit(state.copyWith(busy: true));
    try {
      await _repo.approveRepairReinspection(
        rejectionRepairId: rejectionRepairId,
        acceptedQuantity: acceptedQuantity,
        rejectedAgainQuantity: rejectedAgainQuantity,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        rejectionReason: rejectionReason,
        notes: notes,
        inspectedBy: approvedBy,
        approvedBy: approvedBy,
        authorizedViaPin: authorizedViaPin,
        clientRequestId: clientRequestId,
      );
      await load();
      if (!isClosed) emit(state.copyWith(busy: false));
      return null;
    } on DomainValidationException catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return e.code;
    } catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return e.toString();
    }
  }
}
