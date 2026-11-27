import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/slips/presentation/slip_builder_helper.dart';
import 'package:business_manager/features/slips/presentation/widgets/slip_share_sheet.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Immutable summary shown on [StockSettlementSuccessView].
final class ReturnSuccessInfo {
  const ReturnSuccessInfo({
    required this.workerId,
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

  final String? workerId;
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

/// Label-value icon row used in settlement impact and success summaries.
final class SettlementImpactLine extends StatelessWidget {
  const SettlementImpactLine({
    super.key,
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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

/// Parent issue header card on [StockSettlementPage].
final class StockSettlementHeaderCard extends StatelessWidget {
  const StockSettlementHeaderCard({
    super.key,
    required this.detail,
    required this.localeCode,
  });

  final OpenIssueSummary detail;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final view = detail.issueView;
    final m = view.movement;
    final lockedMode = m.lockedBillingMode ?? BillingMode.receivedQty;
    final previouslySettled =
        view.returnedGoodQty +
        view.returnedDamagedQty +
        view.lostQty +
        view.shortageQty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeading(
            '${view.workerName ?? '-'} • ${view.processName ?? '-'}',
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.xxs),
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
                icon: AppIcons.pending,
              ),
              AppStatusBadge(
                label:
                    '${MoneyFormatter.formatPaise(m.appliedRatePaise)} ${l10n.ratesPerPieceSuffix}',
                tone: AppStatusTone.neutral,
                icon: AppIcons.lock,
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
    );
  }
}

/// Live consequences & labour impact preview card on [StockSettlementPage].
final class StockSettlementConsequencesCard extends StatelessWidget {
  const StockSettlementConsequencesCard({
    super.key,
    required this.good,
    required this.damaged,
    required this.lost,
    required this.shortage,
    required this.remainingAfter,
    required this.lockedMode,
    required this.labourEarned,
    required this.submitError,
  });

  final int good;
  final int damaged;
  final int lost;
  final int shortage;
  final int remainingAfter;
  final BillingMode lockedMode;
  final int labourEarned;
  final String? submitError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      color: colorScheme.surfaceContainer,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeading(l10n.stockConsequencesTitle, level: AppHeadingLevel.h3),
          const SizedBox(height: AppSpacing.sm),
          if (good > 0)
            SettlementImpactLine(
              icon: AppIcons.successOutline,
              color: semantic.goodStock,
              label: l10n.stockConsequenceGood,
              value: '+$good ${l10n.piecesUnit}',
            ),
          if (damaged > 0)
            SettlementImpactLine(
              icon: AppIcons.damaged,
              color: semantic.damaged,
              label: l10n.stockConsequenceDamaged,
              value: '+$damaged ${l10n.piecesUnit}',
            ),
          if (lost > 0)
            SettlementImpactLine(
              icon: AppIcons.help,
              color: semantic.advanceCredit,
              label: l10n.stockConsequenceLost,
              value: '$lost ${l10n.piecesUnit}',
            ),
          if (shortage > 0)
            SettlementImpactLine(
              icon: AppIcons.remove,
              color: semantic.advanceCredit,
              label: l10n.stockConsequenceShortage,
              value: '$shortage ${l10n.piecesUnit}',
            ),
          SettlementImpactLine(
            icon: AppIcons.pending,
            color: remainingAfter > 0 ? semantic.pending : semantic.goodStock,
            label: l10n.stockConsequencePending,
            value:
                '${remainingAfter < 0 ? 0 : remainingAfter} ${l10n.piecesUnit}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: AppDivider(),
          ),
          if (lockedMode == BillingMode.givenQty)
            AppText(
              l10n.stockConsequenceLabourAlreadyGiven,
              variant: AppTextVariant.bodySmall,
              color: colorScheme.onSurfaceVariant,
            )
          else if (labourEarned > 0)
            SettlementImpactLine(
              icon: AppIcons.accounting,
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
          if (submitError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppStatusBadge(
              label: submitError!,
              tone: AppStatusTone.damaged,
              icon: AppIcons.error,
            ),
          ],
        ],
      ),
    );
  }
}

/// Child settlements history list on [StockSettlementPage].
final class StockSettlementChildHistory extends StatelessWidget {
  const StockSettlementChildHistory({
    super.key,
    required this.settlements,
    required this.localeCode,
  });

  final List<StockMovementView> settlements;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHeading(l10n.stockDetailsHeading, level: AppHeadingLevel.h3),
        const SizedBox(height: AppSpacing.sm),
        for (final child in settlements)
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
    );
  }
}

/// Confirmation screen shown after a settlement/return succeeds.
final class StockSettlementSuccessView extends StatelessWidget {
  const StockSettlementSuccessView({
    super.key,
    required this.issueId,
    required this.info,
    required this.otherActiveProcesses,
    required this.transactionAtUtc,
    required this.notes,
    required this.onReceiveAnother,
    required this.onViewDetails,
  });

  final String issueId;
  final ReturnSuccessInfo info;
  final List<ProcessEntity> otherActiveProcesses;
  final int transactionAtUtc;
  final String notes;
  final VoidCallback onReceiveAnother;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
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
                      AppIcons.success,
                      color: semantic.goodStock,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.stockReturnSuccessTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                  child: AppActionRow(
                    content: AppText(
                      l10n.stockReturnUpdatedPendingLabel,
                      fontWeight: FontWeight.w600,
                    ),
                    actions: [
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
                  SettlementImpactLine(
                    icon: AppIcons.accounting,
                    color: semantic.goodStock,
                    label: l10n.stockConsequenceLabourEarned,
                    value: MoneyFormatter.formatPaise(info.labourEarnedPaise),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.slipShareReturnAction,
                  icon: AppIcons.share,
                  variant: AppButtonVariant.outlined,
                  isExpanded: true,
                  onPressed: () async {
                    final slip = await SlipBuilderHelper.buildReturnQcSlip(
                      referenceId:
                          'RET-${issueId.length > 6 ? issueId.substring(0, 6).toUpperCase() : issueId.toUpperCase()}',
                      lotNumber: info.lotNumber,
                      designName: info.designName,
                      colourName: info.colourName,
                      processName: info.processName,
                      workerName: info.workerName,
                      goodQty: info.goodQty,
                      damagedQty: info.damagedQty,
                      lostQty: info.lostQty,
                      shortageQty: info.shortageQty,
                      labourEarnedPaise: info.labourEarnedPaise,
                      transactionAtUtcMillis: transactionAtUtc,
                      notes: notes,
                    );
                    if (context.mounted) {
                      await SlipShareSheet.show(context, slip);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                if (info.goodQty > 0) ...[
                  AppButton(
                    label: l10n.stockIssueNextProcessAction,
                    icon: AppIcons.stockIssue,
                    isExpanded: true,
                    onPressed: () => context.pushReplacement(
                      RoutePaths.stockIssue(
                        designColourId: info.designColourId,
                      ),
                    ),
                  ),
                  if (otherActiveProcesses.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final proc in otherActiveProcesses.take(4))
                          AppChip.action(
                            icon: AppIcons.stockIssue,
                            label: proc.name,
                            onPressed: () => context.pushReplacement(
                              RoutePaths.stockIssue(
                                designColourId: info.designColourId,
                                processId: proc.id,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (info.workerId != null) ...[
                  AppButton(
                    label: l10n.uxActionRecordPayment,
                    icon: AppIcons.payment,
                    variant: AppButtonVariant.outlined,
                    isExpanded: true,
                    onPressed: () => context.pushReplacement(
                      RoutePaths.paymentCreate(workerId: info.workerId),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppButton(
                  label: l10n.stockReceiveAnotherReturnAction,
                  icon: AppIcons.receiveReturn,
                  variant: info.goodQty > 0
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  isExpanded: true,
                  onPressed: onReceiveAnother,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.stockDetailsHeading,
                  variant: AppButtonVariant.outlined,
                  isExpanded: true,
                  onPressed: onViewDetails,
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
