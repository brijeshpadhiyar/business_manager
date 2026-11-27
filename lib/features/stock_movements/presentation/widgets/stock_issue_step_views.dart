import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/slips/presentation/slip_builder_helper.dart';
import 'package:business_manager/features/slips/presentation/widgets/slip_share_sheet.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/presentation/widgets/stock_issue_step_widgets.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Immutable summary passed to [StockIssueSuccessView] after an atomic issue.
final class IssuedSuccessInfo {
  const IssuedSuccessInfo({
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

/// Step 1 card: Pick or review the Lot/Design/Colour variant to issue.
final class StockIssueStep1Card extends StatelessWidget {
  const StockIssueStep1Card({
    super.key,
    required this.selected,
    required this.pickingStock,
    required this.allBalances,
    required this.recentSuggestions,
    required this.searchController,
    required this.onlyInStock,
    required this.selectedColourId,
    required this.onRequestChangeSelection,
    required this.onSearchChanged,
    required this.onOnlyInStockChanged,
    required this.onSelectStock,
  });

  final DesignColourStockBalance? selected;
  final bool pickingStock;
  final List<DesignColourStockBalance> allBalances;
  final RecentIssueSuggestions recentSuggestions;
  final TextEditingController searchController;
  final bool onlyInStock;
  final String? selectedColourId;
  final VoidCallback onRequestChangeSelection;
  final VoidCallback onSearchChanged;
  final ValueChanged<bool> onOnlyInStockChanged;
  final ValueChanged<DesignColourStockBalance> onSelectStock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (selected != null && !pickingStock) {
      return AppCard(
        borderColor: context.semanticColors.goodStock.withValues(alpha: 0.45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const StockIssueStepBadge(number: 1, completed: true),
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
                  onPressed: onRequestChangeSelection,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              '${selected!.lotNumber} • ${selected!.designName} • ${selected!.colourName}',
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
                      '${l10n.stockAvailableGoodLabel}: ${selected!.physicalAvailableInHouse} ${l10n.piecesUnit}',
                  tone: selected!.physicalAvailableInHouse > 0
                      ? AppStatusTone.good
                      : AppStatusTone.damaged,
                  icon: AppIcons.successOutline,
                ),
                if (selected!.totalPendingWithWorkers > 0)
                  AppStatusBadge(
                    label:
                        '${l10n.stockPendingWorkerLabel}: ${selected!.totalPendingWithWorkers} ${l10n.piecesUnit}',
                    tone: AppStatusTone.pending,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    final query = searchController.text.trim().toLowerCase();
    final filtered =
        allBalances.where((b) {
          if (onlyInStock && b.physicalAvailableInHouse <= 0) return false;
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
              const StockIssueStepBadge(number: 1, completed: false),
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
          if (recentSuggestions.inStockDesignColourIds.isNotEmpty &&
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
                for (final id in recentSuggestions.inStockDesignColourIds)
                  for (final b in allBalances)
                    if (b.designColourId == id)
                      AppChip.action(
                        icon: AppIcons.productionHistory,
                        label:
                            '${b.lotNumber} • ${b.colourName} (${b.physicalAvailableInHouse})',
                        onPressed: () => onSelectStock(b),
                      ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppTextField(
            controller: searchController,
            label: l10n.stockSearchStockHint,
            prefixIcon: AppIcons.search,
            onChanged: (_) => onSearchChanged(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              AppChip.filter(
                label: l10n.stockOnlyAvailableFilter,
                selected: onlyInStock,
                onSelected: onOnlyInStockChanged,
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
                  final isSelected = b.designColourId == selectedColourId;
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
                    onTap: () => onSelectStock(b),
                    child: AppActionRow(
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            '${b.lotNumber} • ${b.designName}',
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
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
}

/// Step 2 card: Pick process, eligible worker, rate preview & advanced options.
final class StockIssueStep2Card extends StatelessWidget {
  const StockIssueStep2Card({
    super.key,
    required this.workDone,
    required this.recentSuggestions,
    required this.activeProcesses,
    required this.eligibleWorkers,
    required this.selectedProcessId,
    required this.selectedWorkerId,
    required this.ratePreview,
    required this.effectiveBillingMode,
    required this.overrideRate,
    required this.overrideRateController,
    required this.overrideReasonController,
    required this.notesController,
    required this.transactionAtUtc,
    required this.showAdvanced,
    required this.onSelectRecentPair,
    required this.onSelectProcess,
    required this.onSelectWorker,
    required this.onExpansionChanged,
    required this.onDateChanged,
    required this.onOverrideRateChanged,
    required this.onClearSubmitError,
  });

  final bool workDone;
  final RecentIssueSuggestions recentSuggestions;
  final List<ProcessEntity> activeProcesses;
  final List<ProcessAssignedWorkerSummary> eligibleWorkers;
  final String? selectedProcessId;
  final String? selectedWorkerId;
  final RateResolutionResult? ratePreview;
  final BillingMode effectiveBillingMode;
  final bool overrideRate;
  final TextEditingController overrideRateController;
  final TextEditingController overrideReasonController;
  final TextEditingController notesController;
  final int transactionAtUtc;
  final bool showAdvanced;
  final Future<void> Function(RecentWorkPairSuggestion pair) onSelectRecentPair;
  final ValueChanged<String> onSelectProcess;
  final ValueChanged<String> onSelectWorker;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<int> onDateChanged;
  final ValueChanged<bool> onOverrideRateChanged;
  final VoidCallback onClearSubmitError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StockIssueStepBadge(number: 2, completed: workDone),
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
          if (recentSuggestions.workPairs.isNotEmpty) ...[
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
                for (final pair in recentSuggestions.workPairs)
                  AppChip.action(
                    icon: AppIcons.quick,
                    label: '${pair.processName} • ${pair.workerName}',
                    onPressed: () => onSelectRecentPair(pair),
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
          if (activeProcesses.isEmpty)
            AppStatusBadge(
              label: l10n.stockNoActiveProcessesWarning,
              tone: AppStatusTone.pending,
              icon: AppIcons.warning,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final proc in activeProcesses)
                  AppChip(
                    label: proc.name,
                    selected: selectedProcessId == proc.id,
                    onSelected: (_) => onSelectProcess(proc.id),
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
          if (eligibleWorkers.isEmpty)
            AppStatusBadge(
              label: l10n.stockNoEligibleWorkers,
              tone: AppStatusTone.pending,
              icon: AppIcons.warning,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final w in eligibleWorkers)
                  AppChip(
                    label: w.workerName,
                    selected: selectedWorkerId == w.workerId,
                    onSelected: (_) => onSelectWorker(w.workerId),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          _RateAndBillingPreviewCard(
            ratePreview: ratePreview,
            effectiveBillingMode: effectiveBillingMode,
            overrideRate: overrideRate,
            overrideRateText: overrideRateController.text,
          ),
          const SizedBox(height: AppSpacing.xs),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: showAdvanced,
              onExpansionChanged: onExpansionChanged,
              leading: const Icon(AppIcons.filter, size: 18),
              title: AppText(
                l10n.stockAdvancedOptionsTitle,
                variant: AppTextVariant.label,
              ),
              children: [
                const SizedBox(height: AppSpacing.sm),
                AppDatePicker(
                  label: l10n.stockTransactionDateTimeLabel,
                  selectedUtcMillis: transactionAtUtc,
                  includeTime: true,
                  onDateSelectedUtcMillis: onDateChanged,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSwitch(
                  label: l10n.stockRateOverrideToggle,
                  value: overrideRate,
                  onChanged: onOverrideRateChanged,
                ),
                if (overrideRate) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: overrideRateController,
                    label: l10n.stockOverrideRateLabel,
                    prefixIcon: AppIcons.rupee,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => onClearSubmitError(),
                    validator: (v) => overrideRate
                        ? ValidationLocalizer.localize(
                            l10n,
                            AppValidators.nonNegativeAmountValidator(v),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: overrideReasonController,
                    label: l10n.stockOverrideReasonLabel,
                    maxLines: 2,
                    maxLength: ValidationLimits.maxNotesLength,
                    validator: (v) => overrideRate
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
                  controller: notesController,
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
}

final class _RateAndBillingPreviewCard extends StatelessWidget {
  const _RateAndBillingPreviewCard({
    required this.ratePreview,
    required this.effectiveBillingMode,
    required this.overrideRate,
    required this.overrideRateText,
  });

  final RateResolutionResult? ratePreview;
  final BillingMode effectiveBillingMode;
  final bool overrideRate;
  final String overrideRateText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = ratePreview;
    final colorScheme = Theme.of(context).colorScheme;
    final billingLabel = DomainLabelLocalizer.billingMode(
      l10n,
      effectiveBillingMode,
    );
    final localeCode = Localizations.localeOf(context).languageCode;

    Widget rateRow;
    if (overrideRate) {
      final overridePaise = AppValidators.parseRupeesToPaiseExact(
        overrideRateText,
        allowZero: true,
      ).paise;
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
                AppStatusBadge(
                  label: context.l10n.workerRateLabel,
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
                  AppStatusBadge(
                    label: context.l10n.stockStageDefaultBadge,
                    tone: AppStatusTone.info,
                  ),
                ],
              ),
              AppText(
                context.l10n.stockInheritedFrom(
                  processName,
                  MoneyFormatter.formatRatePaise(
                    rawDefaultRatePaise,
                    pricingUnit: pricingUnit,
                  ),
                ),
                variant: AppTextVariant.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        RateResolutionMissing() => AppStatusBadge(
          label: l10n.stockRateMissingWarning,
          tone: AppStatusTone.damaged,
          icon: AppIcons.error,
        ),
        RateResolutionConflict() => AppStatusBadge(
          label: l10n.stockRateConflictWarning,
          tone: AppStatusTone.damaged,
          icon: AppIcons.error,
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
          if (preview != null || overrideRate)
            const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(AppIcons.lock, size: 16, color: colorScheme.secondary),
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
}

/// Step 3 card: Enter issue quantity with quick increment pills.
final class StockIssueStep3Card extends StatelessWidget {
  const StockIssueStep3Card({
    super.key,
    required this.balance,
    required this.qtyExceeds,
    required this.parsedQty,
    required this.qtyController,
    required this.qtyFocusNode,
    required this.onChanged,
    required this.onAddQuickQty,
    required this.onSetExactQty,
  });

  final DesignColourStockBalance balance;
  final bool qtyExceeds;
  final int parsedQty;
  final TextEditingController qtyController;
  final FocusNode qtyFocusNode;
  final VoidCallback onChanged;
  final ValueChanged<int> onAddQuickQty;
  final ValueChanged<int> onSetExactQty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final available = balance.physicalAvailableInHouse;
    final qtyValid = parsedQty > 0 && !qtyExceeds;

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
              StockIssueStepBadge(number: 3, completed: qtyValid),
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
            controller: qtyController,
            focusNode: qtyFocusNode,
            label: l10n.stockIssueQuantityLabel,
            prefixIcon: AppIcons.number,
            suffixText: l10n.piecesUnit,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.tabular(
              Theme.of(
                context,
              ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
            ),
            errorText: qtyExceeds ? l10n.stockInsufficientGoodError : null,
            onChanged: (_) => onChanged(),
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
                  AppChip.action(
                    label: '+10',
                    onPressed: () => onAddQuickQty(10),
                  ),
                if (available >= 25)
                  AppChip.action(
                    label: '+25',
                    onPressed: () => onAddQuickQty(25),
                  ),
                if (available >= 50)
                  AppChip.action(
                    label: '+50',
                    onPressed: () => onAddQuickQty(50),
                  ),
                AppChip.action(
                  icon: AppIcons.doneAll,
                  label: '${l10n.stockQuickAllAvailable} ($available)',
                  onPressed: () => onSetExactQty(available),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Step 4 card: Compact review summary & labour estimate before submit.
final class StockIssueStep4Card extends StatelessWidget {
  const StockIssueStep4Card({
    super.key,
    required this.balance,
    required this.proc,
    required this.worker,
    required this.ratePaise,
    required this.qty,
    required this.canSubmit,
    required this.effectiveBillingMode,
    required this.transactionAtUtc,
    required this.submitError,
  });

  final DesignColourStockBalance balance;
  final ProcessEntity? proc;
  final ProcessAssignedWorkerSummary? worker;
  final int? ratePaise;
  final int qty;
  final bool canSubmit;
  final BillingMode effectiveBillingMode;
  final int transactionAtUtc;
  final String? submitError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    final expectedLabourPaise = (ratePaise != null && qty > 0)
        ? qty * ratePaise!
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
              const StockIssueStepBadge(number: 4, completed: false),
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
          StockIssueSummaryRow(
            label:
                '${l10n.lotLabelShort} / ${l10n.designNameLabel} / ${l10n.colourNameLabel}',
            value:
                '${balance.lotNumber} • ${balance.designName} • ${balance.colourName}',
          ),
          StockIssueSummaryRow(
            label: l10n.processNameLabel,
            value: proc?.name ?? '-',
          ),
          StockIssueSummaryRow(
            label: l10n.workerNameLabel,
            value: worker?.workerName ?? '-',
          ),
          StockIssueSummaryRow(
            label: l10n.stockIssueQuantityLabel,
            value: qty > 0 ? '$qty ${l10n.piecesUnit}' : '-',
            isNumeric: true,
          ),
          StockIssueSummaryRow(
            label: l10n.stockResolvedRateLabel,
            value: ratePaise != null
                ? '${MoneyFormatter.formatPaise(ratePaise!)} ${l10n.ratesPerPieceSuffix}'
                : '-',
            isNumeric: true,
          ),
          StockIssueSummaryRow(
            label: l10n.stockBillingModePreviewLabel,
            value: DomainLabelLocalizer.billingMode(l10n, effectiveBillingMode),
          ),
          StockIssueSummaryRow(
            label: l10n.stockTransactionDateTimeLabel,
            value: IstDateTimeHelper.formatIstDateTime(
              transactionAtUtc,
              locale: localeCode,
            ),
          ),
          if (expectedLabourPaise != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: AppDivider(),
            ),
            StockIssueSummaryRow(
              label: l10n.stockExpectedLabourLabel,
              value: MoneyFormatter.formatPaise(expectedLabourPaise),
              isNumeric: true,
              highlight: true,
            ),
            const SizedBox(height: AppSpacing.xxs),
            AppText(
              effectiveBillingMode == BillingMode.givenQty
                  ? l10n.stockPayableOnIssueNote
                  : l10n.stockPayableOnReturnNote,
              variant: AppTextVariant.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
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

/// Step 5 confirmation screen shown after stock is issued cleanly.
final class StockIssueSuccessView extends StatelessWidget {
  const StockIssueSuccessView({
    super.key,
    required this.info,
    required this.onIssueMore,
  });

  final IssuedSuccessInfo info;
  final VoidCallback onIssueMore;

  @override
  Widget build(BuildContext context) {
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
                      AppIcons.success,
                      color: semantic.goodStock,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.stockIssueSuccessTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                const AppDivider(),
                const SizedBox(height: AppSpacing.sm),
                StockIssueSummaryRow(
                  label: l10n.lotLabelShort,
                  value:
                      '${info.lotNumber} • ${info.designName} • ${info.colourName}',
                ),
                StockIssueSummaryRow(
                  label: l10n.processNameLabel,
                  value: info.processName,
                ),
                StockIssueSummaryRow(
                  label: l10n.workerNameLabel,
                  value: info.workerName,
                ),
                StockIssueSummaryRow(
                  label: l10n.stockIssuedLabel,
                  value: '${info.movement.quantity} ${l10n.piecesUnit}',
                  isNumeric: true,
                  highlight: true,
                ),
                StockIssueSummaryRow(
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
                      Icon(AppIcons.lot, color: semantic.goodStock),
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
                  label: l10n.slipShareChallanAction,
                  icon: AppIcons.share,
                  isExpanded: true,
                  onPressed: () async {
                    final slip = await SlipBuilderHelper.buildStockIssueChallan(
                      movementId: info.movement.id,
                      lotNumber: info.lotNumber,
                      designName: info.designName,
                      colourName: info.colourName,
                      processName: info.processName,
                      workerName: info.workerName,
                      quantity: info.movement.quantity,
                      ratePaise: info.movement.appliedRatePaise,
                      transactionAtUtcMillis: info.movement.transactionAt,
                      notes: info.movement.notes,
                    );
                    if (context.mounted) {
                      await SlipShareSheet.show(context, slip);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.stockIssueMoreAction,
                  icon: AppIcons.addCircle,
                  variant: AppButtonVariant.secondary,
                  isExpanded: true,
                  onPressed: onIssueMore,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.stockViewIssueDetailsAction,
                  icon: AppIcons.receiveReturn,
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
