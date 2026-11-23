import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';

abstract interface class ReportsRepository {
  Future<DashboardSnapshot> getDashboardSnapshot();

  Future<BusinessReportsBundle> getBusinessReports({
    int? fromUtcMillis,
    int? toUtcMillis,
    String? lotId,
    String? workerId,
    String? processId,
    String? searchQuery,
  });
}
