import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/presentation/bloc/process_detail_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class ProcessDetailPage extends StatelessWidget {
  const ProcessDetailPage({super.key, required this.processId});

  final String processId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProcessDetailCubit>(
      create: (_) => getIt<ProcessDetailCubit>()..loadProcess(processId),
      child: _ProcessDetailView(processId: processId),
    );
  }
}

final class _ProcessDetailView extends StatelessWidget {
  const _ProcessDetailView({required this.processId});

  final String processId;

  Future<void> _confirmToggleActive(
    BuildContext context,
    ProcessEntity process,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<ProcessDetailCubit>();
    if (process.isActive) {
      final confirmed = await AppDialog.showConfirmation(
        context,
        title: l10n.processDeactivateConfirmTitle,
        message: l10n.processDeactivateConfirmMessage,
        confirmLabel: l10n.processDeactivateAction,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
      );
      if (confirmed == true) {
        await cubit.setActive(false);
      }
    } else {
      await cubit.setActive(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<ProcessDetailCubit, ProcessDetailState>(
      builder: (context, state) {
        if (state.status == ProcessDetailStatus.loading ||
            state.status == ProcessDetailStatus.initial) {
          return AppScaffold(
            title: l10n.processDetailsHeading,
            body: const AppLoader(),
          );
        }
        if (state.status == ProcessDetailStatus.error || state.detail == null) {
          return AppScaffold(
            title: l10n.processDetailsHeading,
            body: AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () =>
                  context.read<ProcessDetailCubit>().loadProcess(processId),
            ),
          );
        }

        final detail = state.detail!;
        final proc = detail.process;

        final billingLabel = switch (proc.billingModeOverride) {
          ProcessBillingModeOverride.receivedQty => l10n.billingModeReceivedQty,
          ProcessBillingModeOverride.givenQty => l10n.billingModeGivenQty,
          null => l10n.processBillingInheritGlobal,
        };

        return AppScaffold(
          title: proc.name,
          actions: [
            AppIconButton(
              icon: Icons.edit_outlined,
              tooltip: l10n.processEditAction,
              onPressed: () async {
                await context.push(RoutePaths.processEdit(proc.id));
                if (context.mounted) {
                  await context.read<ProcessDetailCubit>().loadProcess(proc.id);
                }
              },
            ),
          ],
          body: ListView(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppHeading(
                            proc.name,
                            level: AppHeadingLevel.h2,
                          ),
                        ),
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
                    if (proc.description != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText(proc.description!),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    AppText(
                      'Default Labour Rate: ${proc.defaultRatePaise > 0 ? MoneyFormatter.formatRatePaise(proc.defaultRatePaise, pricingUnit: proc.defaultPricingUnit) : 'Not set'}',
                      variant: AppTextVariant.bodySmall,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      '${l10n.processBillingOverrideLabel}: $billingLabel',
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      '${l10n.processIncludeDamagedLabel}: ${proc.includeDamagedInLabour ? l10n.statusEnabled : l10n.statusDisabled}',
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      '${l10n.createdAtLabel}: ${AppDateTimeFormatter.formatDateTime(proc.createdAt, locale: localeCode)}',
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      '${l10n.updatedAtLabel}: ${AppDateTimeFormatter.formatDateTime(proc.updatedAt, locale: localeCode)}',
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppButton(
                          label: l10n.processEditAction,
                          icon: Icons.edit_outlined,
                          variant: AppButtonVariant.outlined,
                          onPressed: () async {
                            await context.push(RoutePaths.processEdit(proc.id));
                            if (context.mounted) {
                              await context
                                  .read<ProcessDetailCubit>()
                                  .loadProcess(proc.id);
                            }
                          },
                        ),
                        AppButton(
                          label: proc.isActive
                              ? l10n.processDeactivateAction
                              : l10n.processActivateAction,
                          icon: proc.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          variant: proc.isActive
                              ? AppButtonVariant.destructive
                              : AppButtonVariant.secondary,
                          onPressed: () => _confirmToggleActive(context, proc),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppHeading(
                l10n.processAssignedWorkersHeading,
                level: AppHeadingLevel.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (detail.assignedWorkers.isEmpty)
                AppCard(
                  child: AppText(
                    l10n.processNoAssignedWorkers,
                    variant: AppTextVariant.bodySmall,
                  ),
                )
              else
                ...detail.assignedWorkers.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () =>
                          context.push(RoutePaths.workerDetail(w.workerId)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  w.workerName,
                                  variant: AppTextVariant.bodyLarge,
                                  fontWeight: FontWeight.w600,
                                ),
                                if (w.workerPhone != null)
                                  AppText(
                                    w.workerPhone!,
                                    variant: AppTextVariant.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          AppStatusBadge(
                            label: w.workerIsActive
                                ? l10n.statusActive
                                : l10n.statusInactive,
                            tone: w.workerIsActive
                                ? AppStatusTone.good
                                : AppStatusTone.neutral,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppHeading(
                l10n.processAuditHistoryHeading,
                level: AppHeadingLevel.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (detail.auditHistory.isEmpty)
                AppCard(
                  child: AppText(
                    l10n.processNoAuditHistory,
                    variant: AppTextVariant.bodySmall,
                  ),
                )
              else
                AppCard(
                  child: Column(
                    children: detail.auditHistory
                        .map(
                          (entry) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.history),
                            title: Text(
                              DomainLabelLocalizer.auditAction(
                                l10n,
                                entry.actionType,
                              ),
                            ),
                            subtitle: Text(
                              AppDateTimeFormatter.formatDateTime(
                                entry.recordedAt,
                                locale: localeCode,
                              ),
                            ),
                            trailing: entry.actor != null
                                ? Text(entry.actor!)
                                : null,
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
