import 'dart:typed_data';

import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation_localizer.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/auth/presentation/widgets/permission_gate.dart';
import 'package:business_manager/features/cashbook/domain/calculators/cashbook_calculator.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/cashbook/presentation/bloc/cashbook_cubit.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

/// Adaptive detail bottom sheet / dialog for a [WorkshopExpenseView], showing
/// full metadata, partial-payment progress, settlement history, receipt preview,
/// and optional post-create receipt upload.
final class ExpenseDetailSheet {
  static Future<void> show(
    BuildContext context, {
    required WorkshopExpenseView view,
    required CashbookCubit cubit,
    required VoidCallback onMarkPaid,
    required VoidCallback onReverseExpense,
    required ValueChanged<CashbookEntryEntity> onReverseSettlement,
  }) {
    final l10n = context.l10n;
    return AppBottomSheet.show<void>(
      context,
      title: l10n.cashbookExpenseDetailTitle,
      builder: (sheetCtx) => _ExpenseDetailBody(
        view: view,
        cubit: cubit,
        onMarkPaid: () {
          Navigator.of(sheetCtx).pop();
          onMarkPaid();
        },
        onReverseExpense: () {
          Navigator.of(sheetCtx).pop();
          onReverseExpense();
        },
        onReverseSettlement: (entry) {
          Navigator.of(sheetCtx).pop();
          onReverseSettlement(entry);
        },
      ),
    );
  }
}

final class _ExpenseDetailBody extends StatefulWidget {
  const _ExpenseDetailBody({
    required this.view,
    required this.cubit,
    required this.onMarkPaid,
    required this.onReverseExpense,
    required this.onReverseSettlement,
  });

  final WorkshopExpenseView view;
  final CashbookCubit cubit;
  final VoidCallback onMarkPaid;
  final VoidCallback onReverseExpense;
  final ValueChanged<CashbookEntryEntity> onReverseSettlement;

  @override
  State<_ExpenseDetailBody> createState() => _ExpenseDetailBodyState();
}

final class _ExpenseDetailBodyState extends State<_ExpenseDetailBody> {
  List<CashbookEntryEntity> _settlements = const [];
  bool _loadingSettlements = true;
  Uint8List? _receiptBytes;
  bool _loadingReceipt = false;
  bool _uploadingReceipt = false;

  bool get _canUseCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final expId = widget.view.expense.id;
    final loadReceipt = widget.view.hasReceiptAttachment;
    if (loadReceipt) {
      setState(() => _loadingReceipt = true);
    }

    try {
      final settlements = await widget.cubit.getExpenseSettlements(expId);
      final bytes = loadReceipt
          ? await widget.cubit.readReceiptBytes(expId)
          : null;
      if (!mounted) return;
      setState(() {
        _settlements = settlements;
        _loadingSettlements = false;
        _receiptBytes = bytes;
        _loadingReceipt = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSettlements = false;
        _loadingReceipt = false;
      });
    }
  }

  Future<void> _attachReceipt(ImageSource source) async {
    final l10n = context.l10n;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || !mounted) return;
      final ext = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

      setState(() => _uploadingReceipt = true);
      await widget.cubit.attachExpenseReceipt(
        expenseId: widget.view.expense.id,
        receiptBytes: bytes,
        fileExtension: ext,
        mimeType: mime,
      );
      if (!mounted) return;
      setState(() {
        _receiptBytes = bytes;
        _uploadingReceipt = false;
      });
      AppFeedback.showSuccess(context, l10n.cashbookReceiptAttachedSuccess);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingReceipt = false);
      AppFeedback.showError(
        context,
        ValidationLocalizer.describeError(l10n, e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = widget.view;
    final e = view.expense;

    final canManageAll = PermissionGate.hasPermission(
      context,
      AppPermission.recordNonCashExpenseAndTransfers,
    );
    final canAttachReceipt =
        !view.isReversed &&
        ((e.paymentStatus == ExpensePaymentStatus.paid &&
                e.paymentMode == PaymentMode.cash &&
                PermissionGate.hasPermission(
                  context,
                  AppPermission.recordCashExpense,
                )) ||
            canManageAll);

    final (statusLabel, statusTone) = view.isReversed
        ? (l10n.dispatchReversedBadge, AppStatusTone.neutral)
        : view.isFullySettled
        ? (l10n.cashbookExpensePaidBadge, AppStatusTone.good)
        : view.settledPaise > 0
        ? (l10n.cashbookExpensePartialBadge, AppStatusTone.info)
        : (l10n.cashbookExpenseUnpaidBadge, AppStatusTone.pending);

    final settlementEntries = _settlements
        .where((s) => s.entryType == CashbookEntryType.expenseSettlement)
        .toList();
    final reversedSettlementIds = const CashbookCalculator()
        .reversedCashbookEntryIds(_settlements);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        AppActionRow(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppHeading(e.title, level: AppHeadingLevel.h3),
              const AppGap.xs(),
              AppText(
                DomainLabelLocalizer.expenseCategory(l10n, e.category),
                variant: AppTextVariant.bodySmall,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          actions: [
            AppStatusBadge(
              label: MoneyFormatter.formatPaise(e.amountPaise),
              tone: AppStatusTone.neutral,
            ),
            AppStatusBadge(label: statusLabel, tone: statusTone),
          ],
        ),
        if (!view.isReversed &&
            view.settledPaise > 0 &&
            view.remainingUnpaidPaise > 0) ...[
          const AppGap.sm(),
          AppProgressBar(
            value: view.settledPaise / e.amountPaise,
            tone: AppStatusTone.info,
            label:
                '${l10n.cashbookExpenseSettledValue(MoneyFormatter.formatPaise(view.settledPaise), MoneyFormatter.formatPaise(e.amountPaise))} • ${l10n.cashbookRemainingDueLabel}: ${MoneyFormatter.formatPaise(view.remainingUnpaidPaise)}',
          ),
        ],
        const AppGap.md(),
        _DetailRow(
          label: l10n.stockTransactionDateTimeLabel,
          value: AppDateTimeFormatter.formatDateTime(e.transactionAt),
        ),
        if (e.payeeName != null && e.payeeName!.isNotEmpty)
          _DetailRow(label: l10n.cashbookExpensePayeeLabel, value: e.payeeName!),
        if (e.paymentMode != null)
          _DetailRow(
            label: l10n.accountingPaymentModeLabel,
            value: DomainLabelLocalizer.paymentMode(l10n, e.paymentMode!),
          ),
        if (e.referenceNo != null && e.referenceNo!.isNotEmpty)
          _DetailRow(
            label: l10n.accountingReferenceLabel,
            value: e.referenceNo!,
          ),
        if (e.notes != null && e.notes!.isNotEmpty)
          _DetailRow(label: l10n.lotNotesLabel, value: e.notes!),
        if (e.createdBy != null && e.createdBy!.isNotEmpty)
          _DetailRow(label: l10n.cashbookCreatedByLabel, value: e.createdBy!),
        if (e.reason != null && e.reason!.isNotEmpty)
          _DetailRow(label: l10n.cashbookReversalReasonLabel, value: e.reason!),
        if (e.paymentStatus == ExpensePaymentStatus.unpaid ||
            settlementEntries.isNotEmpty) ...[
          const AppGap.md(),
          AppHeading(
            l10n.cashbookSettlementHistoryHeading,
            level: AppHeadingLevel.h3,
          ),
          const AppGap.xs(),
          if (_loadingSettlements)
            const AppProgressBar()
          else if (settlementEntries.isEmpty)
            AppText(
              l10n.cashbookNoSettlementsYet,
              variant: AppTextVariant.bodySmall,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          else
            for (final s in settlementEntries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppCard.listItem(
                  child: AppActionRow(
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          '${MoneyFormatter.formatPaise(s.amountPaise)} • ${DomainLabelLocalizer.paymentMode(l10n, s.paymentMode)}',
                          fontWeight: FontWeight.w700,
                        ),
                        AppText(
                          '${AppDateTimeFormatter.formatDateTime(s.transactionAt)}'
                          '${s.referenceNo != null && s.referenceNo!.isNotEmpty ? ' • ${s.referenceNo}' : ''}'
                          '${s.notes != null && s.notes!.isNotEmpty ? ' • ${s.notes}' : ''}',
                          variant: AppTextVariant.bodySmall,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    actions: [
                      if (reversedSettlementIds.contains(s.id))
                        AppStatusBadge(
                          label: l10n.dispatchReversedBadge,
                          tone: AppStatusTone.neutral,
                        )
                      else if (canManageAll)
                        AppIconButton(
                          icon: AppIcons.reverse,
                          tooltip: l10n.stockReverseAction,
                          onPressed: () => widget.onReverseSettlement(s),
                        ),
                    ],
                  ),
                ),
              ),
        ],
        const AppGap.md(),
        AppHeading(
          l10n.cashbookExpenseReceiptLabel,
          level: AppHeadingLevel.h3,
        ),
        const AppGap.xs(),
        if (_loadingReceipt || _uploadingReceipt)
          const AppProgressBar()
        else if (_receiptBytes != null && _receiptBytes!.isNotEmpty)
          ClipRRect(
            borderRadius: context.density.radiusMdBorder,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Image.memory(_receiptBytes!, fit: BoxFit.contain),
            ),
          )
        else if (canAttachReceipt)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (_canUseCamera)
                AppButton(
                  label: l10n.lotAddPhotoCamera,
                  icon: AppIcons.camera,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => _attachReceipt(ImageSource.camera),
                ),
              AppButton(
                label: l10n.cashbookExpenseAddReceipt,
                icon: AppIcons.gallery,
                variant: AppButtonVariant.outlined,
                onPressed: () => _attachReceipt(ImageSource.gallery),
              ),
            ],
          ),
        if (!view.isReversed && canManageAll) ...[
          const AppGap.md(),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (!view.isFullySettled)
                AppButton(
                  label: l10n.cashbookMarkPaidAction,
                  icon: AppIcons.confirm,
                  variant: AppButtonVariant.primary,
                  onPressed: widget.onMarkPaid,
                ),
              AppButton(
                label: l10n.stockReverseAction,
                icon: AppIcons.reverse,
                variant: AppButtonVariant.outlined,
                onPressed: widget.onReverseExpense,
              ),
            ],
          ),
        ],
      ],
      ),
    );
  }
}

final class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: AppText(
              label,
              variant: AppTextVariant.bodySmall,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: AppText(value, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
