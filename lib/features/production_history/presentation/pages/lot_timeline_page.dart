import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/presentation/bloc/lot_history_cubit.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Screen 3: Exact-Timestamp Chronological Lot Timeline.
final class LotTimelinePage extends StatelessWidget {
  const LotTimelinePage({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LotHistoryCubit>(
      create: (_) => getIt<LotHistoryCubit>()..loadLot(lotId),
      child: _LotTimelineView(lotId: lotId),
    );
  }
}

final class _LotTimelineView extends StatelessWidget {
  const _LotTimelineView({required this.lotId});

  final String lotId;

  IconData _iconFor(LotTimelineEventKind kind) => switch (kind) {
    LotTimelineEventKind.lotCreated => AppIcons.lotAdd,
    LotTimelineEventKind.processAssigned ||
    LotTimelineEventKind.stockIssued => AppIcons.stockIssue,
    LotTimelineEventKind.handoverTransfer => AppIcons.stockMovements,
    LotTimelineEventKind.stockReturned => AppIcons.receiveReturn,
    LotTimelineEventKind.inspectionApproved => AppIcons.qcPassed,
    LotTimelineEventKind.inspectionRejected => AppIcons.damaged,
    LotTimelineEventKind.rejectionRepaired => AppIcons.repair,
    LotTimelineEventKind.repairReapproved => AppIcons.success,
    LotTimelineEventKind.settlementLost ||
    LotTimelineEventKind.settlementShortage => AppIcons.warning,
    LotTimelineEventKind.movementReversed => AppIcons.reverse,
    LotTimelineEventKind.lotCompleted => AppIcons.milestone,
  };

  AppStatusTone _toneFor(LotTimelineEventKind kind) => switch (kind) {
    LotTimelineEventKind.inspectionApproved ||
    LotTimelineEventKind.repairReapproved ||
    LotTimelineEventKind.lotCompleted => AppStatusTone.good,
    LotTimelineEventKind.inspectionRejected ||
    LotTimelineEventKind.settlementLost ||
    LotTimelineEventKind.settlementShortage ||
    LotTimelineEventKind.movementReversed => AppStatusTone.damaged,
    LotTimelineEventKind.stockReturned ||
    LotTimelineEventKind.rejectionRepaired => AppStatusTone.pending,
    _ => AppStatusTone.info,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<LotHistoryCubit, LotHistoryState>(
      builder: (context, state) {
        final history = state.history;
        return AppScaffold(
          title: history != null
              ? '${history.lot.lotNumber} — ${l10n.prodHistoryLotTimelineTitle}'
              : l10n.prodHistoryLotTimelineTitle,
          actions: [
            AppIconButton(
              icon: AppIcons.productionHistory,
              tooltip: l10n.prodHistoryViewLotHistory,
              onPressed: () => context.push(RoutePaths.lotHistory(lotId)),
            ),
          ],
          body: switch (state.status) {
            ProductionHistoryLoadStatus.initial ||
            ProductionHistoryLoadStatus.loading => const AppSkeletonList(
              itemCount: 5,
            ),
            ProductionHistoryLoadStatus.error ||
            _ when history == null => AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () => context.read<LotHistoryCubit>().loadLot(lotId),
            ),
            _ => _buildTimeline(context, history, localeCode),
          },
        );
      },
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    LotCompleteHistory history,
    String localeCode,
  ) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final events = history.timeline;

    if (events.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.timeline,
        title: l10n.prodHistoryLotTimelineTitle,
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        final isLast = index == events.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        _iconFor(e.kind),
                        size: 16,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard.listItem(
                    onTap:
                        e.kind == LotTimelineEventKind.lotCreated ||
                            e.kind == LotTimelineEventKind.lotCompleted
                        ? null
                        : () => context.push(
                            RoutePaths.productionTransactionDetail(
                              e.transactionKind.routeSegment,
                              e.transactionId,
                            ),
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppText(
                                '${index + 1}. ${e.title}',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (e.quantity != null)
                              AppStatusBadge(
                                label:
                                    '${MoneyFormatter.formatQuantity(e.quantity!)} ${l10n.piecesUnit}',
                                tone: _toneFor(e.kind),
                              ),
                          ],
                        ),
                        if (e.subtitle != null && e.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          AppText(
                            e.subtitle!,
                            variant: AppTextVariant.bodySmall,
                          ),
                        ],
                        if (e.reason != null && e.reason!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          AppText(
                            'Reason: ${e.reason}',
                            variant: AppTextVariant.bodySmall,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppText(
                              AppDateTimeFormatter.formatDateTime(
                                e.timestampUtcMillis,
                                locale: localeCode,
                              ),
                              variant: AppTextVariant.bodySmall,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            if (e.actor != null)
                              AppText(
                                '• ${e.actor}',
                                variant: AppTextVariant.bodySmall,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            if (e.workerId != null)
                              AppChip.action(
                                dense: true,
                                label: e.workerName ?? 'Worker',
                                onPressed: () => context.push(
                                  RoutePaths.workerDetail(e.workerId!),
                                ),
                              ),
                            if (e.processId != null)
                              AppChip.action(
                                dense: true,
                                label: e.processName ?? 'Process',
                                onPressed: () => context.push(
                                  RoutePaths.processDetail(e.processId!),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
