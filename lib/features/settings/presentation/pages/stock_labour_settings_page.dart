import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Stock & Labour Preferences backed directly by the authoritative
/// `BusinessProfileRepository` and `ProcessRepository` (zero duplicate storage).
///
/// Supports unlimited dynamic processes with prominent `+ Add Process` actions,
/// inline billing-mode & damaged-quantity controls, default labour rate display,
/// edit navigation, and activate/deactivate toggles.
final class StockLabourSettingsPage extends StatefulWidget {
  const StockLabourSettingsPage({super.key});

  @override
  State<StockLabourSettingsPage> createState() =>
      _StockLabourSettingsPageState();
}

final class _StockLabourSettingsPageState
    extends State<StockLabourSettingsPage> {
  final _processRepo = getIt<ProcessRepository>();

  List<ProcessEntity> _processes = const [];
  bool _loading = true;
  String? _busyProcessId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSkeleton = true}) async {
    if (showSkeleton) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final processes = await _processRepo.getProcesses();
      if (!mounted) return;
      setState(() {
        _processes = processes;
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

  void _openWorkStages() => context.go(RoutePaths.processes);

  Future<void> _openEditProcess(ProcessEntity proc) async {
    await context.push<bool>(RoutePaths.processEdit(proc.id));
    if (mounted) {
      await _load(showSkeleton: false);
    }
  }

  Future<void> _toggleProcessActive(ProcessEntity proc) async {
    if (_busyProcessId != null) return;
    final l10n = context.l10n;
    if (proc.isActive) {
      final confirmed = await AppDialog.showConfirmation(
        context,
        title: l10n.processDeactivateConfirmTitle,
        message: l10n.processDeactivateConfirmMessage,
        confirmLabel: l10n.processDeactivateAction,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _busyProcessId = proc.id);
    try {
      await _processRepo.setProcessActive(
        processId: proc.id,
        isActive: !proc.isActive,
      );
      if (!mounted) return;
      await _load(showSkeleton: false);
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, l10n.errorUnexpected);
      }
    } finally {
      if (mounted) {
        setState(() => _busyProcessId = null);
      }
    }
  }

  Future<void> _updateProcessQuickRule(
    ProcessEntity proc, {
    required ProcessBillingModeOverride? billingModeOverride,
    required bool includeDamagedInLabour,
  }) async {
    if (_busyProcessId != null) return;
    setState(() => _busyProcessId = proc.id);
    try {
      await _processRepo.updateProcess(
        processId: proc.id,
        name: proc.name,
        description: proc.description,
        isActive: proc.isActive,
        billingModeOverride: billingModeOverride,
        includeDamagedInLabour: includeDamagedInLabour,
        defaultRatePaise: proc.defaultRatePaise,
        defaultPricingUnit: proc.defaultPricingUnit,
      );
      if (!mounted) return;
      await _load(showSkeleton: false);
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, context.l10n.errorUnexpected);
      }
    } finally {
      if (mounted) {
        setState(() => _busyProcessId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return AppScaffold(
        title: l10n.settingsStockLabourTitle,
        body: const AppSkeletonList(itemCount: 3),
      );
    }
    if (_error != null) {
      return AppScaffold(
        title: l10n.settingsStockLabourTitle,
        body: AppErrorView(
          title: l10n.errorUnexpected,
          message: _error,
          retryLabel: l10n.actionRetry,
          onRetry: _load,
        ),
      );
    }

    final activeCount = _processes.where((p) => p.isActive).length;

    return AppScaffold(
      title: l10n.settingsStockLabourTitle,
      contentWidth: AppContentWidth.narrow,
      body: ListView(
        children: [
          AppCard(
            isGlass: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(AppIcons.success, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppHeading(
                        l10n.settingsFinalPaymentRuleTitle,
                        level: AppHeadingLevel.h3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  l10n.settingsFinalPaymentRuleBody,
                  variant: AppTextVariant.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppHeading(
                '${l10n.settingsProcessOverridesTitle} (${_processes.length})',
                level: AppHeadingLevel.h3,
                subtitle:
                    '${l10n.settingsProcessOverridesSubtitle} ($activeCount ${l10n.statusActive})',
              ),
              AppButton(
                label: l10n.settingsManageWorkStagesAction,
                icon: AppIcons.process,
                variant: AppButtonVariant.outlined,
                onPressed: _openWorkStages,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_processes.isEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    l10n.settingsNoProcessesYet,
                    variant: AppTextVariant.bodySmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: l10n.settingsManageWorkStagesAction,
                    icon: AppIcons.process,
                    variant: AppButtonVariant.outlined,
                    onPressed: _openWorkStages,
                  ),
                ],
              ),
            )
          else
            for (final proc in _processes)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard.listItem(
                  key: ValueKey<String>('settings_proc_${proc.id}'),
                  onTap: () => _openEditProcess(proc),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppActionRow(
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              proc.name,
                              variant: AppTextVariant.bodyLarge,
                              fontWeight: FontWeight.w700,
                            ),
                            if (proc.description != null &&
                                proc.description!.trim().isNotEmpty)
                              AppText(
                                proc.description!,
                                variant: AppTextVariant.bodySmall,
                                color: colorScheme.onSurfaceVariant,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        actions: [
                          AppStatusBadge(
                            label: proc.isActive
                                ? l10n.statusActive
                                : l10n.statusInactive,
                            tone: proc.isActive
                                ? AppStatusTone.good
                                : AppStatusTone.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          AppStatusBadge(
                            label: proc.defaultRatePaise > 0
                                ? 'Default: ${MoneyFormatter.formatRatePaise(proc.defaultRatePaise, pricingUnit: proc.defaultPricingUnit)}'
                                : 'No default labour rate',
                            tone: proc.defaultRatePaise > 0
                                ? AppStatusTone.info
                                : AppStatusTone.neutral,
                          ),
                          AppStatusBadge(
                            label: proc.billingModeOverride == null
                                ? l10n.settingsProcessInheritsGlobal
                                : '${l10n.settingsProcessOverridesGlobal}: ${proc.billingModeOverride == ProcessBillingModeOverride.givenQty ? l10n.billingModeGivenQty : l10n.billingModeReceivedQty}',
                            tone: proc.billingModeOverride == null
                                ? AppStatusTone.neutral
                                : AppStatusTone.pending,
                          ),
                          AppStatusBadge(
                            label: proc.includeDamagedInLabour
                                ? l10n.settingsDamagedIncludedShort
                                : l10n.settingsDamagedExcludedShort,
                            tone: proc.includeDamagedInLabour
                                ? AppStatusTone.info
                                : AppStatusTone.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppDropdown<String>(
                        label: l10n.processBillingOverrideLabel,
                        value: proc.billingModeOverride?.dbValue ?? 'GLOBAL',
                        items: const ['GLOBAL', 'RECEIVED_QTY', 'GIVEN_QTY'],
                        itemLabelBuilder: (item) => switch (item) {
                          'RECEIVED_QTY' => l10n.billingModeReceivedQty,
                          'GIVEN_QTY' => l10n.billingModeGivenQty,
                          _ => l10n.processBillingInheritGlobal,
                        },
                        onChanged: _busyProcessId == proc.id
                            ? null
                            : (value) {
                                if (value == null) return;
                                final nextOverride = value == 'GLOBAL'
                                    ? null
                                    : ProcessBillingModeOverride.fromDbValue(
                                        value,
                                      );
                                if (nextOverride != proc.billingModeOverride) {
                                  _updateProcessQuickRule(
                                    proc,
                                    billingModeOverride: nextOverride,
                                    includeDamagedInLabour:
                                        proc.includeDamagedInLabour,
                                  );
                                }
                              },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppSwitch(
                        label:
                            '${l10n.processIncludeDamagedLabel} (Retired — Always Excluded)',
                        value: false,
                        onChanged: null,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          alignment: WrapAlignment.end,
                          children: [
                            AppButton(
                              label: l10n.processEditAction,
                              icon: AppIcons.edit,
                              variant: AppButtonVariant.outlined,
                              onPressed: _busyProcessId == proc.id
                                  ? null
                                  : () => _openEditProcess(proc),
                            ),
                            AppButton(
                              label: proc.isActive
                                  ? l10n.processDeactivateAction
                                  : l10n.processActivateAction,
                              icon: proc.isActive
                                  ? AppIcons.pause
                                  : AppIcons.resume,
                              variant: proc.isActive
                                  ? AppButtonVariant.secondary
                                  : AppButtonVariant.primary,
                              isLoading: _busyProcessId == proc.id,
                              onPressed: _busyProcessId == proc.id
                                  ? null
                                  : () => _toggleProcessActive(proc),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
