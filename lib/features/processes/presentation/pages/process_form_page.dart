import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Create or edit a dynamic production process with full billing rules and
/// process-level default labour rate configuration.
final class ProcessFormPage extends StatefulWidget {
  const ProcessFormPage({super.key, this.processId});

  final String? processId;

  bool get isEdit => processId != null;

  @override
  State<ProcessFormPage> createState() => _ProcessFormPageState();
}

final class _ProcessFormPageState extends State<ProcessFormPage> {
  final _dirty = AppFormDirtyTracker();

  /// setState for a user edit: also marks the form as unsaved.
  void _edit(VoidCallback fn) {
    _dirty.markDirty();
    setState(fn);
  }

  final _formKey = GlobalKey<FormState>();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _descFieldKey = GlobalKey<FormFieldState<String>>();
  final _rateFieldKey = GlobalKey<FormFieldState<String>>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();
  final _rateFocus = FocusNode();
  final _repository = getIt<ProcessRepository>();

  // Uses sentinel 'GLOBAL' in dropdown because DropdownButtonFormField null value shows hint.
  String _billingChoice = 'GLOBAL';
  String _pricingUnit = 'PER_PIECE';
  bool _includeDamaged = false;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _submittedOnce = false;
  String? _loadError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _dirty.watch([_nameCtrl, _descCtrl, _rateCtrl]);
    if (widget.isEdit) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final detail = await _repository.getProcessDetail(widget.processId!);
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'Process not found.';
        });
        return;
      }
      final proc = detail.process;
      _nameCtrl.text = proc.name;
      _descCtrl.text = proc.description ?? '';
      _rateCtrl.text = proc.defaultRatePaise > 0
          ? MoneyFormatter.formatPaiseForInput(proc.defaultRatePaise)
          : '';
      _billingChoice = proc.billingModeOverride?.dbValue ?? 'GLOBAL';
      _pricingUnit = proc.defaultPricingUnit;
      _includeDamaged = proc.includeDamagedInLabour;
      _isActive = proc.isActive;
      _dirty.reset();
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _dirty.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _rateCtrl.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    _rateFocus.dispose();
    super.dispose();
  }

  String _pricingUnitLabel(String unit) {
    return switch (unit) {
      'PER_DOZEN' => 'Per Dozen (12 pcs)',
      'PER_LOT' => 'Per Lot',
      'FIXED_AMOUNT' => 'Fixed Amount',
      _ => 'Per Piece (Default)',
    };
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }
    final valid = FormValidationHelper.validateAndFocusFirstInvalid(
      formKey: _formKey,
      orderedAnchors: [
        ValidatedFieldAnchor(fieldKey: _nameFieldKey, focusNode: _nameFocus),
        ValidatedFieldAnchor(fieldKey: _descFieldKey, focusNode: _descFocus),
        ValidatedFieldAnchor(fieldKey: _rateFieldKey, focusNode: _rateFocus),
      ],
    );
    if (!valid) return;

    final parsedRate = AppValidators.parseRupeesToPaiseExact(
      _rateCtrl.text,
      isRequired: false,
      allowZero: true,
    );
    if (!parsedRate.validation.isValid) {
      return;
    }
    final defaultRatePaise = parsedRate.paise ?? 0;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final override = _billingChoice == 'GLOBAL'
        ? null
        : ProcessBillingModeOverride.fromDbValue(_billingChoice);

    try {
      if (widget.isEdit) {
        await _repository.updateProcess(
          processId: widget.processId!,
          name: _nameCtrl.text,
          description: _descCtrl.text,
          isActive: _isActive,
          billingModeOverride: override,
          includeDamagedInLabour: _includeDamaged,
          defaultRatePaise: defaultRatePaise,
          defaultPricingUnit: _pricingUnit,
        );
      } else {
        await _repository.createProcess(
          name: _nameCtrl.text,
          description: _descCtrl.text,
          isActive: _isActive,
          billingModeOverride: override,
          includeDamagedInLabour: _includeDamaged,
          defaultRatePaise: defaultRatePaise,
          defaultPricingUnit: _pricingUnit,
        );
      }
      if (mounted) {
        context.pop(true);
      }
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = ValidationLocalizer.localizeDomainException(
          context.l10n,
          e,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final title = widget.isEdit
        ? l10n.processEditAction
        : l10n.processCreateAction;

    if (_isLoading) {
      return AppScaffold(title: title, body: const AppLoader());
    }
    if (_loadError != null) {
      return AppScaffold(
        title: title,
        body: AppErrorView(
          title: l10n.errorUnexpected,
          message: _loadError,
          retryLabel: l10n.actionRetry,
          onRetry: _loadExisting,
        ),
      );
    }

    return AppUnsavedChangesGuard.tracked(
      tracker: _dirty,
      child: AppScaffold(
        title: title,
        contentWidth: AppContentWidth.narrow,
        body: Form(
          key: _formKey,
          autovalidateMode: _submittedOnce
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppHeading(
                            l10n.processDetailsHeading,
                            level: AppHeadingLevel.h3,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            fieldKey: _nameFieldKey,
                            controller: _nameCtrl,
                            focusNode: _nameFocus,
                            label: l10n.processNameLabel,
                            prefixIcon: Icons.precision_manufacturing_outlined,
                            textInputAction: TextInputAction.next,
                            maxLength: ValidationLimits.maxShortNameLength,
                            onChanged: (_) {
                              if (_submitError != null) {
                                setState(() => _submitError = null);
                              }
                            },
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.nameValidator(
                                v,
                                maxLength: ValidationLimits.maxShortNameLength,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            fieldKey: _descFieldKey,
                            controller: _descCtrl,
                            focusNode: _descFocus,
                            label: l10n.processDescriptionLabel,
                            maxLines: 3,
                            maxLength: ValidationLimits.maxNotesLength,
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.maxLengthValidator(
                                v,
                                maxLength: ValidationLimits.maxNotesLength,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppSwitch(
                            label: _isActive
                                ? l10n.statusActive
                                : l10n.statusInactive,
                            value: _isActive,
                            onChanged: (v) => _edit(() => _isActive = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppHeading(
                            'Labour Billing & Default Rate',
                            level: AppHeadingLevel.h3,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppText(
                            'Workers assigned to this process inherit the default labour rate unless a worker-specific custom rate is set.',
                            variant: AppTextVariant.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppDropdown<String>(
                            label: l10n.processBillingOverrideLabel,
                            value: _billingChoice,
                            items: const [
                              'GLOBAL',
                              'RECEIVED_QTY',
                              'GIVEN_QTY',
                            ],
                            itemLabelBuilder: (item) => switch (item) {
                              'RECEIVED_QTY' => l10n.billingModeReceivedQty,
                              'GIVEN_QTY' => l10n.billingModeGivenQty,
                              _ => l10n.processBillingInheritGlobal,
                            },
                            onChanged: (v) {
                              _dirty.markDirty();
                              if (v != null) setState(() => _billingChoice = v);
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppSwitch(
                            label: l10n.processIncludeDamagedLabel,
                            value: _includeDamaged,
                            onChanged: (v) => _edit(() => _includeDamaged = v),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            fieldKey: _rateFieldKey,
                            controller: _rateCtrl,
                            focusNode: _rateFocus,
                            label: 'Default Labour Rate (₹)',
                            hint: '0.00',
                            prefixIcon: Icons.currency_rupee_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              AppInputFormatters.currencyDecimal,
                            ],
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.nonNegativeAmountValidator(
                                v,
                                isRequired: false,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppDropdown<String>(
                            label: 'Pricing Unit',
                            value: _pricingUnit,
                            items: const [
                              'PER_PIECE',
                              'PER_DOZEN',
                              'PER_LOT',
                              'FIXED_AMOUNT',
                            ],
                            itemLabelBuilder: _pricingUnitLabel,
                            onChanged: (v) {
                              _dirty.markDirty();
                              if (v != null) setState(() => _pricingUnit = v);
                            },
                          ),
                          if (_submitError != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            AppText(_submitError!, color: colorScheme.error),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: AppButton(
                  label: l10n.actionSave,
                  icon: Icons.check,
                  isExpanded: true,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
