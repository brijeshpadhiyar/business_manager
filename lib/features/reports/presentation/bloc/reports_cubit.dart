import 'dart:async';

import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/reports/domain/repositories/reports_repository.dart';
import 'package:business_manager/features/reports/domain/services/report_export_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum ReportsStatus { initial, loading, loaded, error }

final class ReportsState {
  const ReportsState({
    this.status = ReportsStatus.initial,
    this.category = ReportCategory.dailyWorkshop,
    this.inventorySubTab = 0,
    this.financialSubTab = 0,
    this.filter = const ReportFilter(preset: ReportDatePreset.allTime),
    this.bundle,
    this.isExporting = false,
    this.exportFeedbackMessage,
    this.exportSucceeded,
    this.errorMessage,
  });

  final ReportsStatus status;
  final ReportCategory category;
  final int inventorySubTab;
  final int financialSubTab;
  final ReportFilter filter;
  final AdvancedReportsBundle? bundle;
  final bool isExporting;
  final String? exportFeedbackMessage;
  final bool? exportSucceeded;
  final String? errorMessage;

  ReportsState copyWith({
    ReportsStatus? status,
    ReportCategory? category,
    int? inventorySubTab,
    int? financialSubTab,
    ReportFilter? filter,
    AdvancedReportsBundle? bundle,
    bool? isExporting,
    String? exportFeedbackMessage,
    bool? exportSucceeded,
    bool clearExportFeedback = false,
    String? errorMessage,
  }) {
    return ReportsState(
      status: status ?? this.status,
      category: category ?? this.category,
      inventorySubTab: inventorySubTab ?? this.inventorySubTab,
      financialSubTab: financialSubTab ?? this.financialSubTab,
      filter: filter ?? this.filter,
      bundle: bundle ?? this.bundle,
      isExporting: isExporting ?? this.isExporting,
      exportFeedbackMessage: clearExportFeedback
          ? null
          : (exportFeedbackMessage ?? this.exportFeedbackMessage),
      exportSucceeded: clearExportFeedback
          ? null
          : (exportSucceeded ?? this.exportSucceeded),
      errorMessage: errorMessage,
    );
  }
}

@injectable
final class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._repository, this._exportService)
    : super(
        ReportsState(
          filter: ReportFilter.forPreset(ReportDatePreset.thisMonth),
        ),
      );

  final ReportsRepository _repository;
  final ReportExportService _exportService;
  Timer? _searchDebounce;
  int _loadEpoch = 0;

  void selectCategory(ReportCategory category) {
    if (state.category == category) return;
    emit(state.copyWith(category: category, clearExportFeedback: true));
  }

  void selectInventorySubTab(int index) {
    emit(state.copyWith(inventorySubTab: index, clearExportFeedback: true));
  }

  void selectFinancialSubTab(int index) {
    emit(state.copyWith(financialSubTab: index, clearExportFeedback: true));
  }

  Future<void> applyPreset(ReportDatePreset preset) async {
    final bounds = IstDateRangePresets.resolve(preset);
    final nextFilter = state.filter.copyWith(
      preset: preset,
      fromUtcMillis: bounds.fromUtcMillis,
      toUtcMillis: bounds.toUtcMillis,
      clearFrom: preset == ReportDatePreset.allTime,
      clearTo: preset == ReportDatePreset.allTime,
    );
    await loadReports(filterOverride: nextFilter);
  }

  Future<void> setCustomDateRange({int? fromUtcMillis, int? toUtcMillis}) {
    var from = fromUtcMillis ?? state.filter.fromUtcMillis;
    var to = toUtcMillis ?? state.filter.toUtcMillis;
    if (from != null && to != null && to < from) {
      to = IstDateRangePresets.endOfIstDay(from);
    }
    final nextFilter = state.filter.copyWith(
      preset: ReportDatePreset.custom,
      fromUtcMillis: from,
      toUtcMillis: to,
    );
    return loadReports(filterOverride: nextFilter);
  }

  Future<void> setWorkerFilter(String? workerId) {
    return loadReports(
      filterOverride: state.filter.copyWith(
        workerId: workerId,
        clearWorker: workerId == null,
      ),
    );
  }

  Future<void> setProcessFilter(String? processId) {
    return loadReports(
      filterOverride: state.filter.copyWith(
        processId: processId,
        clearProcess: processId == null,
      ),
    );
  }

  Future<void> setLotFilter(String? lotId) {
    return loadReports(
      filterOverride: state.filter.copyWith(
        lotId: lotId,
        clearLot: lotId == null,
        clearDesign: true,
        clearColour: true,
      ),
    );
  }

  Future<void> setDesignFilter(String? designId) {
    return loadReports(
      filterOverride: state.filter.copyWith(
        lotDesignId: designId,
        clearDesign: designId == null,
        clearColour: true,
      ),
    );
  }

  Future<void> setColourFilter(String? colourId) {
    return loadReports(
      filterOverride: state.filter.copyWith(
        designColourId: colourId,
        clearColour: colourId == null,
      ),
    );
  }

  Future<void> setPaymentModeFilter(PaymentMode? mode) {
    return loadReports(
      filterOverride: state.filter.copyWith(
        paymentMode: mode,
        clearPaymentMode: mode == null,
      ),
    );
  }

  Future<void> setPaymentTypeFilter(PaymentType? type) {
    return loadReports(
      filterOverride: state.filter.copyWith(
        paymentType: type,
        clearPaymentType: type == null,
      ),
    );
  }

  Future<void> setIncludeReversedInHistory(bool include) {
    return loadReports(
      filterOverride: state.filter.copyWith(includeReversedInHistory: include),
    );
  }

  void updateSearchQuery(String query) {
    _searchDebounce?.cancel();
    final updated = state.filter.copyWith(searchQuery: query);
    emit(state.copyWith(filter: updated, clearExportFeedback: true));
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!isClosed) {
        unawaited(loadReports(filterOverride: updated));
      }
    });
  }

  Future<void> clearAllFilters() {
    _searchDebounce?.cancel();
    final reset = ReportFilter.forPreset(ReportDatePreset.thisMonth);
    return loadReports(filterOverride: reset);
  }

  Future<void> loadReports({ReportFilter? filterOverride}) async {
    final targetFilter = filterOverride ?? state.filter;
    final epoch = ++_loadEpoch;
    emit(
      state.copyWith(
        status: ReportsStatus.loading,
        filter: targetFilter,
        clearExportFeedback: true,
      ),
    );
    try {
      final bundle = await _repository.getAdvancedReports(targetFilter);
      if (isClosed || epoch != _loadEpoch) return;
      emit(
        state.copyWith(
          status: ReportsStatus.loaded,
          filter: targetFilter,
          bundle: bundle,
        ),
      );
    } catch (e) {
      if (isClosed || epoch != _loadEpoch) return;
      emit(
        state.copyWith(
          status: ReportsStatus.error,
          filter: targetFilter,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<ReportExportResult> exportReport({
    required ReportExportFormat format,
    required String localeCode,
    bool fullWorkbook = false,
  }) async {
    final bundle = state.bundle;
    if (bundle == null) {
      return const ReportExportResult(
        success: false,
        message: 'No report data loaded.',
      );
    }
    emit(state.copyWith(isExporting: true, clearExportFeedback: true));
    try {
      final result = switch (format) {
        ReportExportFormat.printPdf => await _exportService.printOrSavePdf(
          bundle: bundle,
          category: state.category,
          localeCode: localeCode,
          subTabIndex: state.category == ReportCategory.inventory
              ? state.inventorySubTab
              : (state.category == ReportCategory.labourFinancial
                    ? state.financialSubTab
                    : null),
        ),
        ReportExportFormat.excelXlsx => await _exportService.exportExcel(
          bundle: bundle,
          category: state.category,
          localeCode: localeCode,
          fullWorkbook: fullWorkbook,
        ),
        ReportExportFormat.csvUtf8Bom => await _exportService.exportCsv(
          bundle: bundle,
          category: state.category,
          localeCode: localeCode,
        ),
      };
      if (!isClosed) {
        emit(
          state.copyWith(
            isExporting: false,
            exportSucceeded: result.success,
            exportFeedbackMessage: result.message,
          ),
        );
      }
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isExporting: false,
            exportSucceeded: false,
            exportFeedbackMessage: e.toString(),
          ),
        );
      }
      return ReportExportResult(success: false, message: e.toString());
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
