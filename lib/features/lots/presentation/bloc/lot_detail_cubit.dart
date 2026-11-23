import 'dart:typed_data';

import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'lot_detail_cubit.freezed.dart';

enum LotDetailStatus { initial, loading, loaded, error }

@freezed
sealed class LotDetailState with _$LotDetailState {
  const factory LotDetailState({
    @Default(LotDetailStatus.initial) LotDetailStatus status,
    LotDetailAggregate? detail,
    @Default('') String designSearchQuery,
    String? errorMessage,
  }) = _LotDetailState;
}

@injectable
final class LotDetailCubit extends Cubit<LotDetailState> {
  LotDetailCubit(this._repository) : super(const LotDetailState());

  final LotRepository _repository;

  Future<void> loadLot(String lotId) async {
    emit(state.copyWith(status: LotDetailStatus.loading, errorMessage: null));
    try {
      final detail = await _repository.getLotDetail(lotId);
      if (detail == null) {
        emit(
          state.copyWith(
            status: LotDetailStatus.error,
            errorMessage: 'Lot not found.',
          ),
        );
        return;
      }
      emit(state.copyWith(status: LotDetailStatus.loaded, detail: detail));
    } catch (e) {
      emit(
        state.copyWith(
          status: LotDetailStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void setDesignSearch(String query) {
    emit(state.copyWith(designSearchQuery: query));
  }

  Future<String?> updateLot({
    required String lotId,
    required String lotNumber,
    String? title,
    String? notes,
    required LotStatus status,
    required int transactionAtUtcMillis,
  }) async {
    try {
      await _repository.updateLot(
        lotId: lotId,
        lotNumber: lotNumber,
        title: title,
        notes: notes,
        status: status,
        transactionAtUtcMillis: transactionAtUtcMillis,
      );
      await loadLot(lotId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> archiveLot(String lotId) async {
    await _repository.archiveLot(lotId);
  }

  Future<String?> addDesign({
    required String lotId,
    required String designName,
    String? notes,
  }) async {
    try {
      await _repository.createDesign(
        lotId: lotId,
        designName: designName,
        notes: notes,
      );
      await loadLot(lotId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> editDesign({
    required String lotId,
    required String designId,
    required String designName,
    String? notes,
  }) async {
    try {
      await _repository.updateDesign(
        designId: designId,
        designName: designName,
        notes: notes,
      );
      await loadLot(lotId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> deleteDesign(String lotId, String designId) async {
    await _repository.deleteDesign(designId);
    await loadLot(lotId);
  }

  Future<String?> addColour({
    required String lotId,
    required String lotDesignId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  }) async {
    try {
      await _repository.createDesignColour(
        lotDesignId: lotDesignId,
        colourName: colourName,
        colourHex: colourHex,
        initialQuantity: initialQuantity,
        unitPricePaise: unitPricePaise,
        notes: notes,
      );
      await loadLot(lotId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> editColour({
    required String lotId,
    required String designColourId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  }) async {
    try {
      await _repository.updateDesignColour(
        designColourId: designColourId,
        colourName: colourName,
        colourHex: colourHex,
        initialQuantity: initialQuantity,
        unitPricePaise: unitPricePaise,
        notes: notes,
      );
      await loadLot(lotId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> deleteColour(String lotId, String designColourId) async {
    await _repository.deleteDesignColour(designColourId);
    await loadLot(lotId);
  }

  Future<String?> addPhoto({
    required String lotId,
    required Uint8List bytes,
    required String fileExtension,
    required String mimeType,
    String? caption,
  }) async {
    try {
      await _repository.addLotPhoto(
        lotId: lotId,
        bytes: bytes,
        fileExtension: fileExtension,
        mimeType: mimeType,
        caption: caption,
      );
      await loadLot(lotId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> removePhoto(String lotId, String attachmentId) async {
    await _repository.removeLotPhoto(attachmentId);
    await loadLot(lotId);
  }

  Future<Uint8List?> readPhotoBytes(String relativePath) =>
      _repository.readPhotoBytes(relativePath);
}
