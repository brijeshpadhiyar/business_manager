import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Record Regular Payment, Advance Payment, or Advance Refund for a worker.
final class PaymentFormPage extends StatefulWidget {
  const PaymentFormPage({super.key, this.initialWorkerId});

  final String? initialWorkerId;

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

final class _PaymentFormPageState extends State<PaymentFormPage> {
  final _dirty = AppFormDirtyTracker();

  /// setState for a user edit: also marks the form as unsaved.
  void _edit(VoidCallback fn) {
    _dirty.markDirty();
    setState(fn);
  }

  final _formKey = GlobalKey<FormState>();
  final _workerFieldKey = GlobalKey<FormFieldState<String>>();
  final _amountFieldKey = GlobalKey<FormFieldState<String>>();
  final _refFieldKey = GlobalKey<FormFieldState<String>>();
  final _notesFieldKey = GlobalKey<FormFieldState<String>>();

  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _amountFocus = FocusNode();
  final _refFocus = FocusNode();
  final _notesFocus = FocusNode();

  final _repo = getIt<AccountingRepository>();
  final _clientRequestId = getIt<IdGenerator>().nextRequestId();

  List<WorkerFinancialSummary> _workers = const [];
  String? _selectedWorkerId;
  PaymentType _paymentType = PaymentType.regular;
  PaymentMode _paymentMode = PaymentMode.cash;
  int _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();
  bool _loading = true;
  bool _saving = false;
  bool _submittedOnce = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _dirty.watch([_amountCtrl, _refCtrl, _notesCtrl]);
    _load();
  }

  @override
  void dispose() {
    _dirty.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    _amountFocus.dispose();
    _refFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final workers = await _repo.getAllWorkerSummaries();
    if (!mounted) return;
    setState(() {
      _workers = workers;
      _selectedWorkerId =
          widget.initialWorkerId ??
          (workers.isNotEmpty ? workers.first.workerId : null);
      _loading = false;
    });
  }

  int? _parsePaise(String text) {
    return AppValidators.parseRupeesToPaiseExact(text, allowZero: false).paise;
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }
    final valid = FormValidationHelper.validateAndFocusFirstInvalid(
      formKey: _formKey,
      orderedAnchors: [
        ValidatedFieldAnchor(fieldKey: _workerFieldKey),
        ValidatedFieldAnchor(
          fieldKey: _amountFieldKey,
          focusNode: _amountFocus,
        ),
        ValidatedFieldAnchor(fieldKey: _refFieldKey, focusNode: _refFocus),
        ValidatedFieldAnchor(fieldKey: _notesFieldKey, focusNode: _notesFocus),
      ],
    );
    if (!valid || _selectedWorkerId == null) return;
    final l10n = context.l10n;
    final paise = _parsePaise(_amountCtrl.text);
    if (paise == null) return;

    setState(() {
      _saving = true;
      _submitError = null;
    });

    try {
      await _repo.recordPayment(
        workerId: _selectedWorkerId!,
        paymentType: _paymentType,
        amountPaise: paise,
        paymentMode: _paymentMode,
        transactionAtUtcMillis: _transactionAtUtc,
        referenceNo: _refCtrl.text,
        notes: _notesCtrl.text,
        clientRequestId: _clientRequestId,
      );
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.accountingPaymentSaved);
        context.pop(true);
      }
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = ValidationLocalizer.localizeDomainException(l10n, e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_loading) {
      return AppScaffold(
        title: l10n.accountingRecordPaymentAction,
        body: const AppLoader(),
      );
    }
    if (_workers.isEmpty) {
      return AppScaffold(
        title: l10n.accountingRecordPaymentAction,
        body: AppEmptyState(
          icon: Icons.people_outline_rounded,
          title: l10n.workersEmptyTitle,
        ),
      );
    }

    final selectedWorker = _workers.firstWhere(
      (w) => w.workerId == _selectedWorkerId,
      orElse: () => _workers.first,
    );

    return AppUnsavedChangesGuard.tracked(
      tracker: _dirty,
      child: AppScaffold(
        title: l10n.accountingRecordPaymentAction,
        contentWidth: AppContentWidth.narrow,
        body: Form(
          key: _formKey,
          autovalidateMode: _submittedOnce
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppDropdown<String>(
                      fieldKey: _workerFieldKey,
                      label: l10n.workerNameLabel,
                      value: _selectedWorkerId,
                      items: _workers.map((w) => w.workerId).toList(),
                      itemLabelBuilder: (id) => _workers
                          .firstWhere((w) => w.workerId == id)
                          .workerName,
                      validator: (v) =>
                          v == null ? l10n.validationRequired : null,
                      onChanged: (v) => _edit(() => _selectedWorkerId = v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppStatusBadge(
                          label:
                              '${l10n.accountingOutstandingPayableLabel}: ${MoneyFormatter.formatPaise(selectedWorker.outstandingPayablePaise)}',
                          tone: selectedWorker.outstandingPayablePaise > 0
                              ? AppStatusTone.pending
                              : AppStatusTone.good,
                        ),
                        if (selectedWorker.advanceCreditBalancePaise > 0)
                          AppStatusBadge(
                            label:
                                '${l10n.accountingAdvanceCreditLabel}: ${MoneyFormatter.formatPaise(selectedWorker.advanceCreditBalancePaise)}',
                            tone: AppStatusTone.info,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppDropdown<PaymentType>(
                      label: l10n.accountingPaymentTypeLabel,
                      value: _paymentType,
                      items: const [
                        PaymentType.regular,
                        PaymentType.advance,
                        PaymentType.advanceRefund,
                      ],
                      itemLabelBuilder: (t) => switch (t) {
                        PaymentType.regular =>
                          l10n.accountingPaymentTypeRegular,
                        PaymentType.advance =>
                          l10n.accountingPaymentTypeAdvance,
                        PaymentType.advanceRefund =>
                          l10n.accountingPaymentTypeRefund,
                        PaymentType.reversal => l10n.stockTypeReversal,
                      },
                      onChanged: (v) {
                        _dirty.markDirty();
                        if (v != null) setState(() => _paymentType = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      fieldKey: _amountFieldKey,
                      controller: _amountCtrl,
                      focusNode: _amountFocus,
                      label: l10n.accountingAmountLabel,
                      prefixIcon: Icons.currency_rupee,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_submitError != null) {
                          setState(() => _submitError = null);
                        }
                      },
                      validator: ValidationLocalizer.wrap(
                        l10n,
                        (v) => AppValidators.amountValidator(v),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppDropdown<PaymentMode>(
                      label: l10n.accountingPaymentModeLabel,
                      value: _paymentMode,
                      items: PaymentMode.values,
                      itemLabelBuilder: (m) => switch (m) {
                        PaymentMode.cash => l10n.accountingModeCash,
                        PaymentMode.upi => l10n.accountingModeUpi,
                        PaymentMode.bankTransfer => l10n.accountingModeBank,
                        PaymentMode.cheque => l10n.accountingModeCheque,
                        PaymentMode.other => l10n.accountingModeOther,
                      },
                      onChanged: (v) {
                        _dirty.markDirty();
                        if (v != null) setState(() => _paymentMode = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppDatePicker(
                      label: l10n.stockTransactionDateTimeLabel,
                      selectedUtcMillis: _transactionAtUtc,
                      includeTime: true,
                      onDateSelectedUtcMillis: (utc) =>
                          _edit(() => _transactionAtUtc = utc),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      fieldKey: _refFieldKey,
                      controller: _refCtrl,
                      focusNode: _refFocus,
                      label: l10n.accountingReferenceLabel,
                      prefixIcon: Icons.receipt_outlined,
                      textInputAction: TextInputAction.next,
                      maxLength: ValidationLimits.maxShortNameLength,
                      validator: ValidationLocalizer.wrap(
                        l10n,
                        (v) => AppValidators.maxLengthValidator(
                          v,
                          maxLength: ValidationLimits.maxShortNameLength,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      fieldKey: _notesFieldKey,
                      controller: _notesCtrl,
                      focusNode: _notesFocus,
                      label: l10n.stockNotesLabel,
                      maxLines: 2,
                      maxLength: ValidationLimits.maxNotesLength,
                      validator: ValidationLocalizer.wrap(
                        l10n,
                        (v) => AppValidators.maxLengthValidator(
                          v,
                          maxLength: ValidationLimits.maxNotesLength,
                        ),
                      ),
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText(
                        _submitError!,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.actionSave,
                      icon: Icons.check_rounded,
                      isExpanded: true,
                      isLoading: _saving,
                      onPressed: _submit,
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
