import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _rateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
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
    final clean = raw.trim();
    if (clean.isEmpty) return null;
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(clean);
    if (match == null) return null;
    final rupees = int.parse(match.group(1)!);
    final fracStr = (match.group(2) ?? '').padRight(2, '0');
    final paise = int.parse(fracStr);
    return rupees * 100 + paise;
  }

  static String _paiseToEditableRupees(int paise) {
    final rupees = paise ~/ 100;
    final rem = paise % 100;
    if (rem == 0) return rupees.toString();
    return '$rupees.${rem.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
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
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _mapValidationError(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'rate_overlap' => l10n.ratesOverlapError,
      'rate_multiple_open_ended' => l10n.ratesMultipleOpenEndedError,
      'rate_to_before_from' => l10n.ratesToBeforeFromError,
      'rate_locked_by_history' => l10n.ratesLockedByHistoryError,
      'rate_negative' => l10n.validationValidPrice,
      _ => code,
    };
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving || _isLockedByHistory) return;
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
        _submitError = _mapValidationError(context, e.code);
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

    return AppScaffold(
      title: title,
      body: Form(
        key: _formKey,
        child: ListView(
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
                    onChanged: (p) =>
                        setState(() => _selectedProcessId = p?.id),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _rateCtrl,
                    label: l10n.ratesAmountLabel,
                    prefixIcon: Icons.currency_rupee,
                    enabled: !_isLockedByHistory,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.validationRequired;
                      }
                      return _parseRupeesToPaise(v) == null
                          ? l10n.validationValidPrice
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDatePicker(
                    label: l10n.ratesEffectiveFromLabel,
                    selectedUtcMillis: _effectiveFromUtcMillis,
                    enabled: !_isLockedByHistory,
                    onDateSelectedUtcMillis: (utc) =>
                        setState(() => _effectiveFromUtcMillis = utc),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDatePicker(
                    label: l10n.ratesEffectiveToLabel,
                    hint: l10n.ratesOngoingLabel,
                    selectedUtcMillis: _effectiveToUtcMillis,
                    enabled: !_isLockedByHistory,
                    onDateSelectedUtcMillis: (utc) =>
                        setState(() => _effectiveToUtcMillis = utc),
                  ),
                  if (_effectiveToUtcMillis != null && !_isLockedByHistory) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        label: l10n.ratesClearEffectiveTo,
                        variant: AppButtonVariant.text,
                        onPressed: () =>
                            setState(() => _effectiveToUtcMillis = null),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _notesCtrl,
                    label: l10n.ratesNotesLabel,
                    enabled: !_isLockedByHistory,
                    maxLines: 2,
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
    );
  }
}
