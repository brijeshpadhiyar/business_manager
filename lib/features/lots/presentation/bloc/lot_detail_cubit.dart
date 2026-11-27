import 'dart:typed_data';

import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/domain/repositories/process_routing_repository.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
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
    JobRoutingOverview? routingOverview,
    @Default(<String, DesignColourStockBalance>{})
    Map<String, DesignColourStockBalance> balancesByColourId,
    @Default(<String, List<JobProcessEntity>>{})
    Map<String, List<JobProcessEntity>> operationsByColourId,
    @Default('') String designSearchQuery,
    String? errorMessage,
  }) = _LotDetailState;
}

@injectable
final class LotDetailCubit extends Cubit<LotDetailState> {
  LotDetailCubit(this._repository, this._routingRepository)
    : super(const LotDetailState());

  final LotRepository _repository;
  final ProcessRoutingRepository _routingRepository;

  /// Bounded in-memory cache of photo read futures keyed by relative path so
  /// search typing and minor rebuilds never trigger repeated disk I/O.
  static const int _maxCachedPhotos = 48;
  final Map<String, Future<Uint8List?>> _photoFutureCache = {};

  Future<JobRoutingOverview?> _loadRoutingSafely(String lotId) async {
    try {
      return await _routingRepository.getJobRoutingOverview(lotId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadLot(String lotId) async {
    emit(state.copyWith(status: LotDetailStatus.loading, errorMessage: null));
    try {
      final detailFuture = _repository.getLotDetail(lotId);
      final routingFuture = _loadRoutingSafely(lotId);

      final detail = await detailFuture;
      if (detail == null) {
        emit(
          state.copyWith(
            status: LotDetailStatus.error,
            errorMessage: 'Lot not found.',
          ),
        );
        return;
      }

      final routing = await routingFuture;

      // Pre-index balances & non-cancelled operations once per load for O(1)
      // card rendering inside build().
      final balancesByColourId = <String, DesignColourStockBalance>{};
      final operationsByColourId = <String, List<JobProcessEntity>>{};
      if (routing != null) {
        for (final balance in routing.skuBalances) {
          balancesByColourId[balance.designColourId] = balance;
        }
        for (final op in routing.jobProcesses) {
          if (op.status == JobProcessStatus.cancelled) continue;
          operationsByColourId
              .putIfAbsent(op.designColourId, () => <JobProcessEntity>[])
              .add(op);
        }
      }

      // Evict cached photo futures that no longer exist on this lot.
      final activePaths = detail.photos.map((p) => p.relativePath).toSet();
      _photoFutureCache.removeWhere((path, _) => !activePaths.contains(path));

      emit(
        state.copyWith(
          status: LotDetailStatus.loaded,
          detail: detail,
          routingOverview: routing,
          balancesByColourId:
              Map<String, DesignColourStockBalance>.unmodifiable(
                balancesByColourId,
              ),
          operationsByColourId:
              Map<String, List<JobProcessEntity>>.unmodifiable(
                operationsByColourId.map(
                  (k, v) => MapEntry(k, List<JobProcessEntity>.unmodifiable(v)),
                ),
              ),
        ),
      );
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
    if (query == state.designSearchQuery) return;
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
    } on DomainValidationException catch (e) {
      return e.code;
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
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addDesignWithColours({
    required String lotId,
    required String designName,
    String? notes,
    required List<LotColourDraftInput> colours,
  }) async {
    try {
      await _repository.createDesignWithColours(
        lotId: lotId,
        designName: designName,
        notes: notes,
        colours: colours,
      );
      await loadLot(lotId);
      return null;
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addColoursBatch({
    required String lotId,
    String? lotDesignId,
    required List<LotColourDraftInput> colours,
  }) async {
    try {
      await _repository.createDesignColoursBatch(
        lotId: lotId,
        lotDesignId: lotDesignId,
        colours: colours,
      );
      await loadLot(lotId);
      return null;
    } on DomainValidationException catch (e) {
      return e.code;
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
    } on DomainValidationException catch (e) {
      return e.code;
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
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addColourDirectly({
    required String lotId,
    required String colourName,
    String? colourHex,
    required int initialQuantity,
    required int unitPricePaise,
    String? notes,
  }) async {
    try {
      await _repository.addColourDirectlyToLot(
        lotId: lotId,
        colourName: colourName,
        colourHex: colourHex,
        initialQuantity: initialQuantity,
        unitPricePaise: unitPricePaise,
        notes: notes,
      );
      await loadLot(lotId);
      return null;
    } on DomainValidationException catch (e) {
      return e.code;
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
    } on DomainValidationException catch (e) {
      return e.code;
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
    } on DomainValidationException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> removePhoto(String lotId, String attachmentId) async {
    final removedPath = state.detail?.photos
        .where((p) => p.id == attachmentId)
        .map((p) => p.relativePath)
        .firstOrNull;
    await _repository.removeLotPhoto(attachmentId);
    if (removedPath != null) {
      _photoFutureCache.remove(removedPath);
    }
    await loadLot(lotId);
  }

  Future<Uint8List?> readPhotoBytes(String relativePath) {
    final existing = _photoFutureCache[relativePath];
    if (existing != null) return existing;
    if (_photoFutureCache.length >= _maxCachedPhotos) {
      _photoFutureCache.remove(_photoFutureCache.keys.first);
    }
    final future = _repository.readPhotoBytes(relativePath);
    _photoFutureCache[relativePath] = future;
    return future;
  }

  @override
  Future<void> close() {
    _photoFutureCache.clear();
    return super.close();
  }
}
