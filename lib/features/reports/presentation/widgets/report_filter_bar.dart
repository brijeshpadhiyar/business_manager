import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Compact IST Date Presets + expandable dimension filter bar (Worker, Process,
/// cascading Lot -> Design -> Colour, custom date range, and debounced search).
final class ReportFilterBar extends StatefulWidget {
  const ReportFilterBar({
    super.key,
    required this.state,
    required this.searchController,
  });

  final ReportsState state;
  final TextEditingController searchController;

  @override
  State<ReportFilterBar> createState() => _ReportFilterBarState();
}

final class _ReportFilterBarState extends State<ReportFilterBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ReportsCubit>();
    final filter = widget.state.filter;
    final opts =
        widget.state.bundle?.filterOptions ?? const ReportFilterOptions();

    final presets = <(ReportDatePreset, String)>[
      (ReportDatePreset.today, l10n.reportPresetToday),
      (ReportDatePreset.yesterday, l10n.reportPresetYesterday),
      (ReportDatePreset.thisWeek, l10n.reportPresetThisWeek),
      (ReportDatePreset.thisMonth, l10n.reportPresetThisMonth),
      (ReportDatePreset.previousMonth, l10n.reportPresetPreviousMonth),
      (ReportDatePreset.allTime, l10n.reportPresetAllTime),
    ];

    final filteredDesigns = filter.lotId == null
        ? opts.designs
        : opts.designs.where((d) => d.parentId == filter.lotId).toList();
    final filteredColours = filter.lotDesignId == null
        ? (filter.lotId == null
              ? opts.colours
              : opts.colours
                    .where(
                      (c) => filteredDesigns.any((d) => d.id == c.parentId),
                    )
                    .toList())
        : opts.colours.where((c) => c.parentId == filter.lotDesignId).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. IST Date Preset Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (preset, label) in presets) ...[
                  AppChip(
                    label: label,
                    selected: filter.preset == preset,
                    onSelected: (_) => cubit.applyPreset(preset),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (filter.preset == ReportDatePreset.custom)
                  AppChip(
                    label: l10n.reportPresetCustom,
                    selected: true,
                    onSelected: (_) => setState(() => _expanded = true),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 2. Search + Expandable Dimension Filters Toggle
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: widget.searchController,
                  label: l10n.reportsSearchHint,
                  prefixIcon: AppIcons.search,
                  maxLength: ValidationLimits.maxSearchLength,
                  onChanged: cubit.updateSearchQuery,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppChip.filter(
                icon: _expanded ? AppIcons.clearFilter : AppIcons.filter,
                label: l10n.reportFiltersButton,
                selected: _expanded || filter.hasDimensionFilters,
                onSelected: (_) => setState(() => _expanded = !_expanded),
              ),
            ],
          ),

          // 3. Expanded Dimension & Custom Date Controls
          AppExpandableSection(
            expanded: _expanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                AppFormRow(
                  spacing: AppSpacing.sm,
                  children: [
                    AppDatePicker(
                      label: l10n.accountingFromDateLabel,
                      selectedUtcMillis: filter.fromUtcMillis,
                      onDateSelectedUtcMillis: (utc) =>
                          cubit.setCustomDateRange(
                            fromUtcMillis: IstDateRangePresets.startOfIstDay(
                              utc,
                            ),
                          ),
                    ),
                    AppDatePicker(
                      label: l10n.accountingToDateLabel,
                      selectedUtcMillis: filter.toUtcMillis,
                      errorText: widget.state.dateRangeErrorCode != null
                          ? ValidationLocalizer.localizeDomainCode(
                              l10n,
                              widget.state.dateRangeErrorCode!,
                            )
                          : null,
                      onDateSelectedUtcMillis: (utc) =>
                          cubit.setCustomDateRange(
                            toUtcMillis: IstDateRangePresets.endOfIstDay(utc),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppFormRow(
                  spacing: AppSpacing.sm,
                  children: [
                    _NullableOptionDropdown(
                      label: l10n.workerNameLabel,
                      allLabel: l10n.reportAllOption,
                      options: opts.workers,
                      selectedId: filter.workerId,
                      onChanged: cubit.setWorkerFilter,
                    ),
                    _NullableOptionDropdown(
                      label: l10n.processNameLabel,
                      allLabel: l10n.reportAllOption,
                      options: opts.processes,
                      selectedId: filter.processId,
                      onChanged: cubit.setProcessFilter,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _NullableOptionDropdown(
                  label: l10n.lotNumberLabel,
                  allLabel: l10n.reportAllOption,
                  options: opts.lots,
                  selectedId: filter.lotId,
                  onChanged: cubit.setLotFilter,
                ),
                if (filteredDesigns.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppFormRow(
                    spacing: AppSpacing.sm,
                    children: [
                      _NullableOptionDropdown(
                        label: l10n.designNameLabel,
                        allLabel: l10n.reportAllOption,
                        options: filteredDesigns,
                        selectedId: filter.lotDesignId,
                        onChanged: cubit.setDesignFilter,
                      ),
                      if (filteredColours.isNotEmpty)
                        _NullableOptionDropdown(
                          label: l10n.colourNameLabel,
                          allLabel: l10n.reportAllOption,
                          options: filteredColours,
                          selectedId: filter.designColourId,
                          onChanged: cubit.setColourFilter,
                        ),
                    ],
                  ),
                ],
                if (filter.hasAnyActiveFilter) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: l10n.accountingClearFilters,
                      variant: AppButtonVariant.text,
                      onPressed: () {
                        widget.searchController.clear();
                        cubit.clearAllFilters();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _NullableOptionDropdown extends StatelessWidget {
  const _NullableOptionDropdown({
    required this.label,
    required this.allLabel,
    required this.options,
    required this.selectedId,
    required this.onChanged,
  });

  final String label;
  final String allLabel;
  final List<ReportFilterOption> options;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  static const String _allSentinel = '__ALL__';

  @override
  Widget build(BuildContext context) {
    final ids = <String>[_allSentinel, ...options.map((o) => o.id)];
    final labels = <String, String>{
      _allSentinel: allLabel,
      for (final o in options) o.id: o.label,
    };
    final effectiveValue = selectedId != null && labels.containsKey(selectedId)
        ? selectedId!
        : _allSentinel;

    return AppDropdown<String>(
      label: label,
      items: ids,
      value: effectiveValue,
      itemLabelBuilder: (id) => labels[id] ?? id,
      onChanged: (val) => onChanged(val == _allSentinel ? null : val),
    );
  }
}
