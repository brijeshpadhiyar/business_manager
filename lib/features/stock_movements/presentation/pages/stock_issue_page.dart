import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/calculators/labour_calculator.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/business_profile/domain/repositories/business_profile_repository.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Streamlined 4-step Stock Issue workflow (+ Step 5 Success Summary):
/// 1. Select Stock (Lot / Design / Colour + Available Good)
/// 2. Select Work (Active Process, Eligible Worker, Locked Rate & Billing Mode)
/// 3. Enter Quantity (Large clear input, instant available-stock validation)
/// 4. Confirm Issue (Compact summary + expected labour + atomic submit)
/// 5. Success (Updated available stock + Issue More / View Details)
final class StockIssuePage extends StatefulWidget {
  const StockIssuePage({
    super.key,
    this.initialDesignColourId,
    this.initialProcessId,
    this.initialWorkerId,
  });

  final String? initialDesignColourId;
  final String? initialProcessId;
  final String? initialWorkerId;

  @override
  State<StockIssuePage> createState() => _StockIssuePageState();
}

final class _StockIssuePageState extends State<StockIssuePage> {
  final _dirty = AppFormDirtyTracker();

  /// setState for a user edit: also marks the form as unsaved.
  void _edit(VoidCallback fn) {
    _dirty.markDirty();
    setState(fn);
  }

  final _formKey = GlobalKey<FormState>();
  final _stockSearchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _qtyFocus = FocusNode();
  final _notesCtrl = TextEditingController();
  final _overrideRateCtrl = TextEditingController();
  final _overrideReasonCtrl = TextEditingController();

  final _stockRepo = getIt<StockMovementRepository>();
  final _processRepo = getIt<ProcessRepository>();
  final _profileRepo = getIt<BusinessProfileRepository>();
  final _idGen = getIt<IdGenerator>();
  static const LabourCalculator _labourCalc = LabourCalculator();

  late String _clientRequestId;

  bool _loading = true;
  bool _saving = false;
  bool _onlyInStock = true;
  bool _pickingStock = true;
  bool _showAdvanced = false;
  String? _loadError;
  String? _submitError;

  List<DesignColourStockBalance> _allBalances = const [];
  List<ProcessEntity> _activeProcesses = const [];
  List<ProcessAssignedWorkerSummary> _eligibleWorkers = const [];
  RecentIssueSuggestions _recentSuggestions = const RecentIssueSuggestions();
  BillingMode _globalBillingMode = BillingMode.receivedQty;

  String? _selectedColourId;
  String? _selectedProcessId;
  String? _selectedWorkerId;
  int _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();

  RateResolutionResult? _ratePreview;
  bool _overrideRate = false;

  // Step 5 Success state
  _IssuedSuccessInfo? _successInfo;

  @override
  void initState() {
    super.initState();
    _dirty.watch([
      _qtyCtrl,
      _notesCtrl,
      _overrideRateCtrl,
      _overrideReasonCtrl,
    ]);
    _clientRequestId = _idGen.nextRequestId();
    _loadInitial();
  }

  @override
  void dispose() {
    _dirty.dispose();
    _stockSearchCtrl.dispose();
    _qtyCtrl.dispose();
    _qtyFocus.dispose();
    _notesCtrl.dispose();
    _overrideRateCtrl.dispose();
    _overrideReasonCtrl.dispose();
    super.dispose();
  }

  DesignColourStockBalance? get _selectedBalance {
    if (_selectedColourId == null) return null;
    for (final b in _allBalances) {
      if (b.designColourId == _selectedColourId) return b;
    }
    return null;
  }

  ProcessEntity? get _selectedProcess {
    if (_selectedProcessId == null) return null;
    for (final p in _activeProcesses) {
      if (p.id == _selectedProcessId) return p;
    }
    return null;
  }

  ProcessAssignedWorkerSummary? get _selectedWorker {
    if (_selectedWorkerId == null) return null;
    for (final w in _eligibleWorkers) {
      if (w.workerId == _selectedWorkerId) return w;
    }
    return null;
  }

  BillingMode get _effectiveBillingMode {
    final override = _selectedProcess?.billingModeOverride;
    final mappedOverride = override == null
        ? null
        : BillingMode.fromDbValue(override.dbValue);
    return _labourCalc.resolveEffectiveBillingMode(
      globalDefault: _globalBillingMode,
      processOverride: mappedOverride,
    );
  }

  int? get _effectiveRatePaise {
    if (_overrideRate) {
      return _parseRupeesToPaise(_overrideRateCtrl.text);
    }
    final preview = _ratePreview;
    return switch (preview) {
      RateResolutionFound(:final rate) => rate.ratePaise,
      RateResolutionProcessDefault(:final ratePaise) => ratePaise,
      _ => null,
    };
  }

  int get _parsedQty => int.tryParse(_qtyCtrl.text.trim()) ?? 0;

  Future<void> _loadInitial({String? preserveColourId}) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _stockRepo.getAllDesignColourBalances(),
        _processRepo.getProcesses(isActiveFilter: true),
        _profileRepo.getProfile(),
        _stockRepo.getRecentIssueSuggestions(),
      ]);
      final balances = results[0] as List<DesignColourStockBalance>;
      final procs = results[1] as List<ProcessEntity>;
      final profile = results[2] as BusinessProfileEntity;
      final recents = results[3] as RecentIssueSuggestions;

      final requestedColour = preserveColourId ?? widget.initialDesignColourId;
      String? initialColour;
      if (requestedColour != null &&
          balances.any((b) => b.designColourId == requestedColour)) {
        initialColour = requestedColour;
      } else if (balances.length == 1 &&
          balances.first.physicalAvailableInHouse > 0) {
        initialColour = balances.first.designColourId;
      }

      final requestedProc = widget.initialProcessId;
      String? nextProcessId;
      if (_selectedProcessId != null &&
          procs.any((p) => p.id == _selectedProcessId)) {
        nextProcessId = _selectedProcessId;
      } else if (requestedProc != null &&
          procs.any((p) => p.id == requestedProc)) {
        nextProcessId = requestedProc;
      } else if (procs.isNotEmpty) {
        nextProcessId = procs.first.id;
      }

      if (!mounted) return;
      setState(() {
        _allBalances = balances;
        _activeProcesses = procs;
        _recentSuggestions = recents;
        _globalBillingMode = profile.defaultBillingMode;
        _selectedColourId = initialColour;
        _pickingStock = initialColour == null;
        _selectedProcessId = nextProcessId;
        _loading = false;
      });
      if (_selectedProcessId != null) {
        await _loadWorkersForProcess(
          _selectedProcessId!,
          preferredWorkerId: widget.initialWorkerId,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _loadWorkersForProcess(
    String processId, {
    String? preferredWorkerId,
  }) async {
    final detail = await _processRepo.getProcessDetail(processId);
    final activeAssigned = (detail?.assignedWorkers ?? const [])
        .where((w) => w.workerIsActive)
        .toList();
    if (!mounted) return;
    String? chosenWorkerId;
    if (preferredWorkerId != null &&
        activeAssigned.any((w) => w.workerId == preferredWorkerId)) {
      chosenWorkerId = preferredWorkerId;
    } else if (activeAssigned.isNotEmpty) {
      chosenWorkerId = activeAssigned.first.workerId;
    }
    setState(() {
      _eligibleWorkers = activeAssigned;
      _selectedWorkerId = chosenWorkerId;
      _ratePreview = null;
      _submitError = null;
    });
    await _refreshRatePreview();
  }

  Future<void> _refreshRatePreview() async {
    if (_selectedWorkerId == null || _selectedProcessId == null) {
      setState(() => _ratePreview = null);
      return;
    }
    final result = await _stockRepo.previewRate(
      workerId: _selectedWorkerId!,
      processId: _selectedProcessId!,
      transactionAtUtcMillis: _transactionAtUtc,
    );
    if (!mounted) return;
    setState(() => _ratePreview = result);
  }

  int? _parseRupeesToPaise(String text) {
    return AppValidators.parseRupeesToPaiseExact(text, allowZero: true).paise;
  }

  void _selectStock(DesignColourStockBalance b) {
    _dirty.markDirty();
    setState(() {
      _selectedColourId = b.designColourId;
      _pickingStock = false;
      _submitError = null;
      if (_parsedQty > b.physicalAvailableInHouse) {
        _qtyCtrl.clear();
      }
    });
  }

  void _addQuickQty(int delta, int maxAvailable) {
    _dirty.markDirty();
    final next = (_parsedQty + delta).clamp(0, maxAvailable);
    setState(() {
      _qtyCtrl.text = next > 0 ? '$next' : '';
      _submitError = null;
    });
  }

  void _setExactQty(int qty) {
    _dirty.markDirty();
    setState(() {
      _qtyCtrl.text = qty > 0 ? '$qty' : '';
      _submitError = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;
    final l10n = context.l10n;
    final balance = _selectedBalance;
    final proc = _selectedProcess;
    final worker = _selectedWorker;

    if (balance == null || proc == null || worker == null) {
      setState(() => _submitError = l10n.validationRequired);
      return;
    }

    final qty = _parsedQty;
    if (qty <= 0) {
      setState(() => _submitError = l10n.stockInvalidQtyError);
      return;
    }
    if (qty > balance.physicalAvailableInHouse) {
      setState(() => _submitError = l10n.stockInsufficientGoodError);
      return;
    }

    int? overridePaise;
    if (_overrideRate) {
      overridePaise = _parseRupeesToPaise(_overrideRateCtrl.text);
      if (overridePaise == null || _overrideReasonCtrl.text.trim().isEmpty) {
        setState(() {
          _showAdvanced = true;
          _submitError = l10n.validationRequired;
        });
        return;
      }
    }

    // Unusual-action confirmation guard (never interrupts routine issues)
    final warnings = <String>[];
    if (qty == balance.physicalAvailableInHouse &&
        balance.physicalAvailableInHouse >= 50) {
      warnings.add(l10n.stockUnusualFullStockWarning(qty));
    }
    if (_overrideRate) {
      warnings.add(l10n.stockUnusualRateOverrideWarning);
    }
    final daysBackdated =
        (IstDateTimeHelper.nowUtcMillis() - _transactionAtUtc) ~/
        Duration.millisecondsPerDay;
    if (daysBackdated > 7) {
      warnings.add(l10n.stockUnusualBackdatedWarning(daysBackdated));
    }
    if (warnings.isNotEmpty) {
      final confirmed = await AppDialog.showConfirmation(
        context,
        title: l10n.stockUnusualConfirmTitle,
        message: warnings.map((w) => '• $w').join('\n'),
        confirmLabel: l10n.stockConfirmIssueAction,
        cancelLabel: l10n.actionCancel,
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _saving = true;
      _submitError = null;
    });

    try {
      final movement = await _stockRepo.issueStock(
        designColourId: balance.designColourId,
        processId: proc.id,
        workerId: worker.workerId,
        quantity: qty,
        transactionAtUtcMillis: _transactionAtUtc,
        notes: _notesCtrl.text,
        allowRateOverride: _overrideRate,
        overrideRatePaise: overridePaise,
        overrideReason: _overrideReasonCtrl.text,
        clientRequestId: _clientRequestId,
      );

      final updatedBalance = await _stockRepo.getDesignColourBalance(
        balance.designColourId,
      );

      if (!mounted) return;
      setState(() {
        _saving = false;
        _successInfo = _IssuedSuccessInfo(
          movement: movement,
          lotNumber: balance.lotNumber,
          designName: balance.designName,
          colourName: balance.colourName,
          processName: proc.name,
          workerName: worker.workerName,
          updatedAvailableGood:
              updatedBalance?.physicalAvailableInHouse ??
              (balance.physicalAvailableInHouse - qty),
          effectiveBillingMode:
              movement.lockedBillingMode ?? _effectiveBillingMode,
        );
      });
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

  Future<void> _issueMore() async {
    final prevColourId = _selectedColourId;
    setState(() {
      _successInfo = null;
      _qtyCtrl.clear();
      _notesCtrl.clear();
      _overrideRate = false;
      _overrideRateCtrl.clear();
      _overrideReasonCtrl.clear();
      _submitError = null;
      _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();
      _clientRequestId = _idGen.nextRequestId();
    });
    await _loadInitial(preserveColourId: prevColourId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return AppScaffold(
        title: l10n.stockIssueAction,
        body: const AppSkeletonList(itemCount: 3),
      );
    }
    if (_loadError != null) {
      return AppScaffold(
        title: l10n.stockIssueAction,
        body: AppErrorView(
          title: l10n.errorUnexpected,
          message: _loadError,
          retryLabel: l10n.actionRetry,
          onRetry: _loadInitial,
        ),
      );
    }

    if (_successInfo != null) {
      return _buildSuccessView(context, _successInfo!);
    }

    if (_allBalances.isEmpty) {
      return AppScaffold(
        title: l10n.stockIssueAction,
        body: AppEmptyState(
          icon: Icons.inventory_2_outlined,
          title: l10n.stockNoStockItemsTitle,
          subtitle: l10n.stockNoStockItemsSubtitle,
        ),
      );
    }

    final balance = _selectedBalance;
    final proc = _selectedProcess;
    final worker = _selectedWorker;
    final ratePaise = _effectiveRatePaise;
    final qty = _parsedQty;
    final qtyExceeds =
        balance != null && qty > balance.physicalAvailableInHouse;
    final step1Done = balance != null && balance.physicalAvailableInHouse > 0;
    final step2Done = proc != null && worker != null && ratePaise != null;
    final step3Done = step1Done && qty > 0 && !qtyExceeds;
    final canSubmit = step1Done && step2Done && step3Done && !_saving;

    return AppUnsavedChangesGuard.tracked(
      tracker: _dirty,
      child: AppScaffold(
        title: l10n.stockIssueAction,
        // Confirm stays pinned at the bottom: no scrolling past three steps
        // to find it on a phone.
        bottomAction: AppButton(
          label: l10n.stockConfirmIssueAction,
          icon: Icons.outbox_rounded,
          isExpanded: true,
          isLoading: _saving,
          onPressed: canSubmit ? _submit : null,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _StepProgressStrip(
                steps: [
                  _StepItem(
                    number: 1,
                    label: l10n.stockStepSelectStock,
                    completed: step1Done,
                    active: !step1Done || _pickingStock,
                  ),
                  _StepItem(
                    number: 2,
                    label: l10n.stockStepSelectWork,
                    completed: step2Done,
                    active: step1Done && !step2Done,
                  ),
                  _StepItem(
                    number: 3,
                    label: l10n.stockStepEnterQty,
                    completed: step3Done,
                    active: step1Done && step2Done && !step3Done,
                  ),
                  _StepItem(
                    number: 4,
                    label: l10n.stockStepConfirm,
                    completed: false,
                    active: canSubmit,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // STEP 1: SELECT STOCK
              _buildStep1SelectStock(context, balance),
              const SizedBox(height: AppSpacing.md),

              // STEP 2: SELECT WORK (Process, Eligible Worker, Rate & Billing)
              if (balance != null) ...[
                _buildStep2SelectWork(context),
                const SizedBox(height: AppSpacing.md),

                // STEP 3: ENTER QUANTITY
                _buildStep3EnterQuantity(context, balance, qtyExceeds),
                const SizedBox(height: AppSpacing.md),

                // STEP 4: COMPACT CONFIRMATION SUMMARY & SUBMIT
                _buildStep4ConfirmCard(
                  context,
                  balance: balance,
                  proc: proc,
                  worker: worker,
                  ratePaise: ratePaise,
                  qty: qty,
                  canSubmit: canSubmit,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1SelectStock(
    BuildContext context,
    DesignColourStockBalance? selected,
  ) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (selected != null && !_pickingStock) {
      return AppCard(
        borderColor: context.semanticColors.goodStock.withValues(alpha: 0.45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _StepBadge(number: 1, completed: true),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppText(
                    l10n.stockStepSelectStock,
                    variant: AppTextVariant.label,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppButton(
                  label: l10n.stockChangeSelection,
                  variant: AppButtonVariant.text,
                  onPressed: () => setState(() => _pickingStock = true),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              '${selected.lotNumber} • ${selected.designName} • ${selected.colourName}',
              variant: AppTextVariant.bodyLarge,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppStatusBadge(
                  label:
                      '${l10n.stockAvailableGoodLabel}: ${selected.physicalAvailableInHouse} ${l10n.piecesUnit}',
                  tone: selected.physicalAvailableInHouse > 0
                      ? AppStatusTone.good
                      : AppStatusTone.damaged,
                  icon: Icons.check_circle_outline_rounded,
                ),
                if (selected.totalPendingWithWorkers > 0)
                  AppStatusBadge(
                    label:
                        '${l10n.stockPendingWorkerLabel}: ${selected.totalPendingWithWorkers} ${l10n.piecesUnit}',
                    tone: AppStatusTone.pending,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    final query = _stockSearchCtrl.text.trim().toLowerCase();
    final filtered =
        _allBalances.where((b) {
          if (_onlyInStock && b.physicalAvailableInHouse <= 0) return false;
          if (query.isEmpty) return true;
          return '${b.lotNumber} ${b.designName} ${b.colourName}'
              .toLowerCase()
              .contains(query);
        }).toList()..sort(
          (a, b) =>
              b.physicalAvailableInHouse.compareTo(a.physicalAvailableInHouse),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _StepBadge(number: 1, completed: false),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppHeading(
                  l10n.stockStepSelectStock,
                  level: AppHeadingLevel.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_recentSuggestions.inStockDesignColourIds.isNotEmpty &&
              query.isEmpty) ...[
            AppText(
              l10n.stockRecentStockSuggestionsLabel,
              variant: AppTextVariant.label,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final id in _recentSuggestions.inStockDesignColourIds)
                  for (final b in _allBalances)
                    if (b.designColourId == id)
                      ActionChip(
                        avatar: const Icon(Icons.history_rounded, size: 16),
                        label: Text(
                          '${b.lotNumber} • ${b.colourName} (${b.physicalAvailableInHouse})',
                        ),
                        onPressed: () => _selectStock(b),
                      ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppTextField(
            controller: _stockSearchCtrl,
            label: l10n.stockSearchStockHint,
            prefixIcon: Icons.search_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: Text(l10n.stockOnlyAvailableFilter),
                selected: _onlyInStock,
                onSelected: (v) => setState(() => _onlyInStock = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: AppText(
                l10n.stockNoStockItemsSubtitle,
                variant: AppTextVariant.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, idx) {
                  final b = filtered[idx];
                  final isSelected = b.designColourId == _selectedColourId;
                  final hasStock = b.physicalAvailableInHouse > 0;
                  return AppCard(
                    elevated: false,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    color: isSelected
                        ? colorScheme.secondary.withValues(alpha: 0.10)
                        : colorScheme.surfaceContainer,
                    borderColor: isSelected
                        ? colorScheme.secondary
                        : colorScheme.outlineVariant,
                    onTap: () => _selectStock(b),
                    child: AppActionRow(
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            '${b.lotNumber} • ${b.designName}',
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: 2),
                          AppText(
                            b.colourName,
                            variant: AppTextVariant.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      actions: [
                        AppStatusBadge(
                          label: hasStock
                              ? '${b.physicalAvailableInHouse} ${l10n.piecesUnit}'
                              : l10n.stockOutOfStockBadge,
                          tone: hasStock
                              ? AppStatusTone.good
                              : AppStatusTone.neutral,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep2SelectWork(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final workDone =
        _selectedProcess != null &&
        _selectedWorker != null &&
        _effectiveRatePaise != null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StepBadge(number: 2, completed: workDone),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppHeading(
                  l10n.stockStepSelectWork,
                  level: AppHeadingLevel.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_recentSuggestions.workPairs.isNotEmpty) ...[
            AppText(
              l10n.stockRecentWorkPairsLabel,
              variant: AppTextVariant.label,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final pair in _recentSuggestions.workPairs)
                  ActionChip(
                    avatar: const Icon(Icons.bolt_rounded, size: 16),
                    label: Text('${pair.processName} • ${pair.workerName}'),
                    onPressed: () async {
                      setState(() => _selectedProcessId = pair.processId);
                      await _loadWorkersForProcess(
                        pair.processId,
                        preferredWorkerId: pair.workerId,
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppText(
            l10n.stockActiveProcessesLabel,
            variant: AppTextVariant.label,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_activeProcesses.isEmpty)
            AppStatusBadge(
              label: l10n.stockNoActiveProcessesWarning,
              tone: AppStatusTone.pending,
              icon: Icons.warning_amber_rounded,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final proc in _activeProcesses)
                  ChoiceChip(
                    label: Text(proc.name),
                    selected: _selectedProcessId == proc.id,
                    onSelected: (_) {
                      _dirty.markDirty();
                      setState(() => _selectedProcessId = proc.id);
                      _loadWorkersForProcess(proc.id);
                    },
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            l10n.stockEligibleWorkersLabel,
            variant: AppTextVariant.label,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_eligibleWorkers.isEmpty)
            AppStatusBadge(
              label: l10n.stockNoEligibleWorkers,
              tone: AppStatusTone.pending,
              icon: Icons.warning_amber_rounded,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final w in _eligibleWorkers)
                  ChoiceChip(
                    label: Text(w.workerName),
                    selected: _selectedWorkerId == w.workerId,
                    onSelected: (_) {
                      _dirty.markDirty();
                      setState(() => _selectedWorkerId = w.workerId);
                      _refreshRatePreview();
                    },
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          _buildRateAndBillingPreview(context),
          const SizedBox(height: AppSpacing.xs),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: _showAdvanced,
              onExpansionChanged: (v) => setState(() => _showAdvanced = v),
              leading: const Icon(Icons.tune_rounded, size: 18),
              title: AppText(
                l10n.stockAdvancedOptionsTitle,
                variant: AppTextVariant.label,
              ),
              children: [
                const SizedBox(height: AppSpacing.sm),
                AppDatePicker(
                  label: l10n.stockTransactionDateTimeLabel,
                  selectedUtcMillis: _transactionAtUtc,
                  includeTime: true,
                  onDateSelectedUtcMillis: (utc) {
                    _dirty.markDirty();
                    setState(() => _transactionAtUtc = utc);
                    _refreshRatePreview();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSwitch(
                  label: l10n.stockRateOverrideToggle,
                  value: _overrideRate,
                  onChanged: (v) => _edit(() => _overrideRate = v),
                ),
                if (_overrideRate) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _overrideRateCtrl,
                    label: l10n.stockOverrideRateLabel,
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() => _submitError = null),
                    validator: (v) => _overrideRate
                        ? ValidationLocalizer.localize(
                            l10n,
                            AppValidators.nonNegativeAmountValidator(v),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _overrideReasonCtrl,
                    label: l10n.stockOverrideReasonLabel,
                    maxLines: 2,
                    maxLength: ValidationLimits.maxNotesLength,
                    validator: (v) => _overrideRate
                        ? ValidationLocalizer.localize(
                            l10n,
                            AppValidators.nameValidator(
                              v,
                              maxLength: ValidationLimits.maxNotesLength,
                            ),
                          )
                        : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _notesCtrl,
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
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateAndBillingPreview(BuildContext context) {
    final l10n = context.l10n;
    final preview = _ratePreview;
    final colorScheme = Theme.of(context).colorScheme;
    final billingLabel = DomainLabelLocalizer.billingMode(
      l10n,
      _effectiveBillingMode,
    );

    final localeCode = Localizations.localeOf(context).languageCode;
    Widget rateRow;
    if (_overrideRate) {
      final overridePaise = _parseRupeesToPaise(_overrideRateCtrl.text);
      rateRow = AppText(
        '${l10n.stockOverrideRateLabel}: ${overridePaise != null ? MoneyFormatter.formatPaise(overridePaise) : '-'} ${l10n.ratesPerPieceSuffix}',
        variant: AppTextVariant.numeric,
        fontWeight: FontWeight.w700,
      );
    } else if (preview == null) {
      rateRow = const SizedBox.shrink();
    } else {
      rateRow = switch (preview) {
        RateResolutionFound(:final rate, :final businessDateIst) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppText(
                  '${l10n.stockResolvedRateLabel}: ${MoneyFormatter.formatPaise(rate.ratePaise)} ${l10n.ratesPerPieceSuffix}',
                  variant: AppTextVariant.numeric,
                  fontWeight: FontWeight.w700,
                ),
                const AppStatusBadge(
                  label: 'Worker Rate',
                  tone: AppStatusTone.good,
                ),
              ],
            ),
            AppText(
              '${AppDateTimeFormatter.formatIsoBusinessDateForDisplay(businessDateIst, locale: localeCode)} (${AppDateTimeFormatter.formatIsoDateRange(fromIso: rate.effectiveFrom, toIso: rate.effectiveTo, ongoingLabel: l10n.ratesOngoingLabel, locale: localeCode)})',
              variant: AppTextVariant.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        RateResolutionProcessDefault(
          :final ratePaise,
          :final rawDefaultRatePaise,
          :final pricingUnit,
          :final processName,
        ) =>
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppText(
                    '${l10n.stockResolvedRateLabel}: ${MoneyFormatter.formatPaise(ratePaise)} ${l10n.ratesPerPieceSuffix}',
                    variant: AppTextVariant.numeric,
                    fontWeight: FontWeight.w700,
                  ),
                  const AppStatusBadge(
                    label: 'Process Default',
                    tone: AppStatusTone.info,
                  ),
                ],
              ),
              AppText(
                'Inherited from $processName (${MoneyFormatter.formatRatePaise(rawDefaultRatePaise, pricingUnit: pricingUnit)})',
                variant: AppTextVariant.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        RateResolutionMissing() => AppStatusBadge(
          label: l10n.stockRateMissingWarning,
          tone: AppStatusTone.damaged,
          icon: Icons.error_outline_rounded,
        ),
        RateResolutionConflict() => AppStatusBadge(
          label: l10n.stockRateConflictWarning,
          tone: AppStatusTone.damaged,
          icon: Icons.error_outline_rounded,
        ),
      };
    }

    return AppCard(
      elevated: false,
      color: colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          rateRow,
          if (preview != null || _overrideRate)
            const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppText(
                  '${l10n.stockBillingModePreviewLabel}: $billingLabel',
                  variant: AppTextVariant.bodySmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3EnterQuantity(
    BuildContext context,
    DesignColourStockBalance balance,
    bool qtyExceeds,
  ) {
    final l10n = context.l10n;
    final available = balance.physicalAvailableInHouse;
    final qtyValid = _parsedQty > 0 && !qtyExceeds;

    return AppCard(
      borderColor: qtyExceeds
          ? Theme.of(context).colorScheme.error
          : (qtyValid
                ? context.semanticColors.goodStock.withValues(alpha: 0.45)
                : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StepBadge(number: 3, completed: qtyValid),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppHeading(
                  l10n.stockStepEnterQty,
                  level: AppHeadingLevel.h3,
                ),
              ),
              AppStatusBadge(
                label: '${l10n.stockAvailableGoodLabel}: $available',
                tone: available > 0
                    ? AppStatusTone.good
                    : AppStatusTone.damaged,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _qtyCtrl,
            focusNode: _qtyFocus,
            label: l10n.stockIssueQuantityLabel,
            prefixIcon: Icons.numbers_rounded,
            suffixText: l10n.piecesUnit,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.tabular(
              Theme.of(context).textTheme.headlineSmall!
                  .copyWith(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            errorText: qtyExceeds ? l10n.stockInsufficientGoodError : null,
            onChanged: (_) => setState(() => _submitError = null),
            validator: (v) {
              final parsed = AppValidators.parseQuantityExact(v);
              if (!parsed.validation.isValid) {
                return parsed.validation.code ==
                        ValidationErrorCode.valueTooLarge
                    ? l10n.validationValueTooLarge
                    : l10n.stockInvalidQtyError;
              }
              if (parsed.value! > available) {
                return l10n.stockInsufficientGoodError;
              }
              return null;
            },
          ),
          if (available > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (available >= 10)
                  ActionChip(
                    label: const Text('+10'),
                    onPressed: () => _addQuickQty(10, available),
                  ),
                if (available >= 25)
                  ActionChip(
                    label: const Text('+25'),
                    onPressed: () => _addQuickQty(25, available),
                  ),
                if (available >= 50)
                  ActionChip(
                    label: const Text('+50'),
                    onPressed: () => _addQuickQty(50, available),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.done_all_rounded, size: 16),
                  label: Text('${l10n.stockQuickAllAvailable} ($available)'),
                  onPressed: () => _setExactQty(available),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4ConfirmCard(
    BuildContext context, {
    required DesignColourStockBalance balance,
    required ProcessEntity? proc,
    required ProcessAssignedWorkerSummary? worker,
    required int? ratePaise,
    required int qty,
    required bool canSubmit,
  }) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    final expectedLabourPaise = (ratePaise != null && qty > 0)
        ? qty * ratePaise
        : null;

    return AppCard(
      color: colorScheme.surfaceContainerLow,
      borderColor: canSubmit
          ? colorScheme.secondary.withValues(alpha: 0.55)
          : colorScheme.outlineVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _StepBadge(number: 4, completed: false),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppHeading(
                  l10n.stockConfirmSummaryTitle,
                  level: AppHeadingLevel.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(
            label:
                '${l10n.lotLabelShort} / ${l10n.designNameLabel} / ${l10n.colourNameLabel}',
            value:
                '${balance.lotNumber} • ${balance.designName} • ${balance.colourName}',
          ),
          _SummaryRow(label: l10n.processNameLabel, value: proc?.name ?? '-'),
          _SummaryRow(
            label: l10n.workerNameLabel,
            value: worker?.workerName ?? '-',
          ),
          _SummaryRow(
            label: l10n.stockIssueQuantityLabel,
            value: qty > 0 ? '$qty ${l10n.piecesUnit}' : '-',
            isNumeric: true,
          ),
          _SummaryRow(
            label: l10n.stockResolvedRateLabel,
            value: ratePaise != null
                ? '${MoneyFormatter.formatPaise(ratePaise)} ${l10n.ratesPerPieceSuffix}'
                : '-',
            isNumeric: true,
          ),
          _SummaryRow(
            label: l10n.stockBillingModePreviewLabel,
            value: DomainLabelLocalizer.billingMode(
              l10n,
              _effectiveBillingMode,
            ),
          ),
          _SummaryRow(
            label: l10n.stockTransactionDateTimeLabel,
            value: IstDateTimeHelper.formatIstDateTime(
              _transactionAtUtc,
              locale: localeCode,
            ),
          ),
          if (expectedLabourPaise != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
            _SummaryRow(
              label: l10n.stockExpectedLabourLabel,
              value: MoneyFormatter.formatPaise(expectedLabourPaise),
              isNumeric: true,
              highlight: true,
            ),
            const SizedBox(height: 2),
            AppText(
              _effectiveBillingMode == BillingMode.givenQty
                  ? l10n.stockPayableOnIssueNote
                  : l10n.stockPayableOnReturnNote,
              variant: AppTextVariant.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
          if (_submitError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppStatusBadge(
              label: _submitError!,
              tone: AppStatusTone.damaged,
              icon: Icons.error_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, _IssuedSuccessInfo info) {
    final l10n = context.l10n;
    final semantic = context.semanticColors;

    return AppScaffold(
      title: l10n.stockIssueAction,
      body: ListView(
        children: [
          AppCard(
            borderColor: semantic.goodStock.withValues(alpha: 0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: semantic.goodStockContainer,
                      borderRadius: AppRadius.fullBorder,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: semantic.goodStock,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.stockIssueSuccessTitle,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  l10n.stockIssueSuccessSubtitle,
                  variant: AppTextVariant.bodySmall,
                  textAlign: TextAlign.center,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                _SummaryRow(
                  label: l10n.lotLabelShort,
                  value:
                      '${info.lotNumber} • ${info.designName} • ${info.colourName}',
                ),
                _SummaryRow(
                  label: l10n.processNameLabel,
                  value: info.processName,
                ),
                _SummaryRow(
                  label: l10n.workerNameLabel,
                  value: info.workerName,
                ),
                _SummaryRow(
                  label: l10n.stockIssuedLabel,
                  value: '${info.movement.quantity} ${l10n.piecesUnit}',
                  isNumeric: true,
                  highlight: true,
                ),
                _SummaryRow(
                  label: l10n.stockResolvedRateLabel,
                  value:
                      '${MoneyFormatter.formatPaise(info.movement.appliedRatePaise)} ${l10n.ratesPerPieceSuffix}',
                  isNumeric: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  elevated: false,
                  color: semantic.goodStockContainer.withValues(alpha: 0.55),
                  borderColor: semantic.goodStock.withValues(alpha: 0.35),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: semantic.goodStock,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppText(
                          l10n.stockUpdatedAvailableLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppText(
                        '${info.updatedAvailableGood} ${l10n.piecesUnit}',
                        variant: AppTextVariant.numeric,
                        fontWeight: FontWeight.w700,
                        color: semantic.goodStock,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.stockIssueMoreAction,
                  icon: Icons.add_circle_outline_rounded,
                  isExpanded: true,
                  onPressed: _issueMore,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.stockViewIssueDetailsAction,
                  icon: Icons.assignment_returned_outlined,
                  variant: AppButtonVariant.secondary,
                  isExpanded: true,
                  onPressed: () => context.pushReplacement(
                    RoutePaths.stockReturn(info.movement.id),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.actionDone,
                  variant: AppButtonVariant.outlined,
                  isExpanded: true,
                  onPressed: () => context.pop(true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _IssuedSuccessInfo {
  const _IssuedSuccessInfo({
    required this.movement,
    required this.lotNumber,
    required this.designName,
    required this.colourName,
    required this.processName,
    required this.workerName,
    required this.updatedAvailableGood,
    required this.effectiveBillingMode,
  });

  final StockMovementEntity movement;
  final String lotNumber;
  final String designName;
  final String colourName;
  final String processName;
  final String workerName;
  final int updatedAvailableGood;
  final BillingMode effectiveBillingMode;
}

final class _StepItem {
  const _StepItem({
    required this.number,
    required this.label,
    required this.completed,
    required this.active,
  });

  final int number;
  final String label;
  final bool completed;
  final bool active;
}

final class _StepProgressStrip extends StatelessWidget {
  const _StepProgressStrip({required this.steps});

  final List<_StepItem> steps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: steps[i].completed
                    ? semantic.goodStockContainer
                    : (steps[i].active
                          ? colorScheme.secondary.withValues(alpha: 0.16)
                          : colorScheme.surfaceContainer),
                borderRadius: AppRadius.fullBorder,
                border: Border.all(
                  color: steps[i].completed
                      ? semantic.goodStock.withValues(alpha: 0.4)
                      : (steps[i].active
                            ? colorScheme.secondary
                            : colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    steps[i].completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_checked_rounded,
                    size: 14,
                    color: steps[i].completed
                        ? semantic.goodStock
                        : (steps[i].active
                              ? colorScheme.secondary
                              : colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${steps[i].number}. ${steps[i].label}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: steps[i].active || steps[i].completed
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: steps[i].completed
                          ? semantic.goodStock
                          : (steps[i].active
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            if (i < steps.length - 1) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

final class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.completed});

  final int number;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: completed ? semantic.goodStock : colorScheme.primary,
        borderRadius: AppRadius.fullBorder,
      ),
      child: completed
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : Text(
              '$number',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

final class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isNumeric = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool isNumeric;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              variant: AppTextVariant.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: AppText(
              value,
              variant: isNumeric
                  ? AppTextVariant.numeric
                  : AppTextVariant.bodyMedium,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? colorScheme.primary : null,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
