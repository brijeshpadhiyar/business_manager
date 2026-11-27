import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
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
import 'package:business_manager/features/stock_movements/presentation/widgets/stock_issue_step_views.dart';
import 'package:business_manager/features/stock_movements/presentation/widgets/stock_issue_step_widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Streamlined 4-step Stock Issue workflow (+ Step 5 Success Summary).
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
  IssuedSuccessInfo? _successInfo;

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
        _loadError = ValidationLocalizer.describeError(context.l10n, e);
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
        _successInfo = IssuedSuccessInfo(
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
        _submitError = ValidationLocalizer.describeError(context.l10n, e);
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
      return StockIssueSuccessView(
        info: _successInfo!,
        onIssueMore: _issueMore,
      );
    }

    if (_allBalances.isEmpty) {
      return AppScaffold(
        title: l10n.stockIssueAction,
        body: AppEmptyState(
          icon: AppIcons.lot,
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
        bottomAction: AppButton(
          label: l10n.stockConfirmIssueAction,
          icon: AppIcons.stockIssue,
          isExpanded: true,
          isLoading: _saving,
          onPressed: canSubmit ? _submit : null,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              StockIssueStepProgressStrip(
                steps: [
                  StockIssueStepItem(
                    number: 1,
                    label: l10n.stockStepSelectStock,
                    completed: step1Done,
                    active: !step1Done || _pickingStock,
                  ),
                  StockIssueStepItem(
                    number: 2,
                    label: l10n.stockStepSelectWork,
                    completed: step2Done,
                    active: step1Done && !step2Done,
                  ),
                  StockIssueStepItem(
                    number: 3,
                    label: l10n.stockStepEnterQty,
                    completed: step3Done,
                    active: step1Done && step2Done && !step3Done,
                  ),
                  StockIssueStepItem(
                    number: 4,
                    label: l10n.stockStepConfirm,
                    completed: false,
                    active: canSubmit,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              StockIssueStep1Card(
                selected: balance,
                pickingStock: _pickingStock,
                allBalances: _allBalances,
                recentSuggestions: _recentSuggestions,
                searchController: _stockSearchCtrl,
                onlyInStock: _onlyInStock,
                selectedColourId: _selectedColourId,
                onRequestChangeSelection: () =>
                    setState(() => _pickingStock = true),
                onSearchChanged: () => setState(() {}),
                onOnlyInStockChanged: (v) => setState(() => _onlyInStock = v),
                onSelectStock: _selectStock,
              ),
              const SizedBox(height: AppSpacing.md),

              if (balance != null) ...[
                StockIssueStep2Card(
                  workDone: step2Done,
                  recentSuggestions: _recentSuggestions,
                  activeProcesses: _activeProcesses,
                  eligibleWorkers: _eligibleWorkers,
                  selectedProcessId: _selectedProcessId,
                  selectedWorkerId: _selectedWorkerId,
                  ratePreview: _ratePreview,
                  effectiveBillingMode: _effectiveBillingMode,
                  overrideRate: _overrideRate,
                  overrideRateController: _overrideRateCtrl,
                  overrideReasonController: _overrideReasonCtrl,
                  notesController: _notesCtrl,
                  transactionAtUtc: _transactionAtUtc,
                  showAdvanced: _showAdvanced,
                  onSelectRecentPair: (pair) async {
                    setState(() => _selectedProcessId = pair.processId);
                    await _loadWorkersForProcess(
                      pair.processId,
                      preferredWorkerId: pair.workerId,
                    );
                  },
                  onSelectProcess: (id) {
                    _dirty.markDirty();
                    setState(() => _selectedProcessId = id);
                    _loadWorkersForProcess(id);
                  },
                  onSelectWorker: (id) {
                    _dirty.markDirty();
                    setState(() => _selectedWorkerId = id);
                    _refreshRatePreview();
                  },
                  onExpansionChanged: (v) => setState(() => _showAdvanced = v),
                  onDateChanged: (utc) {
                    _dirty.markDirty();
                    setState(() => _transactionAtUtc = utc);
                    _refreshRatePreview();
                  },
                  onOverrideRateChanged: (v) => _edit(() => _overrideRate = v),
                  onClearSubmitError: () => setState(() => _submitError = null),
                ),
                const SizedBox(height: AppSpacing.md),

                StockIssueStep3Card(
                  balance: balance,
                  qtyExceeds: qtyExceeds,
                  parsedQty: qty,
                  qtyController: _qtyCtrl,
                  qtyFocusNode: _qtyFocus,
                  onChanged: () => setState(() => _submitError = null),
                  onAddQuickQty: (delta) =>
                      _addQuickQty(delta, balance.physicalAvailableInHouse),
                  onSetExactQty: _setExactQty,
                ),
                const SizedBox(height: AppSpacing.md),

                StockIssueStep4Card(
                  balance: balance,
                  proc: proc,
                  worker: worker,
                  ratePaise: ratePaise,
                  qty: qty,
                  canSubmit: canSubmit,
                  effectiveBillingMode: _effectiveBillingMode,
                  transactionAtUtc: _transactionAtUtc,
                  submitError: _submitError,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
