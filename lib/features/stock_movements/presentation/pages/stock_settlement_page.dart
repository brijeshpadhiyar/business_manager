import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/calculators/labour_calculator.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Streamlined Receive Return & Settlement workflow (Steps 2–5) linked to an
/// open ISSUE movement, preserving 100% of domain stock & labour rules.
final class StockSettlementPage extends StatefulWidget {
  const StockSettlementPage({super.key, required this.issueId});

  final String issueId;

  @override
  State<StockSettlementPage> createState() => _StockSettlementPageState();
}

final class _StockSettlementPageState extends State<StockSettlementPage> {
  final _formKey = GlobalKey<FormState>();
  final _goodCtrl = TextEditingController();
  final _damagedCtrl = TextEditingController();
  final _lostCtrl = TextEditingController();
  final _shortageCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _repo = getIt<StockMovementRepository>();
  final _idGen = getIt<IdGenerator>();
  static const LabourCalculator _labourCalc = LabourCalculator();

  late String _clientRequestId;

  OpenIssueSummary? _detail;
  bool _loading = true;
  bool _saving = false;
  bool _showAdvanced = false;
  String? _loadError;
  String? _submitError;
  int _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();

  // Step 5 Success state
  _ReturnSuccessInfo? _successInfo;

  @override
  void initState() {
    super.initState();
    _clientRequestId = _idGen.nextRequestId();
    _load();
  }

  @override
  void dispose() {
    _goodCtrl.dispose();
    _damagedCtrl.dispose();
    _lostCtrl.dispose();
    _shortageCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final detail = await _repo.getIssueDetail(widget.issueId);
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _loading = false;
          _loadError = 'Issue record not found.';
        });
        return;
      }
      setState(() {
        _detail = detail;
        _goodCtrl.text = detail.remainingPending > 0
            ? '${detail.remainingPending}'
            : '';
        _damagedCtrl.text = '0';
        _lostCtrl.text = '0';
        _shortageCtrl.text = '0';
        _reasonCtrl.clear();
        _notesCtrl.clear();
        _submitError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  int _qtyOf(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  void _fillAllGood(int remaining) {
    setState(() {
      _goodCtrl.text = '$remaining';
      _damagedCtrl.text = '0';
      _lostCtrl.text = '0';
      _shortageCtrl.text = '0';
      _submitError = null;
    });
  }

  int _computeExpectedLabourPaise({
    required StockMovementEntity issue,
    required int good,
    required int damaged,
  }) {
    final mode = issue.lockedBillingMode ?? BillingMode.receivedQty;
    var payable = 0;
    if (good > 0) {
      final planned = _labourCalc.planForSettlement(
        movementType: StockMovementType.returnGood,
        quantity: good,
        lockedRatePaise: issue.appliedRatePaise,
        lockedBillingMode: mode,
        lockedIncludeDamaged: issue.lockedIncludeDamaged,
      );
      if (planned != null && planned.isPayable) {
        payable += planned.amountPaise;
      }
    }
    if (damaged > 0) {
      final planned = _labourCalc.planForSettlement(
        movementType: StockMovementType.returnDamaged,
        quantity: damaged,
        lockedRatePaise: issue.appliedRatePaise,
        lockedBillingMode: mode,
        lockedIncludeDamaged: issue.lockedIncludeDamaged,
      );
      if (planned != null && planned.isPayable) {
        payable += planned.amountPaise;
      }
    }
    return payable;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving || _detail == null) return;
    final l10n = context.l10n;

    final good = _qtyOf(_goodCtrl);
    final damaged = _qtyOf(_damagedCtrl);
    final lost = _qtyOf(_lostCtrl);
    final shortage = _qtyOf(_shortageCtrl);
    final total = good + damaged + lost + shortage;

    if (total <= 0) {
      setState(() => _submitError = l10n.stockSettlementEmptyError);
      return;
    }
    if (total > _detail!.remainingPending) {
      setState(() => _submitError = l10n.stockSettlementTotalExceedsError);
      return;
    }
    if ((damaged > 0 || lost > 0 || shortage > 0) &&
        _reasonCtrl.text.trim().isEmpty) {
      setState(() => _submitError = l10n.stockSettlementReasonRequiredError);
      return;
    }

    setState(() {
      _saving = true;
      _submitError = null;
    });

    try {
      final result = await _repo.recordSettlement(
        parentIssueId: widget.issueId,
        goodQuantity: good,
        damagedQuantity: damaged,
        lostQuantity: lost,
        shortageQuantity: shortage,
        transactionAtUtcMillis: _transactionAtUtc,
        reason: _reasonCtrl.text,
        notes: _notesCtrl.text,
        clientRequestId: _clientRequestId,
      );

      final refreshed = await _repo.getIssueDetail(widget.issueId);
      final issue = _detail!.issueView.movement;
      final labourEarnedPaise = _computeExpectedLabourPaise(
        issue: issue,
        good: good,
        damaged: damaged,
      );

      if (!mounted) return;
      setState(() {
        _saving = false;
        _detail = refreshed ?? _detail;
        _successInfo = _ReturnSuccessInfo(
          designColourId: issue.designColourId,
          lotNumber: _detail!.issueView.lotNumber,
          designName: _detail!.issueView.designName,
          colourName: _detail!.issueView.colourName,
          workerName: _detail!.issueView.workerName ?? '-',
          processName: _detail!.issueView.processName ?? '-',
          goodQty: good,
          damagedQty: damaged,
          lostQty: lost,
          shortageQty: shortage,
          updatedPending: result.remainingPending,
          labourEarnedPaise: labourEarnedPaise,
        );
      });
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = switch (e.code) {
          'exceeds_pending_quantity' => l10n.stockSettlementTotalExceedsError,
          'settlement_empty' => l10n.stockSettlementEmptyError,
          'reason_required' => l10n.stockSettlementReasonRequiredError,
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

  Future<void> _receiveAnother() async {
    final pending = _detail?.remainingPending ?? 0;
    if (pending > 0) {
      setState(() {
        _successInfo = null;
        _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();
        _clientRequestId = _idGen.nextRequestId();
      });
      await _load();
    } else {
      context.pushReplacement(RoutePaths.stockReturnPicker);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    if (_loading) {
      return AppScaffold(
        title: l10n.stockSettlementHeading,
        body: const AppSkeletonList(itemCount: 3),
      );
    }
    if (_loadError != null || _detail == null) {
      return AppScaffold(
        title: l10n.stockSettlementHeading,
        body: AppErrorView(
          title: l10n.errorUnexpected,
          message: _loadError,
          retryLabel: l10n.actionRetry,
          onRetry: _load,
        ),
      );
    }

    if (_successInfo != null) {
      return _buildSuccessView(context, _successInfo!);
    }

    final detail = _detail!;
    final view = detail.issueView;
    final m = view.movement;
    final semantic = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;

    final good = _qtyOf(_goodCtrl);
    final damaged = _qtyOf(_damagedCtrl);
    final lost = _qtyOf(_lostCtrl);
    final shortage = _qtyOf(_shortageCtrl);
    final totalEntered = good + damaged + lost + shortage;
    final remainingAfter = detail.remainingPending - totalEntered;
    final isOverReturn = remainingAfter < 0;
    final needsReason = damaged > 0 || lost > 0 || shortage > 0;
    final lockedMode = m.lockedBillingMode ?? BillingMode.receivedQty;
    final labourEarned = _computeExpectedLabourPaise(
      issue: m,
      good: good,
      damaged: damaged,
    );

    final previouslySettled =
        view.returnedGoodQty +
        view.returnedDamagedQty +
        view.lostQty +
        view.shortageQty;

    return AppScaffold(
      title: l10n.stockSettlementHeading,
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            // Parent Issue Summary Header Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    '${view.workerName ?? '-'} • ${view.processName ?? '-'}',
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    '${view.lotNumber} • ${view.designName} • ${view.colourName}',
                    variant: AppTextVariant.bodySmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      AppStatusBadge(
                        label: '${l10n.stockIssuedLabel}: ${m.quantity}',
                        tone: AppStatusTone.info,
                      ),
                      AppStatusBadge(
                        label:
                            '${l10n.stockPreviouslyReturnedLabel}: $previouslySettled',
                        tone: AppStatusTone.good,
                      ),
                      AppStatusBadge(
                        label:
                            '${l10n.stockRemainingPendingLabel}: ${detail.remainingPending}',
                        tone: detail.remainingPending > 0
                            ? AppStatusTone.pending
                            : AppStatusTone.good,
                        icon: Icons.hourglass_bottom_rounded,
                      ),
                      AppStatusBadge(
                        label:
                            '${MoneyFormatter.formatPaise(m.appliedRatePaise)} ${l10n.ratesPerPieceSuffix}',
                        tone: AppStatusTone.neutral,
                        icon: Icons.lock_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    '${DomainLabelLocalizer.billingMode(l10n, lockedMode)} • ${IstDateTimeHelper.formatIstDateTime(m.transactionAt, locale: localeCode)}',
                    variant: AppTextVariant.bodySmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),

            if (detail.remainingPending > 0) ...[
              const SizedBox(height: AppSpacing.md),

              // STEP 2: ENTER RETURN QUANTITIES + LIVE REMAINING INDICATOR
              AppCard(
                borderColor: isOverReturn ? colorScheme.error : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Live Remaining Pending Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isOverReturn
                            ? semantic.damagedContainer
                            : (remainingAfter == 0
                                  ? semantic.goodStockContainer
                                  : semantic.pendingContainer),
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOverReturn
                                ? Icons.error_outline_rounded
                                : (remainingAfter == 0
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.pending_actions_rounded),
                            size: 20,
                            color: isOverReturn
                                ? semantic.damaged
                                : (remainingAfter == 0
                                      ? semantic.goodStock
                                      : semantic.pending),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppText(
                              isOverReturn
                                  ? l10n.stockOverReturnErrorLive
                                  : l10n.stockLiveRemainingAfterReturn,
                              variant: AppTextVariant.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: isOverReturn
                                  ? semantic.damaged
                                  : (remainingAfter == 0
                                        ? semantic.goodStock
                                        : semantic.pending),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppText(
                            isOverReturn
                                ? '$totalEntered / ${detail.remainingPending}'
                                : '$remainingAfter ${l10n.piecesUnit}',
                            variant: AppTextVariant.numeric,
                            fontWeight: FontWeight.w700,
                            color: isOverReturn
                                ? semantic.damaged
                                : (remainingAfter == 0
                                      ? semantic.goodStock
                                      : semantic.pending),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ActionChip(
                        avatar: Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: semantic.goodStock,
                        ),
                        label: Text(
                          '${l10n.stockFillAllRemaining} (${detail.remainingPending})',
                        ),
                        onPressed: () => _fillAllGood(detail.remainingPending),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Good Returned (Primary Green)
                    AppTextField(
                      controller: _goodCtrl,
                      label: l10n.stockGoodReturnQtyLabel,
                      prefixIcon: Icons.check_circle_outline_rounded,
                      suffixText: l10n.piecesUnit,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTypography.tabular(
                        Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: semantic.goodStock,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onChanged: (_) => setState(() => _submitError = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Damaged Returned (Red)
                    AppTextField(
                      controller: _damagedCtrl,
                      label: l10n.stockDamagedReturnQtyLabel,
                      prefixIcon: Icons.report_problem_outlined,
                      suffixText: l10n.piecesUnit,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTypography.tabular(
                        Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: damaged > 0 ? semantic.damaged : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: (_) => setState(() => _submitError = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Lost vs Shortage clearly separated with helper text
                    AppTextField(
                      controller: _lostCtrl,
                      label: l10n.stockLostQtyLabel,
                      helperText: l10n.stockLostHelper,
                      prefixIcon: Icons.help_outline_rounded,
                      suffixText: l10n.piecesUnit,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTypography.tabular(
                        Theme.of(context).textTheme.titleMedium!,
                      ),
                      onChanged: (_) => setState(() => _submitError = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _shortageCtrl,
                      label: l10n.stockShortageQtyLabel,
                      helperText: l10n.stockShortageHelper,
                      prefixIcon: Icons.remove_circle_outline_rounded,
                      suffixText: l10n.piecesUnit,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTypography.tabular(
                        Theme.of(context).textTheme.titleMedium!,
                      ),
                      onChanged: (_) => setState(() => _submitError = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _reasonCtrl,
                      label: l10n.stockSettlementReasonLabel,
                      maxLines: 2,
                      validator: (v) {
                        if (needsReason && (v == null || v.trim().isEmpty)) {
                          return l10n.stockSettlementReasonRequiredError;
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() => _submitError = null),
                    ),
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        initiallyExpanded: _showAdvanced,
                        onExpansionChanged: (v) =>
                            setState(() => _showAdvanced = v),
                        leading: const Icon(Icons.schedule_rounded, size: 18),
                        title: AppText(
                          '${l10n.stockTransactionDateTimeLabel} / ${l10n.stockNotesLabel}',
                          variant: AppTextVariant.label,
                        ),
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          AppDatePicker(
                            label: l10n.stockTransactionDateTimeLabel,
                            selectedUtcMillis: _transactionAtUtc,
                            includeTime: true,
                            onDateSelectedUtcMillis: (utc) =>
                                setState(() => _transactionAtUtc = utc),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppTextField(
                            controller: _notesCtrl,
                            label: l10n.stockNotesLabel,
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // STEP 3: CONSEQUENCES & LABOUR IMPACT SUMMARY + STEP 4 SAVE
              AppCard(
                color: colorScheme.surfaceContainer,
                elevated: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppHeading(
                      l10n.stockConsequencesTitle,
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (good > 0)
                      _ImpactLine(
                        icon: Icons.check_circle_outline_rounded,
                        color: semantic.goodStock,
                        label: l10n.stockConsequenceGood,
                        value: '+$good ${l10n.piecesUnit}',
                      ),
                    if (damaged > 0)
                      _ImpactLine(
                        icon: Icons.report_problem_outlined,
                        color: semantic.damaged,
                        label: l10n.stockConsequenceDamaged,
                        value: '+$damaged ${l10n.piecesUnit}',
                      ),
                    if (lost > 0)
                      _ImpactLine(
                        icon: Icons.help_outline_rounded,
                        color: semantic.advanceCredit,
                        label: l10n.stockConsequenceLost,
                        value: '$lost ${l10n.piecesUnit}',
                      ),
                    if (shortage > 0)
                      _ImpactLine(
                        icon: Icons.remove_circle_outline_rounded,
                        color: semantic.advanceCredit,
                        label: l10n.stockConsequenceShortage,
                        value: '$shortage ${l10n.piecesUnit}',
                      ),
                    _ImpactLine(
                      icon: Icons.hourglass_bottom_rounded,
                      color: remainingAfter > 0
                          ? semantic.pending
                          : semantic.goodStock,
                      label: l10n.stockConsequencePending,
                      value:
                          '${remainingAfter < 0 ? 0 : remainingAfter} ${l10n.piecesUnit}',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(),
                    ),
                    if (lockedMode == BillingMode.givenQty)
                      AppText(
                        l10n.stockConsequenceLabourAlreadyGiven,
                        variant: AppTextVariant.bodySmall,
                        color: colorScheme.onSurfaceVariant,
                      )
                    else if (labourEarned > 0)
                      _ImpactLine(
                        icon: Icons.account_balance_wallet_outlined,
                        color: semantic.goodStock,
                        label: l10n.stockConsequenceLabourEarned,
                        value: MoneyFormatter.formatPaise(labourEarned),
                      )
                    else
                      AppText(
                        l10n.stockConsequenceLabourNone,
                        variant: AppTextVariant.bodySmall,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    if (_submitError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppStatusBadge(
                        label: _submitError!,
                        tone: AppStatusTone.damaged,
                        icon: Icons.error_outline_rounded,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.stockConfirmSaveReturnAction,
                      icon: Icons.check_rounded,
                      isExpanded: true,
                      isLoading: _saving,
                      onPressed: (!isOverReturn && totalEntered > 0 && !_saving)
                          ? _submit
                          : null,
                    ),
                  ],
                ),
              ),
            ],

            // Existing child settlements history (with localized movement labels!)
            if (detail.childSettlements.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AppHeading(l10n.stockDetailsHeading, level: AppHeadingLevel.h3),
              const SizedBox(height: AppSpacing.sm),
              for (final child in detail.childSettlements)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppStatusBadge(
                                label: DomainLabelLocalizer.movementType(
                                  l10n,
                                  child.movement.movementType,
                                ),
                                tone: DomainLabelLocalizer.movementTone(
                                  child.movement.movementType,
                                ),
                              ),
                              if (child.movement.reason != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                AppText(
                                  child.movement.reason!,
                                  variant: AppTextVariant.bodySmall,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xs),
                              AppText(
                                IstDateTimeHelper.formatIstDateTime(
                                  child.movement.transactionAt,
                                  locale: localeCode,
                                ),
                                variant: AppTextVariant.bodySmall,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (child.isReversed)
                          AppStatusBadge(
                            label: l10n.stockReversedBadge,
                            tone: AppStatusTone.neutral,
                          )
                        else
                          AppText(
                            '${child.movement.quantity} ${l10n.piecesUnit}',
                            variant: AppTextVariant.numeric,
                            fontWeight: FontWeight.w700,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, _ReturnSuccessInfo info) {
    final l10n = context.l10n;
    final semantic = context.semanticColors;

    return AppScaffold(
      title: l10n.stockSettlementHeading,
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
                  l10n.stockReturnSuccessTitle,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  '${info.workerName} • ${info.processName} • ${info.lotNumber} • ${info.designName} • ${info.colourName}',
                  variant: AppTextVariant.bodySmall,
                  textAlign: TextAlign.center,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (info.goodQty > 0)
                      AppStatusBadge(
                        label:
                            '${l10n.stockGoodReturnedLabel}: ${info.goodQty}',
                        tone: AppStatusTone.good,
                      ),
                    if (info.damagedQty > 0)
                      AppStatusBadge(
                        label:
                            '${l10n.stockDamagedBucketLabel}: ${info.damagedQty}',
                        tone: AppStatusTone.damaged,
                      ),
                    if (info.lostQty > 0)
                      AppStatusBadge(
                        label: '${l10n.stockLostLabel}: ${info.lostQty}',
                        tone: AppStatusTone.info,
                      ),
                    if (info.shortageQty > 0)
                      AppStatusBadge(
                        label:
                            '${l10n.stockShortageLabel}: ${info.shortageQty}',
                        tone: AppStatusTone.info,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  elevated: false,
                  color: info.updatedPending == 0
                      ? semantic.goodStockContainer.withValues(alpha: 0.55)
                      : semantic.pendingContainer.withValues(alpha: 0.55),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText(
                          l10n.stockReturnUpdatedPendingLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppStatusBadge(
                        label: info.updatedPending == 0
                            ? l10n.stockReturnFullySettledBadge
                            : '${info.updatedPending} ${l10n.piecesUnit}',
                        tone: info.updatedPending == 0
                            ? AppStatusTone.good
                            : AppStatusTone.pending,
                      ),
                    ],
                  ),
                ),
                if (info.labourEarnedPaise > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ImpactLine(
                    icon: Icons.account_balance_wallet_outlined,
                    color: semantic.goodStock,
                    label: l10n.stockConsequenceLabourEarned,
                    value: MoneyFormatter.formatPaise(info.labourEarnedPaise),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (info.goodQty > 0) ...[
                  AppButton(
                    label: l10n.stockIssueNextProcessAction,
                    icon: Icons.outbox_rounded,
                    isExpanded: true,
                    onPressed: () => context.pushReplacement(
                      RoutePaths.stockIssue(
                        designColourId: info.designColourId,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppButton(
                  label: l10n.stockReceiveAnotherReturnAction,
                  icon: Icons.assignment_returned_outlined,
                  variant: info.goodQty > 0
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  isExpanded: true,
                  onPressed: _receiveAnother,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.stockDetailsHeading,
                  variant: AppButtonVariant.outlined,
                  isExpanded: true,
                  onPressed: () => setState(() => _successInfo = null),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.actionDone,
                  variant: AppButtonVariant.text,
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

final class _ReturnSuccessInfo {
  const _ReturnSuccessInfo({
    required this.designColourId,
    required this.lotNumber,
    required this.designName,
    required this.colourName,
    required this.workerName,
    required this.processName,
    required this.goodQty,
    required this.damagedQty,
    required this.lostQty,
    required this.shortageQty,
    required this.updatedPending,
    required this.labourEarnedPaise,
  });

  final String designColourId;
  final String lotNumber;
  final String designName;
  final String colourName;
  final String workerName;
  final String processName;
  final int goodQty;
  final int damagedQty;
  final int lostQty;
  final int shortageQty;
  final int updatedPending;
  final int labourEarnedPaise;
}

final class _ImpactLine extends StatelessWidget {
  const _ImpactLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: AppText(label, variant: AppTextVariant.bodySmall)),
          const SizedBox(width: AppSpacing.sm),
          AppText(
            value,
            variant: AppTextVariant.numeric,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }
}
