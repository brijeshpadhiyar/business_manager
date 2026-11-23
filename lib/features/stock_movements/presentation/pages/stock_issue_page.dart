import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Issue stock from in-house available good stock to an eligible worker and process.
final class StockIssuePage extends StatefulWidget {
  const StockIssuePage({super.key, this.initialDesignColourId});

  final String? initialDesignColourId;

  @override
  State<StockIssuePage> createState() => _StockIssuePageState();
}

final class _StockIssuePageState extends State<StockIssuePage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _overrideRateCtrl = TextEditingController();
  final _overrideReasonCtrl = TextEditingController();

  final _stockRepo = getIt<StockMovementRepository>();
  final _processRepo = getIt<ProcessRepository>();
  final _clientRequestId = getIt<IdGenerator>().nextRequestId();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _submitError;

  List<DesignColourStockBalance> _allBalances = const [];
  List<ProcessEntity> _activeProcesses = const [];
  List<ProcessAssignedWorkerSummary> _eligibleWorkers = const [];

  String? _selectedColourId;
  String? _selectedProcessId;
  String? _selectedWorkerId;
  int _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();

  RateResolutionResult? _ratePreview;
  bool _overrideRate = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
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

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final balances = await _stockRepo.getAllDesignColourBalances();
      final procs = await _processRepo.getProcesses(isActiveFilter: true);

      String? initialColour = widget.initialDesignColourId;
      if (initialColour == null && balances.isNotEmpty) {
        final withStock = balances.where((b) => b.physicalAvailableInHouse > 0);
        initialColour = withStock.isNotEmpty
            ? withStock.first.designColourId
            : balances.first.designColourId;
      }

      if (!mounted) return;
      setState(() {
        _allBalances = balances;
        _activeProcesses = procs;
        _selectedColourId = initialColour;
        _selectedProcessId = procs.isNotEmpty ? procs.first.id : null;
        _loading = false;
      });
      if (_selectedProcessId != null) {
        await _loadWorkersForProcess(_selectedProcessId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _loadWorkersForProcess(String processId) async {
    final detail = await _processRepo.getProcessDetail(processId);
    final activeAssigned = (detail?.assignedWorkers ?? const [])
        .where((w) => w.workerIsActive)
        .toList();
    if (!mounted) return;
    setState(() {
      _eligibleWorkers = activeAssigned;
      _selectedWorkerId = activeAssigned.isNotEmpty
          ? activeAssigned.first.workerId
          : null;
      _ratePreview = null;
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
    final cleaned = text.trim();
    if (cleaned.isEmpty) return null;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed < 0) return null;
    return (parsed * 100).round();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;
    final l10n = context.l10n;

    if (_selectedColourId == null ||
        _selectedProcessId == null ||
        _selectedWorkerId == null) {
      setState(() => _submitError = l10n.validationRequired);
      return;
    }

    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      setState(() => _submitError = l10n.stockInvalidQtyError);
      return;
    }

    int? overridePaise;
    if (_overrideRate) {
      overridePaise = _parseRupeesToPaise(_overrideRateCtrl.text);
      if (overridePaise == null) {
        setState(() => _submitError = l10n.validationRequired);
        return;
      }
    }

    setState(() {
      _saving = true;
      _submitError = null;
    });

    try {
      await _stockRepo.issueStock(
        designColourId: _selectedColourId!,
        processId: _selectedProcessId!,
        workerId: _selectedWorkerId!,
        quantity: qty,
        transactionAtUtcMillis: _transactionAtUtc,
        notes: _notesCtrl.text,
        allowRateOverride: _overrideRate,
        overrideRatePaise: overridePaise,
        overrideReason: _overrideReasonCtrl.text,
        clientRequestId: _clientRequestId,
      );
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.stockIssueSuccess);
        context.pop(true);
      }
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = switch (e.code) {
          'insufficient_good_stock' => l10n.stockInsufficientGoodError,
          'invalid_quantity' => l10n.stockInvalidQtyError,
          'rate_missing' => l10n.stockRateMissingWarning,
          'rate_conflict' => l10n.stockRateConflictWarning,
          _ => e.message,
        };
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
      return AppScaffold(title: l10n.stockIssueAction, body: const AppLoader());
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

    final balance = _selectedBalance;

    return AppScaffold(
      title: l10n.stockIssueAction,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDropdown<String>(
                    label:
                        '${l10n.stockSelectLotLabel} / ${l10n.stockSelectDesignLabel} / ${l10n.stockSelectColourLabel}',
                    value: _selectedColourId,
                    items: _allBalances.map((b) => b.designColourId).toList(),
                    itemLabelBuilder: (id) {
                      final b = _allBalances.firstWhere(
                        (e) => e.designColourId == id,
                      );
                      return '${b.lotNumber} • ${b.designName} • ${b.colourName} (${b.physicalAvailableInHouse} ${l10n.piecesUnit})';
                    },
                    onChanged: (v) => setState(() => _selectedColourId = v),
                  ),
                  if (balance != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppStatusBadge(
                          label:
                              '${l10n.stockAvailableGoodLabel}: ${balance.physicalAvailableInHouse} ${l10n.piecesUnit}',
                          tone: balance.physicalAvailableInHouse > 0
                              ? AppStatusTone.good
                              : AppStatusTone.damaged,
                          icon: Icons.inventory_2_outlined,
                        ),
                        AppStatusBadge(
                          label:
                              '${l10n.stockPendingWorkerLabel}: ${balance.totalPendingWithWorkers}',
                          tone: AppStatusTone.pending,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<String>(
                    label: l10n.stockSelectProcessLabel,
                    value: _selectedProcessId,
                    items: _activeProcesses.map((p) => p.id).toList(),
                    itemLabelBuilder: (id) =>
                        _activeProcesses.firstWhere((p) => p.id == id).name,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedProcessId = v);
                      _loadWorkersForProcess(v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_eligibleWorkers.isEmpty)
                    AppStatusBadge(
                      label: l10n.stockNoEligibleWorkers,
                      tone: AppStatusTone.pending,
                      icon: Icons.warning_amber_rounded,
                    )
                  else
                    AppDropdown<String>(
                      label: l10n.stockSelectWorkerLabel,
                      value: _selectedWorkerId,
                      items: _eligibleWorkers.map((w) => w.workerId).toList(),
                      itemLabelBuilder: (id) => _eligibleWorkers
                          .firstWhere((w) => w.workerId == id)
                          .workerName,
                      onChanged: (v) {
                        setState(() => _selectedWorkerId = v);
                        _refreshRatePreview();
                      },
                    ),
                  const SizedBox(height: AppSpacing.md),
                  AppDatePicker(
                    label: l10n.stockTransactionDateTimeLabel,
                    selectedUtcMillis: _transactionAtUtc,
                    includeTime: true,
                    onDateSelectedUtcMillis: (utc) {
                      setState(() => _transactionAtUtc = utc);
                      _refreshRatePreview();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildRatePreviewBox(context),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _qtyCtrl,
                    label: l10n.stockIssueQuantityLabel,
                    prefixIcon: Icons.numbers_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final parsed = int.tryParse(v?.trim() ?? '');
                      if (parsed == null || parsed <= 0) {
                        return l10n.stockInvalidQtyError;
                      }
                      if (balance != null &&
                          parsed > balance.physicalAvailableInHouse) {
                        return l10n.stockInsufficientGoodError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSwitch(
                    label: l10n.stockRateOverrideToggle,
                    value: _overrideRate,
                    onChanged: (v) => setState(() => _overrideRate = v),
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
                      validator: (v) => _parseRupeesToPaise(v ?? '') == null
                          ? l10n.validationRequired
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: _overrideReasonCtrl,
                      label: l10n.stockOverrideReasonLabel,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.validationRequired
                          : null,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _notesCtrl,
                    label: l10n.stockNotesLabel,
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
                    label: l10n.stockIssueAction,
                    icon: Icons.check_rounded,
                    isExpanded: true,
                    isLoading: _saving,
                    onPressed: _eligibleWorkers.isEmpty ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatePreviewBox(BuildContext context) {
    final l10n = context.l10n;
    final preview = _ratePreview;
    if (preview == null) return const SizedBox.shrink();

    return switch (preview) {
      RateResolutionFound(:final rate, :final businessDateIst) => AppCard(
        elevated: false,
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          children: [
            const Icon(Icons.lock_clock_outlined, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '${l10n.stockResolvedRateLabel}: ${MoneyFormatter.formatPaise(rate.ratePaise)} ${l10n.ratesPerPieceSuffix}',
                    fontWeight: FontWeight.w700,
                  ),
                  AppText(
                    '$businessDateIst (${rate.effectiveFrom} → ${rate.effectiveTo ?? l10n.ratesOngoingLabel})',
                    variant: AppTextVariant.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
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
}
