import 'package:business_manager/core/utils/app_memo.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/reports/domain/calculators/workshop_daily_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

enum _PendingSortMode { oldestFirst, highestPending, newestFirst }

/// Step 1 of Receive Return workflow: searchable, sortable & filterable Pending
/// Issues selector defaulting to Oldest First with IST pending-age badges.
final class ReceiveReturnPickerPage extends StatefulWidget {
  const ReceiveReturnPickerPage({
    super.key,
    this.initialWorkerId,
    this.initialProcessId,
    this.initialLotId,
  });

  final String? initialWorkerId;
  final String? initialProcessId;
  final String? initialLotId;

  @override
  State<ReceiveReturnPickerPage> createState() =>
      _ReceiveReturnPickerPageState();
}

final class _ReceiveReturnPickerPageState
    extends State<ReceiveReturnPickerPage> {
  final _viewMemo =
      AppMemo<(List<String>, List<String>, List<OpenIssueSummary>)>();
  final _repo = getIt<StockMovementRepository>();
  final _searchCtrl = TextEditingController();

  List<OpenIssueSummary> _issues = const [];
  String? _workerFilter;
  String? _processFilter;
  _PendingSortMode _sortMode = _PendingSortMode.oldestFirst;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_issues.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final issues = await _repo.getOpenIssues(
        workerId: widget.initialWorkerId,
        processId: widget.initialProcessId,
        lotId: widget.initialLotId,
      );
      if (!mounted) return;
      setState(() {
        _issues = issues;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return AppScaffold(
        title: l10n.stockReceiveReturnHeading,
        body: const AppSkeletonList(itemCount: 4),
      );
    }
    if (_error != null) {
      return AppScaffold(
        title: l10n.stockReceiveReturnHeading,
        body: AppErrorView(
          title: l10n.errorUnexpected,
          message: _error,
          retryLabel: l10n.actionRetry,
          onRetry: _load,
        ),
      );
    }

    final query = _searchCtrl.text.trim().toLowerCase();
    // Names, filtering and sorting run only when the data or a filter changes.
    final (
      workerNames,
      processNames,
      filtered,
    ) = _viewMemo([_issues, _workerFilter, _processFilter, query, _sortMode], () {
      final workerNames = <String>{
        for (final i in _issues)
          if (i.issueView.workerName != null) i.issueView.workerName!,
      }.toList()..sort();

      final processNames = <String>{
        for (final i in _issues)
          if (i.issueView.processName != null) i.issueView.processName!,
      }.toList()..sort();

      final filtered = _issues.where((item) {
        final v = item.issueView;
        if (_workerFilter != null && v.workerName != _workerFilter) {
          return false;
        }
        if (_processFilter != null && v.processName != _processFilter) {
          return false;
        }
        if (query.isEmpty) return true;
        final hay =
            '${v.workerName ?? ''} ${v.processName ?? ''} ${v.lotNumber} ${v.designName} ${v.colourName}'
                .toLowerCase();
        return hay.contains(query);
      }).toList();

      filtered.sort((a, b) {
        return switch (_sortMode) {
          _PendingSortMode.oldestFirst =>
            a.issueView.movement.transactionAt.compareTo(
              b.issueView.movement.transactionAt,
            ),
          _PendingSortMode.highestPending => b.remainingPending.compareTo(
            a.remainingPending,
          ),
          _PendingSortMode.newestFirst =>
            b.issueView.movement.transactionAt.compareTo(
              a.issueView.movement.transactionAt,
            ),
        };
      });
      return (workerNames, processNames, filtered);
    });

    return AppScaffold(
      title: l10n.stockReceiveReturnHeading,
      contentWidth: AppContentWidth.wide,
      actions: [
        AppIconButton(
          icon: Icons.refresh_rounded,
          tooltip: l10n.actionRetry,
          onPressed: _load,
        ),
      ],
      body: _issues.isEmpty
          ? AppEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: l10n.stockEmptyIssuesTitle,
              subtitle: l10n.stockEmptyIssuesSubtitle,
              actionLabel: l10n.stockIssueAction,
              onAction: () async {
                await context.push(RoutePaths.stockIssue());
                if (mounted) await _load();
              },
            )
          : CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppHeading(
                        l10n.stockSelectPendingIssueTitle,
                        level: AppHeadingLevel.h3,
                        subtitle: l10n.stockSelectPendingIssueSubtitle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppSearchField(
                        controller: _searchCtrl,
                        label: l10n.stockSearchHint,
                        debounceDuration: const Duration(milliseconds: 140),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(l10n.stockSortOldestFirst),
                              selected:
                                  _sortMode == _PendingSortMode.oldestFirst,
                              onSelected: (_) => setState(
                                () => _sortMode = _PendingSortMode.oldestFirst,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            ChoiceChip(
                              label: Text(l10n.stockSortHighestPending),
                              selected:
                                  _sortMode == _PendingSortMode.highestPending,
                              onSelected: (_) => setState(
                                () =>
                                    _sortMode = _PendingSortMode.highestPending,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            ChoiceChip(
                              label: Text(l10n.stockSortNewestFirst),
                              selected:
                                  _sortMode == _PendingSortMode.newestFirst,
                              onSelected: (_) => setState(
                                () => _sortMode = _PendingSortMode.newestFirst,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (workerNames.length > 1) ...[
                        const SizedBox(height: AppSpacing.sm),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: Text(l10n.stockFilterAllWorkers),
                                selected: _workerFilter == null,
                                onSelected: (_) =>
                                    setState(() => _workerFilter = null),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              for (final w in workerNames) ...[
                                FilterChip(
                                  label: Text(w),
                                  selected: _workerFilter == w,
                                  onSelected: (_) => setState(
                                    () => _workerFilter = _workerFilter == w
                                        ? null
                                        : w,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (processNames.length > 1) ...[
                        const SizedBox(height: AppSpacing.xs),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: Text(l10n.stockFilterAllProcesses),
                                selected: _processFilter == null,
                                onSelected: (_) =>
                                    setState(() => _processFilter = null),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              for (final p in processNames) ...[
                                FilterChip(
                                  label: Text(p),
                                  selected: _processFilter == p,
                                  onSelected: (_) => setState(
                                    () => _processFilter = _processFilter == p
                                        ? null
                                        : p,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: AppEmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: l10n.reportsEmptyTitle,
                      subtitle: l10n.reportsEmptySubtitle,
                    ),
                  )
                else
                  SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return _PendingIssueSelectionCard(
                        key: ValueKey<String>(item.issueView.movement.id),
                        item: item,
                        localeCode: localeCode,
                        colorScheme: colorScheme,
                        onSelect: () async {
                          final changed = await ctx.push<bool>(
                            RoutePaths.stockReturn(item.issueView.movement.id),
                          );
                          if (changed == true && mounted) {
                            await _load();
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

final class _PendingIssueSelectionCard extends StatelessWidget {
  const _PendingIssueSelectionCard({
    super.key,
    required this.item,
    required this.localeCode,
    required this.colorScheme,
    required this.onSelect,
  });

  final OpenIssueSummary item;
  final String localeCode;
  final ColorScheme colorScheme;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = item.issueView;
    final m = view.movement;
    final previouslyReturned =
        view.returnedGoodQty +
        view.returnedDamagedQty +
        view.lostQty +
        view.shortageQty;
    final ageDays = WorkshopDailyCalculator.pendingAgeDays(
      m.transactionAt,
      IstDateTimeHelper.nowUtcMillis(),
    );
    final ageLabel = ageDays == 0
        ? l10n.reportPresetToday
        : l10n.pendingAgeDaysBadge(ageDays);
    final ageTone = ageDays >= 7
        ? AppStatusTone.damaged
        : (ageDays >= 3 ? AppStatusTone.pending : AppStatusTone.info);

    return AppCard(
      onTap: onSelect,
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
                      view.workerName ?? '-',
                      variant: AppTextVariant.bodyLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    AppText(
                      '${view.processName ?? '-'} • ${view.lotNumber} • ${view.designName} • ${view.colourName}',
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppStatusBadge(
                    label:
                        '${l10n.stockRemainingPendingLabel}: ${item.remainingPending} ${l10n.piecesUnit}',
                    tone: AppStatusTone.pending,
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                  const SizedBox(height: 4),
                  AppStatusBadge(label: ageLabel, tone: ageTone),
                ],
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
                '${l10n.stockPreviouslyReturnedLabel}: $previouslyReturned',
                variant: AppTextVariant.numeric,
              ),
              AppText(
                '${MoneyFormatter.formatPaise(m.appliedRatePaise)} ${l10n.ratesPerPieceSuffix}',
                variant: AppTextVariant.numeric,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppText(
                  IstDateTimeHelper.formatIstDateTime(
                    m.transactionAt,
                    locale: localeCode,
                  ),
                  variant: AppTextVariant.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppButton(
                label: l10n.stockReturnAction,
                icon: Icons.assignment_returned_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: onSelect,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
