import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:business_manager/features/slips/presentation/slip_builder_helper.dart';
import 'package:business_manager/features/slips/presentation/widgets/slip_share_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// `/parties/:id/payment` — Record Cash/UPI/Bank Receipt, Advance, or Refund.
final class PartyPaymentFormPage extends StatefulWidget {
  const PartyPaymentFormPage({super.key, required this.partyId});

  final String partyId;

  @override
  State<PartyPaymentFormPage> createState() => _PartyPaymentFormPageState();
}

final class _PartyPaymentFormPageState extends State<PartyPaymentFormPage> {
  final _repo = getIt<PartyRepository>();
  final _formKey = GlobalKey<FormState>();
  final _dirty = AppFormDirtyTracker();

  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  PartyLedgerDetail? _detail;
  PartyPaymentType _paymentType = PartyPaymentType.receipt;
  PartyPaymentMode _paymentMode = PartyPaymentMode.cash;
  int _transactionAt = IstDateTimeHelper.nowUtcMillis();

  bool _isLoading = true;
  bool _isSaving = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _dirty.watch([_amountCtrl, _refCtrl, _notesCtrl]);
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await _repo.getPartyLedgerDetail(widget.partyId);
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'party_not_found';
        });
        return;
      }
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e;
      });
    }
  }

  @override
  void dispose() {
    _dirty.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amountPaise = AppValidators.parseRupeesToPaiseExact(
      _amountCtrl.text,
      allowZero: false,
    ).paise;
    if (amountPaise == null || amountPaise <= 0) {
      AppFeedback.showError(context, l10n.validationPositiveAmount);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payment = await _repo.recordPartyPayment(
        partyId: widget.partyId,
        paymentType: _paymentType,
        paymentMode: _paymentMode,
        amountPaise: amountPaise,
        referenceNo: _refCtrl.text,
        notes: _notesCtrl.text,
        transactionAtUtcMillis: _transactionAt,
      );
      if (!mounted) return;
      _dirty.reset();

      final updated = await _repo.getPartyLedgerDetail(widget.partyId);
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        l10n.partyPaymentSavedSuccess,
        actionLabel: l10n.partyPaymentShareReceiptAction,
        onAction: () async {
          if (updated == null) return;
          final slip = await SlipBuilderHelper.buildPartyPaymentReceipt(
            party: updated.party,
            payment: payment,
            outstandingReceivablePaise:
                updated.summary.outstandingReceivablePaise,
            advanceCreditPaise: updated.summary.advanceCreditPaise,
          );
          if (!mounted) return;
          await SlipShareSheet.show(context, slip);
        },
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppFeedback.showError(
        context,
        ValidationLocalizer.describeError(l10n, e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final duePaise = _detail?.summary.outstandingReceivablePaise ?? 0;

    return AppUnsavedChangesGuard.tracked(
      tracker: _dirty,
      child: AppScaffold(
        title: l10n.partyPaymentHeading,
        contentWidth: AppContentWidth.narrow,
        bottomAction: (_isLoading || _loadError != null)
            ? null
            : AppStickyActionBar(
                child: AppButton(
                  label: l10n.actionSave,
                  icon: AppIcons.payment,
                  isLoading: _isSaving,
                  isExpanded: true,
                  onPressed: _save,
                ),
              ),
        body: _isLoading
            ? const AppSkeletonList(itemCount: 4)
            : _loadError != null
            ? AppErrorView(
                title: l10n.errorUnexpected,
                message: ValidationLocalizer.describeError(l10n, _loadError!),
                onRetry: _load,
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppActionRow(
                            content: AppText(
                              _detail!.party.name,
                              variant: AppTextVariant.bodyLarge,
                              fontWeight: FontWeight.w600,
                            ),
                            actions: [
                              AppStatusBadge(
                                label: MoneyFormatter.formatPaise(duePaise),
                                tone: duePaise > 0
                                    ? AppStatusTone.pending
                                    : AppStatusTone.good,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppChipGroup<PartyPaymentType>(
                            items: const [
                              PartyPaymentType.receipt,
                              PartyPaymentType.advance,
                              PartyPaymentType.refund,
                            ],
                            value: _paymentType,
                            onChanged: (t) {
                              _dirty.markDirty();
                              setState(() => _paymentType = t);
                            },
                            itemLabelBuilder: (t) => switch (t) {
                              PartyPaymentType.receipt =>
                                l10n.partyPaymentTypeReceipt,
                              PartyPaymentType.advance =>
                                l10n.partyPaymentTypeAdvance,
                              PartyPaymentType.refund =>
                                l10n.partyPaymentTypeRefund,
                              PartyPaymentType.reversal => '',
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _amountCtrl,
                            label: l10n.lotDirectCostAmountLabel,
                            prefixIcon: AppIcons.rupee,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.amountValidator(v),
                            ),
                          ),
                          if (duePaise > 0) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              children: [
                                AppChip.action(
                                  label: l10n.partyPaymentCollectFullAction(
                                    MoneyFormatter.formatPaise(duePaise),
                                  ),
                                  icon: AppIcons.autoFill,
                                  onPressed: () {
                                    _dirty.markDirty();
                                    _amountCtrl.text = (duePaise / 100.0)
                                        .toStringAsFixed(2);
                                  },
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          AppChipGroup<PartyPaymentMode>(
                            scrollable: true,
                            items: PartyPaymentMode.values,
                            value: _paymentMode,
                            onChanged: (m) {
                              _dirty.markDirty();
                              setState(() => _paymentMode = m);
                            },
                            itemLabelBuilder: (m) => switch (m) {
                              PartyPaymentMode.cash => l10n.accountingModeCash,
                              PartyPaymentMode.upi => l10n.accountingModeUpi,
                              PartyPaymentMode.bankTransfer =>
                                l10n.accountingModeBank,
                              PartyPaymentMode.cheque =>
                                l10n.accountingModeCheque,
                              PartyPaymentMode.other =>
                                l10n.accountingModeOther,
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppDatePicker(
                            label: l10n.stockTransactionDateTimeLabel,
                            selectedUtcMillis: _transactionAt,
                            includeTime: true,
                            onDateSelectedUtcMillis: (ms) {
                              _dirty.markDirty();
                              setState(() => _transactionAt = ms);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _refCtrl,
                            label: l10n.txnReferenceLabel,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _notesCtrl,
                            label: l10n.lotNotesLabel,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
