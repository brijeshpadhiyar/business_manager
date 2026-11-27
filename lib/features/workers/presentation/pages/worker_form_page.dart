import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Complete one-screen Worker Creation & Edit workflow:
/// - Worker Details (Name, Phone, Address, Notes, Active/Inactive Status)
/// - Dynamic Multi-Process Assignment (select 0..N processes immediately)
/// - Per-Process Labour Rate Configuration (shows inherited process default
///   rate vs. optional custom worker rate override)
/// - Atomic transactional save via [WorkerRepository.createWorkerWithProcesses]
///   and [WorkerRepository.updateWorkerWithProcesses]
final class WorkerFormPage extends StatefulWidget {
  const WorkerFormPage({super.key, this.workerId});

  final String? workerId;

  bool get isEdit => workerId != null;

  @override
  State<WorkerFormPage> createState() => _WorkerFormPageState();
}

final class _WorkerFormPageState extends State<WorkerFormPage> {
  final _dirty = AppFormDirtyTracker();

  /// setState for a user edit: also marks the form as unsaved.
  void _edit(VoidCallback fn) {
    _dirty.markDirty();
    setState(fn);
  }

  final _formKey = GlobalKey<FormState>();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();
  final _addressFieldKey = GlobalKey<FormFieldState<String>>();
  final _notesFieldKey = GlobalKey<FormFieldState<String>>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _notesFocus = FocusNode();

  final _workerRepo = getIt<WorkerRepository>();
  final _processRepo = getIt<ProcessRepository>();

  bool _isActive = true;
  List<ProcessEntity> _availableProcesses = const [];
  final Set<String> _selectedProcessIds = <String>{};
  final Map<String, TextEditingController> _rateControllers =
      <String, TextEditingController>{};
  final Map<String, int?> _initialCustomRateByProcessId = <String, int?>{};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _submittedOnce = false;
  String? _loadError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _dirty.watch([_nameCtrl, _phoneCtrl, _addressCtrl, _notesCtrl]);
    _loadInitial();
  }

  TextEditingController _rateControllerFor(
    String processId, {
    int? initialPaise,
  }) {
    return _rateControllers.putIfAbsent(
      processId,
      () => TextEditingController(
        text: initialPaise != null
            ? MoneyFormatter.formatPaiseForInput(initialPaise)
            : '',
      ),
    );
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final allProcs = await _processRepo.getProcesses();
      WorkerDetailAggregate? detail;
      if (widget.isEdit) {
        detail = await _workerRepo.getWorkerDetail(widget.workerId!);
        if (!mounted) return;
        if (detail == null) {
          setState(() {
            _isLoading = false;
            _loadError = context.l10n.validationWorkerNotFound;
          });
          return;
        }
      }
      if (!mounted) return;

      final assignedIds = <String>{};
      if (detail != null) {
        final w = detail.worker;
        _nameCtrl.text = w.name;
        _phoneCtrl.text = w.phone ?? '';
        _addressCtrl.text = w.address ?? '';
        _notesCtrl.text = w.notes ?? '';
        _isActive = w.isActive;
        for (final summary in detail.assignedProcesses) {
          final procId = summary.assignment.processId;
          assignedIds.add(procId);
          _selectedProcessIds.add(procId);
          final existingRatePaise = summary.currentRate?.ratePaise;
          _initialCustomRateByProcessId[procId] = existingRatePaise;
          _rateControllerFor(procId, initialPaise: existingRatePaise);
        }
      }

      // Show all active processes plus any currently assigned inactive ones
      final visibleProcesses = allProcs
          .where((p) => p.isActive || assignedIds.contains(p.id))
          .toList();

      setState(() {
        _availableProcesses = visibleProcesses;
        _isLoading = false;
      });
      // Loaded values are the saved state; rate fields are watched too.
      _dirty
        ..watch(_rateControllers.values)
        ..reset();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = ValidationLocalizer.describeError(context.l10n, e);
      });
    }
  }

  Future<void> _refreshProcessesAfterCreate() async {
    try {
      final allProcs = await _processRepo.getProcesses();
      if (!mounted) return;
      final visibleProcesses = allProcs
          .where((p) => p.isActive || _selectedProcessIds.contains(p.id))
          .toList();
      setState(() {
        _availableProcesses = visibleProcesses;
      });
    } catch (_) {
      // Keep current list on transient error
    }
  }

  @override
  void dispose() {
    _dirty.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _notesFocus.dispose();
    for (final ctrl in _rateControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }
    final isValid = FormValidationHelper.validateAndFocusFirstInvalid(
      formKey: _formKey,
      orderedAnchors: [
        ValidatedFieldAnchor(fieldKey: _nameFieldKey, focusNode: _nameFocus),
        ValidatedFieldAnchor(fieldKey: _phoneFieldKey, focusNode: _phoneFocus),
        ValidatedFieldAnchor(
          fieldKey: _addressFieldKey,
          focusNode: _addressFocus,
        ),
        ValidatedFieldAnchor(fieldKey: _notesFieldKey, focusNode: _notesFocus),
      ],
    );
    if (!isValid) return;

    // Validate all selected process custom rates before opening transaction
    final configs = <WorkerProcessConfigInput>[];
    final procNameById = {for (final p in _availableProcesses) p.id: p.name};
    for (final procId in _selectedProcessIds) {
      final rawRate = _rateControllers[procId]?.text.trim() ?? '';
      int? customRatePaise;
      if (rawRate.isNotEmpty) {
        final parsed = AppValidators.parseRupeesToPaiseExact(
          rawRate,
          isRequired: false,
          allowZero: true,
        );
        if (!parsed.validation.isValid || parsed.paise == null) {
          final procName = procNameById[procId] ?? 'process';
          setState(() {
            _submitError = 'Enter a valid non-negative rate for $procName.';
          });
          return;
        }
        customRatePaise = parsed.paise;
      }
      configs.add(
        WorkerProcessConfigInput(
          processId: procId,
          customRatePaise: customRatePaise,
        ),
      );
    }

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      if (widget.isEdit) {
        await _workerRepo.updateWorkerWithProcesses(
          workerId: widget.workerId!,
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          address: _addressCtrl.text,
          notes: _notesCtrl.text,
          isActive: _isActive,
          processConfigs: configs,
        );
      } else {
        await _workerRepo.createWorkerWithProcesses(
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          address: _addressCtrl.text,
          notes: _notesCtrl.text,
          isActive: _isActive,
          processConfigs: configs,
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
        _submitError = ValidationLocalizer.describeError(context.l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final title = widget.isEdit
        ? l10n.workerEditAction
        : l10n.workerCreateAction;

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
          onRetry: _loadInitial,
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
                    // Section 1: Worker Details
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppHeading(
                            '1. Worker Details',
                            level: AppHeadingLevel.h3,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            fieldKey: _nameFieldKey,
                            controller: _nameCtrl,
                            focusNode: _nameFocus,
                            label: l10n.workerNameLabel,
                            prefixIcon: AppIcons.worker,
                            textInputAction: TextInputAction.next,
                            maxLength: ValidationLimits.maxPersonNameLength,
                            onChanged: (_) {
                              if (_submitError != null) {
                                setState(() => _submitError = null);
                              }
                            },
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.nameValidator(
                                v,
                                maxLength: ValidationLimits.maxPersonNameLength,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            fieldKey: _phoneFieldKey,
                            controller: _phoneCtrl,
                            focusNode: _phoneFocus,
                            label: l10n.workerPhoneLabel,
                            prefixIcon: AppIcons.phone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              if (_submitError != null) {
                                setState(() => _submitError = null);
                              }
                            },
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.mobileNumberValidator(v),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            fieldKey: _addressFieldKey,
                            controller: _addressCtrl,
                            focusNode: _addressFocus,
                            label: l10n.workerAddressLabel,
                            prefixIcon: AppIcons.location,
                            maxLines: 2,
                            maxLength: ValidationLimits.maxAddressLength,
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.maxLengthValidator(
                                v,
                                maxLength: ValidationLimits.maxAddressLength,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            fieldKey: _notesFieldKey,
                            controller: _notesCtrl,
                            focusNode: _notesFocus,
                            label: l10n.workerNotesLabel,
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

                    // Section 2: Multi-Process Assignments & Per-Process Labour Pricing
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              AppHeading(
                                '2. Processes & Labour Rates (${_selectedProcessIds.length})',
                                level: AppHeadingLevel.h3,
                              ),
                              AppButton(
                                label: l10n.processCreateAction,
                                icon: AppIcons.add,
                                variant: AppButtonVariant.outlined,
                                onPressed: () async {
                                  await context.push<bool>(
                                    RoutePaths.processCreate,
                                  );
                                  if (mounted) {
                                    await _refreshProcessesAfterCreate();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppText(
                            'Select one or more processes for this worker. Leave a custom rate blank to inherit the process default rate.',
                            variant: AppTextVariant.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_availableProcesses.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.mdBorder,
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: AppText(
                                'No active processes yet. Tap "${l10n.processCreateAction}" above to create processes first, or save this worker and assign processes later.',
                                variant: AppTextVariant.bodySmall,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            for (final proc in _availableProcesses)
                              _buildProcessRateTile(context, proc),
                        ],
                      ),
                    ),

                    if (_submitError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        borderColor: colorScheme.error,
                        child: AppText(_submitError!, color: colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: AppButton(
                  label: l10n.actionSave,
                  icon: AppIcons.confirm,
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

  Widget _buildProcessRateTile(BuildContext context, ProcessEntity proc) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedProcessIds.contains(proc.id);
    final rateCtrl = _rateControllerFor(
      proc.id,
      initialPaise: _initialCustomRateByProcessId[proc.id],
    );
    final hasCustomText = rateCtrl.text.trim().isNotEmpty;

    return Padding(
      key: ValueKey<String>('worker_proc_${proc.id}'),
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdBorder,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.6)
                : colorScheme.outlineVariant,
            width: isSelected ? 1.4 : 1,
          ),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: AppRadius.smBorder,
              onTap: () {
                setState(() {
                  _submitError = null;
                  if (isSelected) {
                    _selectedProcessIds.remove(proc.id);
                  } else {
                    _selectedProcessIds.add(proc.id);
                  }
                });
              },
              child: Row(
                children: [
                  AppCheckbox.bare(
                    value: isSelected,
                    onChanged: (checked) {
                      _dirty.markDirty();
                      setState(() {
                        _submitError = null;
                        if (checked == true) {
                          _selectedProcessIds.add(proc.id);
                        } else {
                          _selectedProcessIds.remove(proc.id);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          proc.name,
                          variant: AppTextVariant.bodyLarge,
                          fontWeight: FontWeight.w700,
                        ),
                        AppText(
                          proc.defaultRatePaise > 0
                              ? 'Process default: ${MoneyFormatter.formatRatePaise(proc.defaultRatePaise, pricingUnit: proc.defaultPricingUnit)}'
                              : 'No process default rate set',
                          variant: AppTextVariant.bodySmall,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    AppStatusBadge(
                      label: hasCustomText
                          ? 'Custom Rate'
                          : (proc.defaultRatePaise > 0
                                ? 'Inherits Default'
                                : 'Rate Optional'),
                      tone: hasCustomText
                          ? AppStatusTone.good
                          : (proc.defaultRatePaise > 0
                                ? AppStatusTone.info
                                : AppStatusTone.neutral),
                    ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: rateCtrl,
                validator: ValidationLocalizer.wrap(
                  context.l10n,
                  (v) => AppValidators.nonNegativeAmountValidator(
                    v,
                    isRequired: false,
                  ),
                ),
                label: context.l10n.workerCustomRateLabel,
                hint: proc.defaultRatePaise > 0
                    ? context.l10n.workerRateInheritHint(
                        MoneyFormatter.formatRatePaise(
                          proc.defaultRatePaise,
                          pricingUnit: proc.defaultPricingUnit,
                        ),
                      )
                    : 'e.g. 25.00',
                prefixIcon: AppIcons.rupee,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AppInputFormatters.currencyDecimal],
                onChanged: (_) => _edit(() {
                  _submitError = null;
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
