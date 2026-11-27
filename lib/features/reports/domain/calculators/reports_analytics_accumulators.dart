import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';

/// Pure-Dart input records & accumulators shared across [ReportsAnalyticsCalculator]
/// and [ReportsInsightsCalculator].
final class ReportLotInput {
  const ReportLotInput({
    required this.id,
    required this.lotNumber,
    this.title,
    required this.status,
  });

  final String id;
  final String lotNumber;
  final String? title;
  final LotStatus status;
}

final class ReportDesignInput {
  const ReportDesignInput({
    required this.id,
    required this.lotId,
    required this.designName,
  });

  final String id;
  final String lotId;
  final String designName;
}

final class ReportColourInput {
  const ReportColourInput({
    required this.id,
    required this.lotId,
    required this.lotDesignId,
    required this.colourName,
    this.colourHex,
    required this.initialQuantity,
    required this.unitPricePaise,
  });

  final String id;
  final String lotId;
  final String lotDesignId;
  final String colourName;
  final String? colourHex;
  final int initialQuantity;
  final int unitPricePaise;
}

final class ReportProcessInput {
  const ReportProcessInput({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;
}

final class ReportWorkerInput {
  const ReportWorkerInput({
    required this.id,
    required this.name,
    this.phone,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? phone;
  final bool isActive;
}

final class IssueSettlementAcc {
  int good = 0;
  int damaged = 0;
  int lost = 0;
  int shortage = 0;
  int maxSettlementTxAt = 0;
}

final class DailyAcc {
  DailyAcc(this.dayStartUtcMillis);
  final int dayStartUtcMillis;
  int issued = 0;
  int good = 0;
  int damaged = 0;
  int lost = 0;
  int shortage = 0;
  int repaired = 0;
  int labourPaise = 0;
  int regularPayPaise = 0;
  int advancePayPaise = 0;
  int advanceRefPaise = 0;
}

final class WorkerProcessAcc {
  int issued = 0;
  int good = 0;
  int damaged = 0;
  int lostShortage = 0;
  int labourPaise = 0;
}

final class WorkerPeriodAcc {
  int issued = 0;
  int good = 0;
  int damaged = 0;
  int lostShortage = 0;
  int labourPaise = 0;
  int regularPayPaise = 0;
  int advancePayPaise = 0;
  int advanceRefPaise = 0;
  final Map<String, WorkerProcessAcc> byProcess = {};
}

final class ProcessWorkerAcc {
  int issued = 0;
  int good = 0;
}

final class ProcessPeriodAcc {
  int issued = 0;
  int good = 0;
  int damaged = 0;
  int lostShortage = 0;
  int labourPaise = 0;
  final Map<String, ProcessWorkerAcc> byWorker = {};
}

final class ReasonAcc {
  int quantity = 0;
  int occurrences = 0;
}

final class TrendBucketAcc {
  TrendBucketAcc(this.label);
  final String label;
  int issued = 0;
  int good = 0;
  int defects = 0;
  int labour = 0;
}

double? computeReportDefectRate({
  required int good,
  required int damaged,
  required int lostShortage,
}) {
  final total = good + damaged + lostShortage;
  if (total <= 0) return null;
  return ((damaged + lostShortage) * 100.0) / total;
}
