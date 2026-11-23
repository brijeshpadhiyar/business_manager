import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';

abstract interface class ReportsRepository {
  Future<DashboardSnapshot> getDashboardSnapshot();

  Future<DailyWorkshopSummary> getDailyWorkshopSummary({
    int? targetDayUtcMillis,
  });

  /// Single-pass StitchFlow V1.2 Advanced Reports & Business Insights query.
  Future<AdvancedReportsBundle> getAdvancedReports(ReportFilter filter);

  Future<BusinessReportsBundle> getBusinessReports({
    int? fromUtcMillis,
    int? toUtcMillis,
    String? lotId,
    String? workerId,
    String? processId,
    String? searchQuery,
  });
}
