import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/rates/domain/repositories/rate_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Add a new historical per-piece rate, or safely edit an unreferenced rate.
final class RateFormPage extends StatefulWidget {
  const RateFormPage({
    super.key,
    required this.workerId,
    this.initialProcessId,
    this.rateId,
  });

  final String workerId;
  final String? initialProcessId;
  final String? rateId;

  bool get isEdit => rateId != null;

  @override
  State<RateFormPage> createState() => _RateFormPageState();
}

final class _RateFormPageState extends State<RateFormPage> {
  final _dirty = AppFormDirtyTracker();

  /// setState for a user edit: also marks the form as unsaved.
  void _edit(VoidCallback fn) {
    _dirty.markDirty();
    setState(fn);
  }

  final _formKey = GlobalKey<FormState>();
  final _rateFieldKey = GlobalKey<FormFieldState<String>>();
  final _notesFieldKey = GlobalKey<FormFieldState<String>>();
  final _effectiveToAnchorKey = GlobalKey();
  final _rateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _rateFocus = FocusNode();
  final _notesFocus = FocusNode();
  final _processRepo = getIt<ProcessRepository>();
  final _rateRepo = getIt<RateRepository>();

  List<ProcessEntity> _processes = const [];
  String? _selectedProcessId;
  int _effectiveFromUtcMillis = _isoToUtcMillis(
    IstDateTimeHelper.toIstBusinessDate(IstDateTimeHelper.nowUtcMillis()),
  );
  int? _effectiveToUtcMillis;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _submittedOnce = false;
  bool _isLockedByHistory = false;
  String? _loadError;
  String? _submitError;

  static int _isoToUtcMillis(String iso) {
    final parts = iso.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    ).millisecondsSinceEpoch;
  }

  static int? _parseRupeesToPaise(String raw) {
    return AppValidators.parseRupeesToPaiseExact(raw, allowZero: true).paise;
  }

  static String _paiseToEditableRupees(int paise) {
    return MoneyFormatter.formatPaiseForInput(paise);
  }

  @override
  void initState() {
    super.initState();
    _dirty.watch([_rateCtrl, _notesCtrl]);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final processes = await _processRepo.getProcesses();
      if (!mounted) return;
      _processes = processes;

      if (widget.isEdit) {
        final existing = await _rateRepo.getRateById(widget.rateId!);
        if (!mounted) return;
        if (existing == null) {
          setState(() {
            _isLoading = false;
            _loadError = 'Rate not found.';
          });
          return;
        }
        final locked = await _rateRepo.isRateLockedByHistory(existing.id);
        if (!mounted) return;
        _selectedProcessId = existing.processId;
        _rateCtrl.text = _paiseToEditableRupees(existing.ratePaise);
        _effectiveFromUtcMillis = _isoToUtcMillis(existing.effectiveFrom);
        _effectiveToUtcMillis = existing.effectiveTo != null
            ? _isoToUtcMillis(existing.effectiveTo!)
            : null;
        _notesCtrl.text = existing.notes ?? '';
        _isLockedByHistory = locked;
      } else {
        _selectedProcessId =
            widget.initialProcessId ??
            (processes.isNotEmpty ? processes.first.id : null);
      }
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
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    _rateFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  String? _inlineDateRangeError(BuildContext context) {
    if (_effectiveToUtcMillis == null) return null;
    final fromIso = IstDateTimeHelper.toIstBusinessDate(
      _effectiveFromUtcMillis,
    );
    final toIso = IstDateTimeHelper.toIstBusinessDate(_effectiveToUtcMillis!);
    final check = AppValidators.isoDateRangeValidator(
      startIso: fromIso,
      endIso: toIso,
    );
    return check.isValid ? null : context.l10n.ratesToBeforeFromError;
  }

  Future<void> _save() async {
    if (_isSaving || _isLockedByHistory) return;
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }
    final formValid = FormValidationHelper.validateAndFocusFirstInvalid(
      formKey: _formKey,
      orderedAnchors: [
        ValidatedFieldAnchor(fieldKey: _rateFieldKey, focusNode: _rateFocus),
        ValidatedFieldAnchor(fieldKey: _notesFieldKey, focusNode: _notesFocus),
      ],
    );
    if (!formValid) return;

    final dateErr = _inlineDateRangeError(context);
    if (dateErr != null) {
      FormValidationHelper.scrollToAnchor(_effectiveToAnchorKey);
      return;
    }

    final processId = _selectedProcessId;
    if (processId == null) return;

    final ratePaise = _parseRupeesToPaise(_rateCtrl.text);
    if (ratePaise == null) return;

    final effectiveFromIso = IstDateTimeHelper.toIstBusinessDate(
      _effectiveFromUtcMillis,
    );
    final effectiveToIso = _effectiveToUtcMillis != null
        ? IstDateTimeHelper.toIstBusinessDate(_effectiveToUtcMillis!)
        : null;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      if (widget.isEdit) {
        await _rateRepo.updateRate(
          rateId: widget.rateId!,
          ratePaise: ratePaise,
          effectiveFrom: effectiveFromIso,
          effectiveTo: effectiveToIso,
          notes: _notesCtrl.text,
        );
      } else {
        // Check if an earlier open-ended rate can be safely auto-closed with user confirmation
        var autoClose = false;
        final openRate = await _rateRepo.findAutoClosableOpenRate(
          workerId: widget.workerId,
          processId: processId,
          newEffectiveFrom: effectiveFromIso,
        );
        if (openRate != null && mounted) {
          final l10n = context.l10n;
          final confirmed = await AppDialog.showConfirmation(
            context,
            title: l10n.ratesAutoCloseTitle,
            message: l10n.ratesAutoCloseMessage,
            confirmLabel: l10n.actionConfirm,
            cancelLabel: l10n.actionCancel,
          );
          if (confirmed != true) {
            if (mounted) setState(() => _isSaving = false);
            return;
          }
          autoClose = true;
        }

        await _rateRepo.addRate(
          workerId: widget.workerId,
          processId: processId,
          ratePaise: ratePaise,
          effectiveFrom: effectiveFromIso,
          effectiveTo: effectiveToIso,
          notes: _notesCtrl.text,
          autoClosePreviousOpenRate: autoClose,
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
    final title = widget.isEdit ? l10n.ratesEditHeading : l10n.ratesAddHeading;

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

    final selectedProcess = _processes
        .where((p) => p.id == _selectedProcessId)
        .firstOrNull;

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
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isLockedByHistory) ...[
                      AppText(
                        l10n.ratesLockedByHistoryError,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppDropdown<ProcessEntity>(
                      label: l10n.ratesFilterProcessLabel,
                      hint: l10n.ratesSelectProcessHint,
                      value: selectedProcess,
                      enabled: !widget.isEdit && !_isLockedByHistory,
                      items: _processes,
                      itemLabelBuilder: (p) => p.name,
                      validator: (v) =>
                          v == null ? l10n.validationRequired : null,
                      onChanged: (p) => _edit(() => _selectedProcessId = p?.id),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      fieldKey: _rateFieldKey,
                      controller: _rateCtrl,
                      focusNode: _rateFocus,
                      label: l10n.ratesAmountLabel,
                      prefixIcon: Icons.currency_rupee,
                      enabled: !_isLockedByHistory,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        if (_submitError != null) {
                          setState(() => _submitError = null);
                        }
                      },
                      validator: ValidationLocalizer.wrap(
                        l10n,
                        (v) => AppValidators.nonNegativeAmountValidator(v),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppDatePicker(
                      label: l10n.ratesEffectiveFromLabel,
                      selectedUtcMillis: _effectiveFromUtcMillis,
                      enabled: !_isLockedByHistory,
                      onDateSelectedUtcMillis: (utc) => _edit(() {
                        _effectiveFromUtcMillis = utc;
                        _submitError = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppDatePicker(
                      key: _effectiveToAnchorKey,
                      label: l10n.ratesEffectiveToLabel,
                      hint: l10n.ratesOngoingLabel,
                      selectedUtcMillis: _effectiveToUtcMillis,
                      enabled: !_isLockedByHistory,
                      errorText: _inlineDateRangeError(context),
                      onDateSelectedUtcMillis: (utc) => _edit(() {
                        _effectiveToUtcMillis = utc;
                        _submitError = null;
                      }),
                    ),
                    if (_effectiveToUtcMillis != null &&
                        !_isLockedByHistory) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AppButton(
                          label: l10n.ratesClearEffectiveTo,
                          variant: AppButtonVariant.text,
                          onPressed: () => setState(() {
                            _effectiveToUtcMillis = null;
                            _submitError = null;
                          }),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      fieldKey: _notesFieldKey,
                      controller: _notesCtrl,
                      focusNode: _notesFocus,
                      label: l10n.ratesNotesLabel,
                      enabled: !_isLockedByHistory,
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
                      icon: Icons.check,
                      isExpanded: true,
                      isLoading: _isSaving,
                      onPressed: _isLockedByHistory ? null : _save,
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
