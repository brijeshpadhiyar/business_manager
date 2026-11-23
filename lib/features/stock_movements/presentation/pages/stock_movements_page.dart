import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:business_manager/features/stock_movements/presentation/bloc/stock_movements_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Daily-work Stock Movements Hub prioritizing:
/// - Quick Issue Stock & Receive Return actions
/// - Pending Returns (searchable & filterable)
/// - Live Stock (Good / Pending / Damaged / Lost & Shortage)
/// - Movement History (filterable + audited reversal)
/// - Worker & Process Stock Summary
final class StockMovementsPage extends StatelessWidget {
  const StockMovementsPage({
    super.key,
    this.initialTab = 0,
    this.embedded = false,
  });

  final int initialTab;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StockMovementsCubit>(
      create: (_) => getIt<StockMovementsCubit>()..loadAll(),
      child: _StockMovementsView(initialTab: initialTab, embedded: embedded),
    );
  }
}

final class _StockMovementsView extends StatefulWidget {
  const _StockMovementsView({required this.initialTab, required this.embedded});

  final int initialTab;
  final bool embedded;

  @override
  State<_StockMovementsView> createState() => _StockMovementsViewState();
}

final class _StockMovementsViewState extends State<_StockMovementsView> {
  late int _tab = widget.initialTab;
  final _pendingSearchCtrl = TextEditingController();
  final _historySearchCtrl = TextEditingController();
  StockMovementType? _typeFilter;

  @override
  void dispose() {
    _pendingSearchCtrl.dispose();
    _historySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await context.read<StockMovementsCubit>().loadAll(
      filter: StockMovementFilter(
        movementType: _typeFilter,
        searchQuery: _historySearchCtrl.text,
      ),
    );
  }

  Future<void> _openIssue({String? designColourId}) async {
    await context.push<bool>(
      RoutePaths.stockIssue(designColourId: designColourId),
    );
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _openReturnPicker() async {
    await context.push(RoutePaths.stockReturnPicker);
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _openReturn(String issueId) async {
    await context.push<bool>(RoutePaths.stockReturn(issueId));
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _openRepair() async {
    final saved = await context.push<bool>(RoutePaths.stockRepair);
    if (saved == true && mounted) {
      await _reload();
    }
  }

  Future<void> _confirmReverse(StockMovementView view) async {
    final l10n = context.l10n;
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await AppDialog.showCustom<bool>(
      context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.stockReverseConfirmTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                '${view.lotNumber} • ${view.designName} • ${view.colourName} (${view.movement.quantity} ${l10n.piecesUnit})',
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: reasonCtrl,
                label: l10n.stockReverseReasonLabel,
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.validationRequired
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: l10n.actionCancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogCtx).pop(false),
          ),
          AppButton(
            label: l10n.stockReverseAction,
            variant: AppButtonVariant.destructive,
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogCtx).pop(true);
              }
            },
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      reasonCtrl.dispose();
      return;
    }

    try {
      await getIt<StockMovementRepository>().reverseMovement(
        movementId: view.movement.id,
        reason: reasonCtrl.text,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      );
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.stockReverseSuccess);
        await _reload();
      }
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'downstream_stock_dependency' ||
        'downstream_damaged_dependency' ||
        'downstream_parent_dependency' => l10n.stockReverseBlockedDownstream,
        'issue_has_active_settlements' => l10n.stockReverseBlockedChildren,
        _ => e.message,
      };
      AppFeedback.showError(context, msg);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e.toString());
    } finally {
      reasonCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    final bodyContent = BlocBuilder<StockMovementsCubit, StockMovementsState>(
      builder: (context, state) {
        if (state.status == StockMovementsStatus.initial ||
            state.status == StockMovementsStatus.loading) {
          return const AppSkeletonList(itemCount: 5);
        }
        if (state.status == StockMovementsStatus.error) {
          return AppErrorView(
            title: l10n.errorUnexpected,
            message: state.errorMessage,
            retryLabel: l10n.actionRetry,
            onRetry: _reload,
          );
        }

        final totalGood = state.colourBalances.fold<int>(
          0,
          (sum, b) => sum + b.physicalAvailableInHouse,
        );
        final totalPending = state.colourBalances.fold<int>(
          0,
          (sum, b) => sum + b.totalPendingWithWorkers,
        );
        final totalDamaged = state.colourBalances.fold<int>(
          0,
          (sum, b) => sum + b.damagedBucket,
        );

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizing.maxContentWidth,
            ),
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  96,
                ),
                children: [
                  if (widget.embedded) ...[
                    AppHeading(
                      l10n.stockHeading,
                      level: AppHeadingLevel.h2,
                      trailing: AppIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: l10n.actionRetry,
                        onPressed: _reload,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Primary Daily Workshop Actions Bar
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppButton(
                        label: l10n.stockIssueAction,
                        icon: Icons.outbox_rounded,
                        onPressed: _openIssue,
                      ),
                      AppButton(
                        label: l10n.stockReturnAction,
                        icon: Icons.assignment_returned_outlined,
                        variant: AppButtonVariant.secondary,
                        onPressed: _openReturnPicker,
                      ),
                      AppButton(
                        label: l10n.stockRepairAction,
                        icon: Icons.build_circle_outlined,
                        variant: AppButtonVariant.outlined,
                        onPressed: _openRepair,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // KPI Summary Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 680;
                      final tileWidth = isWide
                          ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                          : (constraints.maxWidth - AppSpacing.sm) / 2;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          SizedBox(
                            width: tileWidth,
                            child: AppMetricTile(
                              label: l10n.stockAvailableGoodLabel,
                              value: totalGood,
                              suffix: l10n.piecesUnit,
                              icon: Icons.inventory_2_outlined,
                              tone: AppStatusTone.good,
                              onTap: () => setState(() => _tab = 1),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: AppMetricTile(
                              label: l10n.stockPendingWorkerLabel,
                              value: totalPending,
                              suffix: l10n.piecesUnit,
                              icon: Icons.pending_actions_rounded,
                              tone: totalPending > 0
                                  ? AppStatusTone.pending
                                  : AppStatusTone.good,
                              onTap: () => setState(() => _tab = 0),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: AppMetricTile(
                              label: l10n.stockDamagedBucketLabel,
                              value: totalDamaged,
                              suffix: l10n.piecesUnit,
                              icon: Icons.report_problem_outlined,
                              tone: totalDamaged > 0
                                  ? AppStatusTone.damaged
                                  : AppStatusTone.neutral,
                              onTap: totalDamaged > 0 ? _openRepair : null,
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: AppMetricTile(
                              label: l10n.stockTabPendingReturns,
                              value: state.openIssues.length,
                              icon: Icons.assignment_return_outlined,
                              tone: AppStatusTone.info,
                              onTap: () => setState(() => _tab = 0),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Clean Prioritized Daily-Work Tabs
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: Text(
                          '${l10n.stockTabPendingReturns} (${state.openIssues.length})',
                        ),
                        selected: _tab == 0,
                        onSelected: (_) => setState(() => _tab = 0),
                      ),
                      ChoiceChip(
                        label: Text(l10n.stockTabBalances),
                        selected: _tab == 1,
                        onSelected: (_) => setState(() => _tab = 1),
                      ),
                      ChoiceChip(
                        label: Text(l10n.stockTabMovementHistory),
                        selected: _tab == 2,
                        onSelected: (_) => setState(() => _tab = 2),
                      ),
                      ChoiceChip(
                        label: Text(l10n.stockTabSummary),
                        selected: _tab == 3,
                        onSelected: (_) => setState(() => _tab = 3),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  switch (_tab) {
                    0 => _buildOpenIssues(
                      context,
                      state.openIssues,
                      localeCode,
                    ),
                    1 => _buildLiveBalances(context, state.colourBalances),
                    2 => _buildHistory(context, state.history, localeCode),
                    _ => _buildSummaries(
                      context,
                      state.workerSummaries,
                      state.processSummaries,
                    ),
                  },
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.embedded) {
      return bodyContent;
    }

    return AppScaffold(
      title: l10n.stockHeading,
      actions: [
        AppIconButton(
          icon: Icons.build_circle_outlined,
          tooltip: l10n.stockRepairAction,
          onPressed: _openRepair,
        ),
        AppIconButton(
          icon: Icons.refresh_rounded,
          tooltip: l10n.actionRetry,
          onPressed: _reload,
        ),
      ],
      padding: EdgeInsets.zero,
      constrainMaxWidth: false,
      body: bodyContent,
    );
  }

  Widget _buildOpenIssues(
    BuildContext context,
    List<OpenIssueSummary> issues,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (issues.isEmpty) {
      return AppEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: l10n.stockEmptyIssuesTitle,
        subtitle: l10n.stockEmptyIssuesSubtitle,
        actionLabel: l10n.stockIssueAction,
        onAction: _openIssue,
      );
    }

    final q = _pendingSearchCtrl.text.trim().toLowerCase();
    final filtered = issues.where((item) {
      if (q.isEmpty) return true;
      final v = item.issueView;
      return '${v.workerName ?? ''} ${v.processName ?? ''} ${v.lotNumber} ${v.designName} ${v.colourName}'
          .toLowerCase()
          .contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _pendingSearchCtrl,
          label: l10n.stockSearchHint,
          prefixIcon: Icons.search_rounded,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        if (filtered.isEmpty)
          AppEmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: l10n.reportsEmptyTitle,
            subtitle: l10n.reportsEmptySubtitle,
          )
        else
          for (int i = 0; i < filtered.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppMotionEntrance(
                index: i,
                child: _buildOpenIssueCard(context, filtered[i], localeCode),
              ),
            ),
      ],
    );
  }

  Widget _buildOpenIssueCard(
    BuildContext context,
    OpenIssueSummary item,
    String localeCode,
  ) {
    final l10n = context.l10n;
    final view = item.issueView;
    final m = view.movement;
    final colorScheme = Theme.of(context).colorScheme;
    final returnedTotal =
        view.returnedGoodQty +
        view.returnedDamagedQty +
        view.lostQty +
        view.shortageQty;

    return AppCard(
      onTap: () => _openReturn(m.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      '${view.workerName ?? '-'} • ${view.processName ?? '-'}',
                      variant: AppTextVariant.bodyLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      '${view.lotNumber} • ${view.designName} • ${view.colourName}',
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(
                label: '${view.remainingPendingQty} ${l10n.piecesUnit}',
                tone: AppStatusTone.pending,
                icon: Icons.hourglass_bottom_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              AppText(
                '${l10n.stockIssuedLabel}: ${m.quantity}',
                variant: AppTextVariant.numeric,
              ),
              AppText(
                '${l10n.stockPreviouslyReturnedLabel}: $returnedTotal',
                variant: AppTextVariant.numeric,
              ),
              AppText(
                '${MoneyFormatter.formatPaise(m.appliedRatePaise)} ${l10n.ratesPerPieceSuffix}',
                variant: AppTextVariant.numeric,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppText(
                IstDateTimeHelper.formatIstDateTime(
                  m.transactionAt,
                  locale: localeCode,
                ),
                variant: AppTextVariant.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
              AppButton(
                label: l10n.stockReturnAction,
                icon: Icons.assignment_returned_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => _openReturn(m.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBalances(
    BuildContext context,
    List<DesignColourStockBalance> balances,
  ) {
    final l10n = context.l10n;
    if (balances.isEmpty) {
      return AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: l10n.inventoryEmptyTitle,
        subtitle: l10n.inventoryEmptySubtitle,
      );
    }

    return AppDataTable<DesignColourStockBalance>(
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.designNameLabel),
        AppDataColumn(label: l10n.colourNameLabel),
        AppDataColumn(label: l10n.stockAvailableGoodLabel, numeric: true),
        AppDataColumn(label: l10n.stockPendingWorkerLabel, numeric: true),
        AppDataColumn(label: l10n.stockDamagedBucketLabel, numeric: true),
      ],
      items: balances,
      onRowTap: (b) {
        if (b.physicalAvailableInHouse > 0) {
          _openIssue(designColourId: b.designColourId);
        }
      },
      cellsBuilder: (b) => [
        AppText(b.lotNumber, fontWeight: FontWeight.w600),
        AppText(b.designName),
        AppText(b.colourName, fontWeight: FontWeight.w600),
        AppStatusBadge(
          label: '${b.physicalAvailableInHouse}',
          tone: b.physicalAvailableInHouse > 0
              ? AppStatusTone.good
              : AppStatusTone.neutral,
        ),
        AppStatusBadge(
          label: '${b.totalPendingWithWorkers}',
          tone: b.totalPendingWithWorkers > 0
              ? AppStatusTone.pending
              : AppStatusTone.neutral,
        ),
        AppStatusBadge(
          label: '${b.damagedBucket}',
          tone: b.damagedBucket > 0
              ? AppStatusTone.damaged
              : AppStatusTone.neutral,
        ),
      ],
      mobileCardBuilder: (_, b) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      '${b.lotNumber} • ${b.designName} • ${b.colourName}',
                      fontWeight: FontWeight.w700,
                    ),
                    AppText(
                      '${l10n.colourInitialQtyLabel}: ${b.initialQuantity} ${l10n.piecesUnit}',
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
              ),
              if (b.physicalAvailableInHouse > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: l10n.stockIssueAction,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _openIssue(designColourId: b.designColourId),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label:
                    '${l10n.stockAvailableGoodLabel}: ${b.physicalAvailableInHouse}',
                tone: AppStatusTone.good,
              ),
              AppStatusBadge(
                label:
                    '${l10n.stockPendingWorkerLabel}: ${b.totalPendingWithWorkers}',
                tone: AppStatusTone.pending,
              ),
              if (b.damagedBucket > 0)
                AppStatusBadge(
                  label: '${l10n.stockDamagedBucketLabel}: ${b.damagedBucket}',
                  tone: AppStatusTone.damaged,
                ),
              if (b.totalLost > 0)
                AppStatusBadge(
                  label: '${l10n.stockLostLabel}: ${b.totalLost}',
                  tone: AppStatusTone.info,
                ),
              if (b.totalShortage > 0)
                AppStatusBadge(
                  label: '${l10n.stockShortageLabel}: ${b.totalShortage}',
                  tone: AppStatusTone.info,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(
    BuildContext context,
    List<StockMovementView> history,
    String localeCode,
  ) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _historySearchCtrl,
          label: l10n.stockSearchHint,
          prefixIcon: Icons.search_rounded,
          onChanged: (_) => _reload(),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text(l10n.stockFilterAllTypes),
                selected: _typeFilter == null,
                onSelected: (_) {
                  setState(() => _typeFilter = null);
                  _reload();
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              for (final t in StockMovementType.values) ...[
                FilterChip(
                  label: Text(DomainLabelLocalizer.movementType(l10n, t)),
                  selected: _typeFilter == t,
                  onSelected: (_) {
                    setState(() => _typeFilter = t);
                    _reload();
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (history.isEmpty)
          AppEmptyState(
            icon: Icons.history_rounded,
            title: l10n.stockEmptyHistoryTitle,
            subtitle: l10n.stockEmptyHistorySubtitle,
          )
        else
          for (int i = 0; i < history.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              AppStatusBadge(
                                label: DomainLabelLocalizer.movementType(
                                  l10n,
                                  history[i].movement.movementType,
                                ),
                                tone: DomainLabelLocalizer.movementTone(
                                  history[i].movement.movementType,
                                ),
                              ),
                              if (history[i].isReversed)
                                AppStatusBadge(
                                  label: l10n.stockReversedBadge,
                                  tone: AppStatusTone.neutral,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppText(
                          '${history[i].movement.quantity} ${l10n.piecesUnit}',
                          variant: AppTextVariant.numeric,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      '${history[i].lotNumber} • ${history[i].designName} • ${history[i].colourName}',
                      fontWeight: FontWeight.w600,
                    ),
                    if (history[i].processName != null ||
                        history[i].workerName != null)
                      AppText(
                        '${history[i].processName ?? '-'} • ${history[i].workerName ?? '-'} • ${MoneyFormatter.formatPaise(history[i].movement.appliedRatePaise)} ${l10n.ratesPerPieceSuffix}',
                        variant: AppTextVariant.bodySmall,
                      ),
                    if (history[i].movement.reason != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        history[i].movement.reason!,
                        variant: AppTextVariant.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppText(
                          IstDateTimeHelper.formatIstDateTime(
                            history[i].movement.transactionAt,
                            locale: localeCode,
                          ),
                          variant: AppTextVariant.bodySmall,
                        ),
                        if (!history[i].isReversed &&
                            history[i].movement.movementType !=
                                StockMovementType.reversal)
                          AppButton(
                            label: l10n.stockReverseAction,
                            variant: AppButtonVariant.text,
                            onPressed: () => _confirmReverse(history[i]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildSummaries(
    BuildContext context,
    List<WorkerStockSummary> workers,
    List<ProcessStockSummary> processes,
  ) {
    final l10n = context.l10n;
    if (workers.isEmpty && processes.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: l10n.stockEmptyHistoryTitle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (workers.isNotEmpty) ...[
          AppHeading(l10n.stockTabWorkers, level: AppHeadingLevel.h3),
          const SizedBox(height: AppSpacing.sm),
          AppDataTable<WorkerStockSummary>(
            columns: [
              AppDataColumn(label: l10n.workerNameLabel),
              AppDataColumn(label: l10n.stockIssuedLabel, numeric: true),
              AppDataColumn(label: l10n.stockGoodReturnedLabel, numeric: true),
              AppDataColumn(label: l10n.stockDamagedBucketLabel, numeric: true),
              AppDataColumn(
                label: l10n.stockRemainingPendingLabel,
                numeric: true,
              ),
            ],
            items: workers,
            cellsBuilder: (w) => [
              AppText(w.workerName, fontWeight: FontWeight.w600),
              AppText('${w.issued}', variant: AppTextVariant.numeric),
              AppText('${w.goodReturned}', variant: AppTextVariant.numeric),
              AppText('${w.damaged}', variant: AppTextVariant.numeric),
              AppStatusBadge(
                label: '${w.pending}',
                tone: w.pending > 0
                    ? AppStatusTone.pending
                    : AppStatusTone.good,
              ),
            ],
            mobileCardBuilder: (_, w) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(w.workerName, fontWeight: FontWeight.w700),
                      AppText(
                        '${l10n.stockIssuedLabel}: ${w.issued} • ${l10n.stockGoodReturnedLabel}: ${w.goodReturned}',
                        variant: AppTextVariant.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppStatusBadge(
                  label: '${l10n.stockRemainingPendingLabel}: ${w.pending}',
                  tone: w.pending > 0
                      ? AppStatusTone.pending
                      : AppStatusTone.good,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (processes.isNotEmpty) ...[
          AppHeading(l10n.stockTabProcesses, level: AppHeadingLevel.h3),
          const SizedBox(height: AppSpacing.sm),
          AppDataTable<ProcessStockSummary>(
            columns: [
              AppDataColumn(label: l10n.processNameLabel),
              AppDataColumn(label: l10n.stockIssuedLabel, numeric: true),
              AppDataColumn(label: l10n.stockGoodReturnedLabel, numeric: true),
              AppDataColumn(label: l10n.stockDamagedBucketLabel, numeric: true),
              AppDataColumn(
                label: l10n.stockRemainingPendingLabel,
                numeric: true,
              ),
            ],
            items: processes,
            cellsBuilder: (p) => [
              AppText(p.processName, fontWeight: FontWeight.w600),
              AppText('${p.issued}', variant: AppTextVariant.numeric),
              AppText('${p.goodReturned}', variant: AppTextVariant.numeric),
              AppText('${p.damaged}', variant: AppTextVariant.numeric),
              AppStatusBadge(
                label: '${p.pending}',
                tone: p.pending > 0
                    ? AppStatusTone.pending
                    : AppStatusTone.good,
              ),
            ],
            mobileCardBuilder: (_, p) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(p.processName, fontWeight: FontWeight.w700),
                      AppText(
                        '${l10n.stockIssuedLabel}: ${p.issued} • ${l10n.stockGoodReturnedLabel}: ${p.goodReturned}',
                        variant: AppTextVariant.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppStatusBadge(
                  label: '${l10n.stockRemainingPendingLabel}: ${p.pending}',
                  tone: p.pending > 0
                      ? AppStatusTone.pending
                      : AppStatusTone.good,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
