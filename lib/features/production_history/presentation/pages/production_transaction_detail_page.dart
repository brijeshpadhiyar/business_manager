import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:business_manager/features/production_history/presentation/bloc/transaction_detail_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Screen 10: Immutable Production / Financial Transaction Details Inspector.
///
/// Provides full traceability, rate snapshot, actor/approver metadata, audit
/// trail, and one-tap navigation to related Lot, Worker, Process, and linked
/// parent/child transactions.
final class ProductionTransactionDetailPage extends StatelessWidget {
  const ProductionTransactionDetailPage({
    super.key,
    required this.kindSegment,
    required this.transactionId,
  });

  final String kindSegment;
  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final kind = ProductionTransactionKind.fromRouteSegment(kindSegment);
    return BlocProvider<TransactionDetailCubit>(
      create: (_) => getIt<TransactionDetailCubit>()
        ..load(kind: kind, id: transactionId),
      child: _TransactionDetailView(kind: kind, transactionId: transactionId),
    );
  }
}

final class _TransactionDetailView extends StatelessWidget {
  const _TransactionDetailView({
    required this.kind,
    required this.transactionId,
  });

  final ProductionTransactionKind kind;
  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<TransactionDetailCubit, TransactionDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        return AppScaffold(
          title: l10n.prodHistoryTxDetailTitle,
          body: switch (state.status) {
            ProductionHistoryLoadStatus.initial ||
            ProductionHistoryLoadStatus.loading =>
              const AppSkeletonList(itemCount: 3),
            ProductionHistoryLoadStatus.error || _ when detail == null =>
              AppErrorView(
                title: l10n.errorUnexpected,
                message: state.errorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () => context.read<TransactionDetailCubit>().load(
                  kind: kind,
                  id: transactionId,
                ),
              ),
            _ => _buildDetail(context, detail, localeCode),
          },
        );
      },
    );
  }

  Widget _buildDetail(
    BuildContext context,
    ProductionTransactionDetail d,
    String localeCode,
  ) {
    final l10n = context.l10n;
    return ListView(
      children: [
        AppCard(
          isGlass: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: AppHeading(d.title, level: AppHeadingLevel.h3)),
                  AppStatusBadge(label: d.statusLabel, tone: AppStatusTone.info),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText('Transaction ID: ${d.id}', variant: AppTextVariant.bodySmall),
              AppText(
                'Transaction Time: ${AppDateTimeFormatter.formatDateTime(d.transactionAt, locale: localeCode)}',
                variant: AppTextVariant.bodySmall,
              ),
              AppText(
                'Recorded Time: ${AppDateTimeFormatter.formatDateTime(d.recordedAt, locale: localeCode)}',
                variant: AppTextVariant.bodySmall,
              ),
              if (d.actor != null)
                AppText('Recorded By: ${d.actor}', variant: AppTextVariant.bodySmall),
              if (d.approvedBy != null)
                AppText(
                  'Approved By: ${d.approvedBy}${d.authorizedViaPin ? ' (PIN Verified)' : ''}',
                  variant: AppTextVariant.bodySmall,
                ),
              const SizedBox(height: AppSpacing.md),
              // Quick Entity Cross-Navigation Chips
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (d.lotId != null)
                    AppButton(
                      label: '${l10n.prodHistoryOpenLot}: ${d.lotNumber ?? d.lotId}',
                      icon: Icons.inventory_2_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: () =>
                          context.push(RoutePaths.lotHistory(d.lotId!)),
                    ),
                  if (d.workerId != null)
                    AppButton(
                      label:
                          '${l10n.prodHistoryOpenWorker}: ${d.workerName ?? d.workerId}',
                      icon: Icons.person_outline_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: () =>
                          context.push(RoutePaths.workerDetail(d.workerId!)),
                    ),
                  if (d.processId != null)
                    AppButton(
                      label:
                          '${l10n.prodHistoryOpenProcess}: ${d.processName ?? d.processId}',
                      icon: Icons.precision_manufacturing_outlined,
                      variant: AppButtonVariant.outlined,
                      onPressed: () =>
                          context.push(RoutePaths.processDetail(d.processId!)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Quantities & Financial Rate Snapshot
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeading(
                l10n.prodHistoryLockedRateSnapshot,
                level: AppHeadingLevel.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (d.designName != null || d.colourName != null)
                _InfoRow(
                  label: 'Design / Colour',
                  value: '${d.designName ?? '-'} / ${d.colourName ?? '-'}',
                ),
              if (d.quantity != null)
                _InfoRow(
                  label: 'Quantity',
                  value: '${MoneyFormatter.formatQuantity(d.quantity!)} ${l10n.piecesUnit}',
                ),
              if (d.acceptedQuantity != null)
                _InfoRow(
                  label: l10n.prodHistoryTotalAccepted,
                  value:
                      '${MoneyFormatter.formatQuantity(d.acceptedQuantity!)} ${l10n.piecesUnit}',
                ),
              if (d.rejectedQuantity != null)
                _InfoRow(
                  label: l10n.prodHistoryTotalRejected,
                  value:
                      '${MoneyFormatter.formatQuantity(d.rejectedQuantity!)} ${l10n.piecesUnit}',
                ),
              if (d.lockedRatePaise != null)
                _InfoRow(
                  label: l10n.prodHistoryLockedRateSnapshot,
                  value: '${MoneyFormatter.formatPaise(d.lockedRatePaise!)} / pc',
                ),
              if (d.amountPaise != null)
                _InfoRow(
                  label: 'Amount',
                  value: MoneyFormatter.formatPaise(d.amountPaise!),
                ),
              if (d.referenceNo != null && d.referenceNo!.isNotEmpty)
                _InfoRow(label: 'Reference', value: d.referenceNo!),
              if (d.reason != null && d.reason!.isNotEmpty)
                _InfoRow(label: 'Reason', value: d.reason!),
              if (d.notes != null && d.notes!.isNotEmpty)
                _InfoRow(label: l10n.stockNotesLabel, value: d.notes!),
            ],
          ),
        ),

        if (d.relatedLinks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeading(
                  l10n.prodHistoryRelatedRecords,
                  level: AppHeadingLevel.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final link in d.relatedLinks)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link_rounded),
                    title: Text(link.label),
                    subtitle: Text(link.id),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(
                      RoutePaths.productionTransactionDetail(
                        link.kind.routeSegment,
                        link.id,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],

        if (d.auditTrail.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeading(
                  l10n.prodHistoryAuditTrail,
                  level: AppHeadingLevel.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final a in d.auditTrail)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded),
                    title: Text(a.actionType),
                    subtitle: Text(
                      '${AppDateTimeFormatter.formatDateTime(a.recordedAt, locale: localeCode)}'
                      '${a.actor != null ? ' • ${a.actor}' : ''}'
                      '${a.reason != null ? '\n${a.reason}' : ''}',
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

final class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(label, variant: AppTextVariant.bodySmall),
          ),
          Expanded(
            flex: 3,
            child: AppText(
              value,
              variant: AppTextVariant.numeric,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
