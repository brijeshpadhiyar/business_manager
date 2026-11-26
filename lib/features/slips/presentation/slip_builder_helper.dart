import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/business_profile/domain/repositories/business_profile_repository.dart';
import 'package:business_manager/features/slips/domain/entities/slip_entities.dart';

/// Builds [WorkerSlipData] payloads cleanly from operational domain models
/// while fetching the live [BusinessProfileEntity] from DI.
abstract final class SlipBuilderHelper {
  static Future<BusinessProfileEntity?> _loadProfile() async {
    if (!getIt.isRegistered<BusinessProfileRepository>()) return null;
    try {
      return await getIt<BusinessProfileRepository>().getProfile();
    } catch (_) {
      return null;
    }
  }

  static Future<WorkerSlipData> buildStockIssueChallan({
    required String movementId,
    required String lotNumber,
    required String designName,
    required String colourName,
    required String processName,
    required String workerName,
    required int quantity,
    required int ratePaise,
    required int transactionAtUtcMillis,
    int outstandingPayablePaise = 0,
    int advanceCreditPaise = 0,
    String? notes,
  }) async {
    final profile = await _loadProfile();
    final refShort = movementId.length > 8
        ? movementId.substring(0, 8).toUpperCase()
        : movementId.toUpperCase();
    return WorkerSlipData(
      type: SlipDocumentType.stockIssueChallan,
      referenceId: 'CH-$refShort',
      businessNameEn: profile?.nameEn ?? 'Business Manager',
      businessNameGu: profile?.nameGu ?? 'બિઝનેસ મેનેજર',
      businessPhone: profile?.phone,
      businessAddress: profile?.address,
      workerName: workerName,
      transactionAtUtcMillis: transactionAtUtcMillis,
      items: [
        SlipLineItem(
          title: '$lotNumber • $designName • $colourName',
          subtitle: processName,
          quantityText: '$quantity pcs',
          rateText: '${MoneyFormatter.formatPaise(ratePaise)}/pc',
          amountPaise: quantity * ratePaise,
        ),
      ],
      primaryAmountPaise: quantity * ratePaise,
      outstandingPayablePaise: outstandingPayablePaise,
      advanceCreditPaise: advanceCreditPaise,
      notes: notes,
    );
  }

  static Future<WorkerSlipData> buildReturnQcSlip({
    required String referenceId,
    required String lotNumber,
    required String designName,
    required String colourName,
    required String processName,
    required String workerName,
    required int goodQty,
    required int damagedQty,
    required int lostQty,
    required int shortageQty,
    required int labourEarnedPaise,
    required int transactionAtUtcMillis,
    int outstandingPayablePaise = 0,
    int advanceCreditPaise = 0,
    String? notes,
  }) async {
    final profile = await _loadProfile();
    final items = <SlipLineItem>[
      if (goodQty > 0)
        SlipLineItem(
          title: '$lotNumber • $designName • $colourName',
          subtitle: '$processName • Good Returned',
          quantityText: '$goodQty pcs',
          amountPaise: labourEarnedPaise > 0 ? labourEarnedPaise : null,
        ),
      if (damagedQty > 0)
        SlipLineItem(
          title: '$lotNumber • $designName • $colourName',
          subtitle: '$processName • Damaged',
          quantityText: '$damagedQty pcs',
        ),
      if (lostQty > 0)
        SlipLineItem(
          title: '$lotNumber • $designName • $colourName',
          subtitle: '$processName • Lost',
          quantityText: '$lostQty pcs',
        ),
      if (shortageQty > 0)
        SlipLineItem(
          title: '$lotNumber • $designName • $colourName',
          subtitle: '$processName • Shortage',
          quantityText: '$shortageQty pcs',
        ),
    ];

    return WorkerSlipData(
      type: SlipDocumentType.returnQcSlip,
      referenceId: referenceId,
      businessNameEn: profile?.nameEn ?? 'Business Manager',
      businessNameGu: profile?.nameGu ?? 'બિઝનેસ મેનેજર',
      businessPhone: profile?.phone,
      businessAddress: profile?.address,
      workerName: workerName,
      transactionAtUtcMillis: transactionAtUtcMillis,
      items: items.isEmpty
          ? [
              SlipLineItem(
                title: '$lotNumber • $designName • $colourName',
                subtitle: '$processName • Pending QC',
              ),
            ]
          : items,
      primaryAmountPaise: labourEarnedPaise > 0 ? labourEarnedPaise : null,
      outstandingPayablePaise: outstandingPayablePaise,
      advanceCreditPaise: advanceCreditPaise,
      notes: notes,
    );
  }

  static Future<WorkerSlipData> buildPaymentReceipt({
    required String paymentId,
    required String workerName,
    String? workerPhone,
    required String paymentTypeLabel,
    required String paymentModeLabel,
    required int amountPaise,
    required int transactionAtUtcMillis,
    required int outstandingPayablePaise,
    required int advanceCreditPaise,
    String? referenceNo,
    String? notes,
  }) async {
    final profile = await _loadProfile();
    final refShort = (referenceNo != null && referenceNo.trim().isNotEmpty)
        ? referenceNo.trim()
        : 'PAY-${paymentId.length > 8 ? paymentId.substring(0, 8).toUpperCase() : paymentId.toUpperCase()}';
    return WorkerSlipData(
      type: SlipDocumentType.paymentReceipt,
      referenceId: refShort,
      businessNameEn: profile?.nameEn ?? 'Business Manager',
      businessNameGu: profile?.nameGu ?? 'બિઝનેસ મેનેજર',
      businessPhone: profile?.phone,
      businessAddress: profile?.address,
      workerName: workerName,
      workerPhone: workerPhone,
      transactionAtUtcMillis: transactionAtUtcMillis,
      items: [
        SlipLineItem(
          title: paymentTypeLabel,
          subtitle: paymentModeLabel,
          amountPaise: amountPaise,
        ),
      ],
      primaryAmountPaise: amountPaise,
      outstandingPayablePaise: outstandingPayablePaise,
      advanceCreditPaise: advanceCreditPaise,
      notes: notes,
    );
  }

  static Future<WorkerSlipData> buildKhataStatement({
    required WorkerLedgerDetail detail,
    required List<WorkerLedgerLine> visibleLines,
    required int generatedAtUtcMillis,
  }) async {
    final profile = await _loadProfile();
    final summary = detail.summary;
    final items = visibleLines
        .take(25)
        .map(
          (line) => SlipLineItem(
            title: line.title,
            subtitle: line.subtitle ?? line.notes,
            amountPaise: line.amountPaise,
            timestampUtcMillis: line.transactionAt,
          ),
        )
        .toList();

    return WorkerSlipData(
      type: SlipDocumentType.workerKhataStatement,
      referenceId:
          'KH-${summary.workerId.length > 6 ? summary.workerId.substring(0, 6).toUpperCase() : summary.workerId.toUpperCase()}',
      businessNameEn: profile?.nameEn ?? 'Business Manager',
      businessNameGu: profile?.nameGu ?? 'બિઝનેસ મેનેજર',
      businessPhone: profile?.phone,
      businessAddress: profile?.address,
      workerName: summary.workerName,
      workerPhone: summary.workerPhone,
      transactionAtUtcMillis: generatedAtUtcMillis,
      items: items,
      primaryAmountPaise: summary.earnedLabourPaise,
      outstandingPayablePaise: summary.outstandingPayablePaise,
      advanceCreditPaise: summary.advanceCreditBalancePaise,
    );
  }
}
