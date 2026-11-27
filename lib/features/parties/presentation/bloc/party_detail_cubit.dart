import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum PartyDetailStatus { initial, loading, loaded, error }

final class PartyDetailState {
  const PartyDetailState({
    this.status = PartyDetailStatus.initial,
    this.detail,
    this.errorMessage,
  });

  final PartyDetailStatus status;
  final PartyLedgerDetail? detail;
  final String? errorMessage;

  PartyDetailState copyWith({
    PartyDetailStatus? status,
    PartyLedgerDetail? detail,
    String? errorMessage,
  }) => PartyDetailState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    errorMessage: errorMessage,
  );
}

@injectable
final class PartyDetailCubit extends Cubit<PartyDetailState> {
  PartyDetailCubit(this._repo) : super(const PartyDetailState());

  final PartyRepository _repo;

  Future<void> loadParty(String partyId) async {
    emit(state.copyWith(status: PartyDetailStatus.loading, errorMessage: null));
    try {
      final detail = await _repo.getPartyLedgerDetail(partyId);
      if (detail == null) {
        emit(
          state.copyWith(
            status: PartyDetailStatus.error,
            errorMessage: 'party_not_found',
          ),
        );
        return;
      }
      emit(state.copyWith(status: PartyDetailStatus.loaded, detail: detail));
    } catch (e) {
      emit(
        state.copyWith(
          status: PartyDetailStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> reversePayment({
    required String partyId,
    required String paymentId,
    required String reason,
  }) async {
    await _repo.reversePartyPayment(paymentId: paymentId, reason: reason);
    await loadParty(partyId);
  }

  Future<void> reverseBuyerReturn({
    required String partyId,
    required String buyerReturnId,
    required String reason,
  }) async {
    await _repo.reverseBuyerReturn(buyerReturnId: buyerReturnId, reason: reason);
    await loadParty(partyId);
  }
}
