import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/cashbook/domain/repositories/cashbook_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// `/cashbook/transfer/new` — Record Cash↔Bank contra transfers, Owner Capital,
/// or Owner Drawings.
final class CashbookTransferFormPage extends StatefulWidget {
  const CashbookTransferFormPage({super.key});

  @override
  State<CashbookTransferFormPage> createState() =>
      _CashbookTransferFormPageState();
}

final class _CashbookTransferFormPageState
    extends State<CashbookTransferFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dirtyTracker = AppFormDirtyTracker();

  CashbookEntryType _entryType = CashbookEntryType.cashToBank;
  CashbookAccountBucket _bucket = CashbookAccountBucket.cash;
  PaymentMode _mode = PaymentMode.bankTransfer;
  int _txUtcMillis = IstDateTimeHelper.nowUtcMillis();
  bool _saving = false;
  late final String _clientRequestId;

  @override
  void initState() {
    super.initState();
    _clientRequestId = getIt<IdGenerator>().nextEntityId();
    _dirtyTracker.watch([_amountCtrl, _refCtrl, _notesCtrl]);
  }

  @override
  void dispose() {
    _dirtyTracker.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isContra =>
      _entryType == CashbookEntryType.cashToBank ||
      _entryType == CashbookEntryType.bankToCash;

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final parsed = AppValidators.parseRupeesToPaiseExact(_amountCtrl.text);
    if (!parsed.validation.isValid ||
        parsed.paise == null ||
        parsed.paise! <= 0) {
      AppFeedback.showError(context, l10n.validationPositiveAmount);
      return;
    }

    setState(() => _saving = true);
    try {
      final bucket = _isContra ? CashbookAccountBucket.both : _bucket;
      final mode = _isContra
          ? PaymentMode.bankTransfer
          : (_bucket == CashbookAccountBucket.cash ? PaymentMode.cash : _mode);

      await getIt<CashbookRepository>().recordCashbookEntry(
        entryType: _entryType,
        accountBucket: bucket,
        paymentMode: mode,
        amountPaise: parsed.paise!,
        referenceNo: _refCtrl.text,
        notes: _notesCtrl.text,
        transactionAtUtcMillis: _txUtcMillis,
        clientRequestId: _clientRequestId,
      );
      if (!mounted) return;
      _dirtyTracker.reset();
      AppFeedback.showSuccess(context, l10n.cashbookTransferSavedSuccess);
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

    return AppUnsavedChangesGuard.tracked(
      tracker: _dirtyTracker,
      child: AppScaffold(
        title: l10n.cashbookTransferFormHeading,
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
              AppDropdown<CashbookEntryType>(
                label: l10n.cashbookEntryTypeLabel,
                value: _entryType,
                items: const [
                  CashbookEntryType.cashToBank,
                  CashbookEntryType.bankToCash,
                  CashbookEntryType.capitalIn,
                  CashbookEntryType.ownerDrawing,
                ],
                itemLabelBuilder: (t) =>
                    DomainLabelLocalizer.cashbookEntryType(l10n, t),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _entryType = v);
                    _dirtyTracker.markDirty();
                  }
                },
              ),
              const AppGap.md(),
              if (!_isContra) ...[
                AppDropdown<CashbookAccountBucket>(
                  label: l10n.cashbookAccountBucketLabel,
                  value: _bucket,
                  items: const [
                    CashbookAccountBucket.cash,
                    CashbookAccountBucket.bank,
                  ],
                  itemLabelBuilder: (b) => b == CashbookAccountBucket.cash
                      ? l10n.cashbookFilterCash
                      : l10n.cashbookFilterBank,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _bucket = v);
                      _dirtyTracker.markDirty();
                    }
                  },
                ),
                const AppGap.md(),
                if (_bucket == CashbookAccountBucket.bank) ...[
                  AppDropdown<PaymentMode>(
                    label: l10n.accountingPaymentModeLabel,
                    value: _mode,
                    items: const [
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
              const AppGap.xl(),
            ],
          ),
        ),
      ),
    );
  }
}
