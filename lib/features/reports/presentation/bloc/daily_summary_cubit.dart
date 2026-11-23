import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/domain/repositories/reports_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum DailySummaryStatus { initial, loading, loaded, error }

final class DailySummaryState {
  const DailySummaryState({
    this.status = DailySummaryStatus.initial,
    required this.selectedDayUtcMillis,
    this.summary,
    this.errorMessage,
  });

  final DailySummaryStatus status;
  final int selectedDayUtcMillis;
  final DailyWorkshopSummary? summary;
  final String? errorMessage;

  DailySummaryState copyWith({
    DailySummaryStatus? status,
    int? selectedDayUtcMillis,
    DailyWorkshopSummary? summary,
    String? errorMessage,
  }) {
    return DailySummaryState(
      status: status ?? this.status,
      selectedDayUtcMillis: selectedDayUtcMillis ?? this.selectedDayUtcMillis,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
    );
  }
}

@injectable
final class DailySummaryCubit extends Cubit<DailySummaryState> {
  DailySummaryCubit(this._repository)
    : super(
        DailySummaryState(
          selectedDayUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        ),
      );

  final ReportsRepository _repository;

  Future<void> loadForDay(int targetUtcMillis) async {
    emit(
      state.copyWith(
        status: DailySummaryStatus.loading,
        selectedDayUtcMillis: targetUtcMillis,
      ),
    );
    try {
      final summary = await _repository.getDailyWorkshopSummary(
        targetDayUtcMillis: targetUtcMillis,
      );
      emit(
        state.copyWith(
          status: DailySummaryStatus.loaded,
          selectedDayUtcMillis: targetUtcMillis,
          summary: summary,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DailySummaryStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadToday() => loadForDay(IstDateTimeHelper.nowUtcMillis());

  Future<void> loadYesterday() {
    final nowIst = IstDateTimeHelper.fromUtcMillisToIst(
      IstDateTimeHelper.nowUtcMillis(),
    );
    final yesterday = DateTime.utc(
      nowIst.year,
      nowIst.month,
      nowIst.day,
    ).subtract(const Duration(days: 1));
    final yUtc = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: yesterday.year,
      month: yesterday.month,
      day: yesterday.day,
      hour: 12,
    );
    return loadForDay(yUtc);
  }
}
