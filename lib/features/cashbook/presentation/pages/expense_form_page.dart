import 'dart:typed_data';

import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/auth/presentation/widgets/permission_gate.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/cashbook/domain/repositories/cashbook_repository.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

/// `/cashbook/expense/new` — Record a paid or unpaid Workshop Expense with
/// optional receipt photo attachment.
final class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({super.key});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

final class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _payeeCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dirtyTracker = AppFormDirtyTracker();

  ExpenseCategory _category = ExpenseCategory.supplies;
  ExpensePaymentStatus _status = ExpensePaymentStatus.paid;
  PaymentMode _mode = PaymentMode.cash;
  int _txUtcMillis = IstDateTimeHelper.nowUtcMillis();
  Uint8List? _receiptBytes;
  String? _receiptExt;
  String? _receiptMime;
  bool _saving = false;
  late final String _clientRequestId;

  bool get _canUseCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _clientRequestId = getIt<IdGenerator>().nextEntityId();
    _dirtyTracker.watch([
      _titleCtrl,
      _payeeCtrl,
      _amountCtrl,
      _refCtrl,
      _notesCtrl,
    ]);
  }

  @override
  void dispose() {
    _dirtyTracker.dispose();
    _titleCtrl.dispose();
    _payeeCtrl.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _receiptBytes = bytes;
        _receiptExt = picked.name.toLowerCase().endsWith('.png')
            ? 'png'
            : 'jpg';
        _receiptMime = _receiptExt == 'png' ? 'image/png' : 'image/jpeg';
      });
      _dirtyTracker.markDirty();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        ValidationLocalizer.describeError(context.l10n, e),
      );
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final parsed = AppValidators.parseRupeesToPaiseExact(_amountCtrl.text);
    if (!parsed.validation.isValid || parsed.paise == null || parsed.paise! <= 0) {
      AppFeedback.showError(context, l10n.validationPositiveAmount);
      return;
    }

    setState(() => _saving = true);
    try {
      final allowNonCash = PermissionGate.hasPermission(
        context,
        AppPermission.recordNonCashExpenseAndTransfers,
      );
      final effectiveStatus = allowNonCash ? _status : ExpensePaymentStatus.paid;
      final effectiveMode = effectiveStatus == ExpensePaymentStatus.paid
          ? (allowNonCash ? _mode : PaymentMode.cash)
          : null;

      await getIt<CashbookRepository>().recordExpense(
        RecordExpenseInput(
          category: _category,
          title: _titleCtrl.text,
          payeeName: _payeeCtrl.text,
          amountPaise: parsed.paise!,
          paymentStatus: effectiveStatus,
          paymentMode: effectiveMode,
          referenceNo: _refCtrl.text,
          notes: _notesCtrl.text,
          transactionAtUtcMillis: _txUtcMillis,
          clientRequestId: _clientRequestId,
          receiptBytes: _receiptBytes,
          receiptExtension: _receiptExt,
          receiptMimeType: _receiptMime,
        ),
      );
      if (!mounted) return;
      _dirtyTracker.reset();
      AppFeedback.showSuccess(context, l10n.cashbookExpenseSavedSuccess);
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.showError(
        context,
        ValidationLocalizer.describeError(l10n, e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = context.density;
    final allowNonCash = PermissionGate.hasPermission(
      context,
      AppPermission.recordNonCashExpenseAndTransfers,
    );

    return AppUnsavedChangesGuard.tracked(
      tracker: _dirtyTracker,
      child: AppScaffold(
        title: l10n.cashbookExpenseFormHeading,
        contentWidth: AppContentWidth.narrow,
        bottomAction: AppStickyActionBar(
          child: AppButton(
            label: l10n.actionSave,
            icon: AppIcons.save,
            variant: AppButtonVariant.primary,
            isLoading: _saving,
            isExpanded: true,
            onPressed: _saving ? null : _save,
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: d.screenAll,
            children: [
              AppText(
                l10n.cashbookExpenseCategoryLabel,
                variant: AppTextVariant.label,
              ),
              const AppGap.xs(),
              AppChipGroup<ExpenseCategory>(
                items: ExpenseCategory.values,
                value: _category,
                itemLabelBuilder: (c) =>
                    DomainLabelLocalizer.expenseCategory(l10n, c),
                onChanged: (v) {
                  setState(() => _category = v);
                  _dirtyTracker.markDirty();
                },
              ),
              const AppGap.md(),
              AppTextField(
                controller: _titleCtrl,
                label: l10n.cashbookExpenseTitleLabel,
                validator: (v) => ValidationLocalizer.localize(
                  l10n,
                  AppValidators.requiredValidator(v),
                ),
              ),
              const AppGap.md(),
              AppTextField(
                controller: _amountCtrl,
                label: l10n.accountingAmountLabel,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AppInputFormatters.currencyDecimal],
                validator: (v) => ValidationLocalizer.localize(
                  l10n,
                  AppValidators.amountValidator(v),
                ),
              ),
              const AppGap.md(),
              AppTextField(
                controller: _payeeCtrl,
                label: l10n.cashbookExpensePayeeLabel,
              ),
              const AppGap.md(),
              if (!allowNonCash) ...[
                AppCard(
                  child: AppText(
                    l10n.cashbookExpenseManagerCashNote,
                    variant: AppTextVariant.bodySmall,
                  ),
                ),
                const AppGap.md(),
              ] else ...[
                AppDropdown<ExpensePaymentStatus>(
                  label: l10n.cashbookExpenseStatusLabel,
                  value: _status,
                  items: const [
                    ExpensePaymentStatus.paid,
                    ExpensePaymentStatus.unpaid,
                  ],
                  itemLabelBuilder: (s) => s == ExpensePaymentStatus.paid
                      ? l10n.cashbookExpenseStatusPaid
                      : l10n.cashbookExpenseStatusUnpaid,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _status = v);
                      _dirtyTracker.markDirty();
                    }
                  },
                ),
                const AppGap.md(),
                if (_status == ExpensePaymentStatus.paid) ...[
                  AppDropdown<PaymentMode>(
                    label: l10n.accountingPaymentModeLabel,
                    value: _mode,
                    items: const [
                      PaymentMode.cash,
                      PaymentMode.upi,
                      PaymentMode.bankTransfer,
                      PaymentMode.cheque,
                    ],
                    itemLabelBuilder: (m) =>
                        DomainLabelLocalizer.paymentMode(l10n, m),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _mode = v);
                        _dirtyTracker.markDirty();
                      }
                    },
                  ),
                  const AppGap.md(),
                ],
              ],
              AppDatePicker(
                label: l10n.stockTransactionDateTimeLabel,
                selectedUtcMillis: _txUtcMillis,
                mode: AppDatePickMode.dateTime,
                onDateSelectedUtcMillis: (v) {
                  setState(() => _txUtcMillis = v);
                  _dirtyTracker.markDirty();
                },
              ),
              const AppGap.md(),
              AppTextField(
                controller: _refCtrl,
                label: l10n.accountingReferenceLabel,
              ),
              const AppGap.md(),
              AppTextField(
                controller: _notesCtrl,
                label: l10n.lotNotesLabel,
                maxLines: 2,
              ),
              const AppGap.md(),
              AppText(
                l10n.cashbookExpenseReceiptLabel,
                variant: AppTextVariant.label,
              ),
              const AppGap.xs(),
              if (_receiptBytes != null) ...[
                ClipRRect(
                  borderRadius: d.radiusMdBorder,
                  child: Image.memory(
                    _receiptBytes!,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                const AppGap.xs(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: l10n.cashbookExpenseRemoveReceipt,
                    icon: AppIcons.delete,
                    variant: AppButtonVariant.text,
                    onPressed: () {
                      setState(() {
                        _receiptBytes = null;
                        _receiptExt = null;
                        _receiptMime = null;
                      });
                    },
                  ),
                ),
              ] else
                Wrap(
                  spacing: d.sm,
                  runSpacing: d.sm,
                  children: [
                    if (_canUseCamera)
                      AppButton(
                        label: l10n.lotAddPhotoCamera,
                        icon: AppIcons.camera,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => _pickReceipt(ImageSource.camera),
                      ),
                    AppButton(
                      label: l10n.cashbookExpenseAddReceipt,
                      icon: AppIcons.gallery,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => _pickReceipt(ImageSource.gallery),
                    ),
                  ],
                ),
              const AppGap.xl(),
            ],
          ),
        ),
      ),
    );
  }
}
