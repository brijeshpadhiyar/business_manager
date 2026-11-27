import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Audited worker ledger adjustment screen (CREDIT or DEBIT with mandatory reason).
final class WorkerAdjustmentFormPage extends StatefulWidget {
  const WorkerAdjustmentFormPage({super.key, required this.workerId});

  final String workerId;

  @override
  State<WorkerAdjustmentFormPage> createState() =>
      _WorkerAdjustmentFormPageState();
}

final class _WorkerAdjustmentFormPageState
    extends State<WorkerAdjustmentFormPage> {
  late final _dirty = AppFormDirtyTracker()
    ..watch([_amountCtrl, _reasonCtrl, _notesCtrl]);

  /// setState for a user edit: also marks the form as unsaved.
  void _edit(VoidCallback fn) {
    _dirty.markDirty();
    setState(fn);
  }

  final _formKey = GlobalKey<FormState>();
  final _amountFieldKey = GlobalKey<FormFieldState<String>>();
  final _reasonFieldKey = GlobalKey<FormFieldState<String>>();
  final _notesFieldKey = GlobalKey<FormFieldState<String>>();

  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _amountFocus = FocusNode();
  final _reasonFocus = FocusNode();
  final _notesFocus = FocusNode();

  final _repo = getIt<AccountingRepository>();
  final _clientRequestId = getIt<IdGenerator>().nextRequestId();

  WorkerAdjustmentType _type = WorkerAdjustmentType.credit;
  int _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();
  bool _saving = false;
  bool _submittedOnce = false;
  String? _submitError;

  @override
  void dispose() {
    _dirty.dispose();
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    _amountFocus.dispose();
    _reasonFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
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
        ValidatedFieldAnchor(
          fieldKey: _amountFieldKey,
          focusNode: _amountFocus,
        ),
        ValidatedFieldAnchor(
          fieldKey: _reasonFieldKey,
          focusNode: _reasonFocus,
        ),
        ValidatedFieldAnchor(fieldKey: _notesFieldKey, focusNode: _notesFocus),
      ],
    );
    if (!valid) return;
    final paise = _parsePaise(_amountCtrl.text);
    if (paise == null) return;

    setState(() {
      _saving = true;
      _submitError = null;
    });
    try {
      await _repo.recordAdjustment(
        workerId: widget.workerId,
        adjustmentType: _type,
        amountPaise: paise,
        reason: _reasonCtrl.text,
        transactionAtUtcMillis: _transactionAtUtc,
        notes: _notesCtrl.text,
        clientRequestId: _clientRequestId,
      );
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          context.l10n.accountingAdjustmentSaved,
        );
        context.pop(true);
      }
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = ValidationLocalizer.localizeDomainException(
          context.l10n,
          e,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = ValidationLocalizer.describeError(context.l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppUnsavedChangesGuard.tracked(
      tracker: _dirty,
      child: AppScaffold(
        title: l10n.accountingAddAdjustmentAction,
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
                    AppDropdown<WorkerAdjustmentType>(
                      label: l10n.accountingAdjustmentTypeLabel,
                      value: _type,
                      items: const [
                        WorkerAdjustmentType.credit,
                        WorkerAdjustmentType.debit,
                      ],
                      itemLabelBuilder: (t) => t == WorkerAdjustmentType.credit
                          ? l10n.accountingAdjustmentCredit
                          : l10n.accountingAdjustmentDebit,
                      onChanged: (v) {
                        _dirty.markDirty();
                        if (v != null) setState(() => _type = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      fieldKey: _amountFieldKey,
                      controller: _amountCtrl,
                      focusNode: _amountFocus,
                      label: l10n.accountingAmountLabel,
                      prefixIcon: AppIcons.rupee,
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
                    AppDatePicker(
                      label: l10n.stockTransactionDateTimeLabel,
                      selectedUtcMillis: _transactionAtUtc,
                      includeTime: true,
                      onDateSelectedUtcMillis: (utc) =>
                          _edit(() => _transactionAtUtc = utc),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      fieldKey: _reasonFieldKey,
                      controller: _reasonCtrl,
                      focusNode: _reasonFocus,
                      label: l10n.accountingAdjustmentReasonLabel,
                      maxLines: 2,
                      maxLength: ValidationLimits.maxNotesLength,
                      validator: ValidationLocalizer.wrap(
                        l10n,
                        (v) => AppValidators.nameValidator(
                          v,
                          maxLength: ValidationLimits.maxNotesLength,
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
                      icon: AppIcons.confirm,
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
