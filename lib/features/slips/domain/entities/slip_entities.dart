import 'package:flutter/foundation.dart';

/// Four worker-facing bilingual document types supported in StitchFlow v1.6.
enum SlipDocumentType {
  stockIssueChallan,
  returnQcSlip,
  paymentReceipt,
  workerKhataStatement,
}

/// Single tabular row inside a Karigar slip or Khata statement.
@immutable
final class SlipLineItem {
  const SlipLineItem({
    required this.title,
    this.subtitle,
    this.quantityText,
    this.rateText,
    this.amountPaise,
    this.timestampUtcMillis,
  });

  final String title;
  final String? subtitle;
  final String? quantityText;
  final String? rateText;
  final int? amountPaise;
  final int? timestampUtcMillis;
}

/// Immutable, pure-Dart payload for generating WhatsApp text, Indigo Thread
/// HTML/PDF printouts, and branded PNG receipt images via `RepaintBoundary`.
@immutable
final class WorkerSlipData {
  const WorkerSlipData({
    required this.type,
    required this.referenceId,
    required this.businessNameEn,
    required this.businessNameGu,
    this.businessPhone,
    this.businessAddress,
    required this.workerName,
    this.workerPhone,
    required this.transactionAtUtcMillis,
    required this.items,
    this.primaryAmountPaise,
    this.outstandingPayablePaise = 0,
    this.advanceCreditPaise = 0,
    this.periodLabelEn,
    this.periodLabelGu,
    this.notes,
  });

  final SlipDocumentType type;
  final String referenceId;
  final String businessNameEn;
  final String businessNameGu;
  final String? businessPhone;
  final String? businessAddress;
  final String workerName;
  final String? workerPhone;
  final int transactionAtUtcMillis;
  final List<SlipLineItem> items;
  final int? primaryAmountPaise;
  final int outstandingPayablePaise;
  final int advanceCreditPaise;
  final String? periodLabelEn;
  final String? periodLabelGu;
  final String? notes;

  String shopNameForLocale(String localeCode) =>
      localeCode == 'gu' ? businessNameGu : businessNameEn;

  String? periodForLocale(String localeCode) =>
      localeCode == 'gu' ? periodLabelGu : periodLabelEn;
}
