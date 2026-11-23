import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/presentation/bloc/worker_detail_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Worker Profile Summary page.
///
/// Displays worker name, contact details, assigned processes, current per-piece
/// rates per process, historical rate links, and active/inactive status.
/// Intentionally omits labour earnings and payment balances (later milestones).
final class WorkerDetailPage extends StatelessWidget {
  const WorkerDetailPage({super.key, required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkerDetailCubit>(
      create: (_) => getIt<WorkerDetailCubit>()..loadWorker(workerId),
      child: _WorkerDetailView(workerId: workerId),
    );
  }
}

final class _WorkerDetailView extends StatelessWidget {
  const _WorkerDetailView({required this.workerId});

  final String workerId;

  Future<void> _confirmToggleActive(
    BuildContext context,
    WorkerEntity worker,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<WorkerDetailCubit>();
    if (worker.isActive) {
      final confirmed = await AppDialog.showConfirmation(
        context,
        title: l10n.workerDeactivateConfirmTitle,
        message: l10n.workerDeactivateConfirmMessage,
        confirmLabel: l10n.workerDeactivateAction,
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

    return BlocBuilder<WorkerDetailCubit, WorkerDetailState>(
      builder: (context, state) {
        if (state.status == WorkerDetailStatus.loading ||
            state.status == WorkerDetailStatus.initial) {
          return AppScaffold(
            title: l10n.workerDetailsHeading,
            body: const AppLoader(),
          );
        }
        if (state.status == WorkerDetailStatus.error || state.detail == null) {
          return AppScaffold(
            title: l10n.workerDetailsHeading,
            body: AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () =>
                  context.read<WorkerDetailCubit>().loadWorker(workerId),
            ),
          );
        }

        final detail = state.detail!;
        final worker = detail.worker;

        return AppScaffold(
          title: worker.name,
          actions: [
            AppIconButton(
              icon: Icons.edit_outlined,
              tooltip: l10n.workerEditAction,
              onPressed: () async {
                await context.push(RoutePaths.workerEdit(worker.id));
                if (context.mounted) {
                  await context.read<WorkerDetailCubit>().loadWorker(worker.id);
                }
              },
            ),
          ],
          body: ListView(
            children: [
              // Profile header & contact info
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppHeading(
                            worker.name,
                            level: AppHeadingLevel.h2,
                          ),
                        ),
                        AppStatusBadge(
                          label: worker.isActive
                              ? l10n.statusActive
                              : l10n.statusInactive,
                          tone: worker.isActive
                              ? AppStatusTone.good
                              : AppStatusTone.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppText(
                      l10n.workerContactHeading,
                      variant: AppTextVariant.label,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (worker.phone == null && worker.address == null)
                      AppText(
                        l10n.workerNoContactInfo,
                        variant: AppTextVariant.bodySmall,
                      )
                    else ...[
                      if (worker.phone != null)
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(child: AppText(worker.phone!)),
                          ],
                        ),
                      if (worker.address != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(child: AppText(worker.address!)),
                          ],
                        ),
                      ],
                    ],
                    if (worker.notes != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText(worker.notes!, variant: AppTextVariant.bodySmall),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      '${l10n.createdAtLabel}: ${IstDateTimeHelper.formatIstDateTime(worker.createdAt, locale: localeCode)}',
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppButton(
                          label: l10n.workerManageAssignmentsAction,
                          icon: Icons.link,
                          onPressed: () async {
                            await context.push(
                              RoutePaths.workerAssignments(worker.id),
                            );
                            if (context.mounted) {
                              await context
                                  .read<WorkerDetailCubit>()
                                  .loadWorker(worker.id);
                            }
                          },
                        ),
                        AppButton(
                          label: l10n.workerViewRateHistoryAction,
                          icon: Icons.currency_rupee,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            await context.push(
                              RoutePaths.workerRates(worker.id),
                            );
                            if (context.mounted) {
                              await context
                                  .read<WorkerDetailCubit>()
                                  .loadWorker(worker.id);
                            }
                          },
                        ),
                        AppButton(
                          label: l10n.accountingOpenLedgerAction,
                          icon: Icons.account_balance_wallet_outlined,
                          variant: AppButtonVariant.secondary,
                          onPressed: () =>
                              context.push(RoutePaths.workerLedger(worker.id)),
                        ),
                        AppButton(
                          label: l10n.accountingRecordPaymentAction,
                          icon: Icons.payments_outlined,
                          variant: AppButtonVariant.outlined,
                          onPressed: () => context.push(
                            RoutePaths.paymentCreate(workerId: worker.id),
                          ),
                        ),
                        AppButton(
                          label: worker.isActive
                              ? l10n.workerDeactivateAction
                              : l10n.workerActivateAction,
                          icon: worker.isActive
                              ? Icons.person_off_outlined
                              : Icons.person_outline,
                          variant: worker.isActive
                              ? AppButtonVariant.destructive
                              : AppButtonVariant.outlined,
                          onPressed: () =>
                              _confirmToggleActive(context, worker),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppHeading(
                l10n.workerAssignedProcessesHeading,
                level: AppHeadingLevel.h3,
                trailing: AppButton(
                  label: l10n.workerAddRateAction,
                  icon: Icons.add,
                  variant: AppButtonVariant.outlined,
                  onPressed: () async {
                    await context.push(RoutePaths.workerRateCreate(worker.id));
                    if (context.mounted) {
                      await context.read<WorkerDetailCubit>().loadWorker(
                        worker.id,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (detail.assignedProcesses.isEmpty)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        l10n.workerNoAssignedProcesses,
                        variant: AppTextVariant.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: l10n.workerManageAssignmentsAction,
                        icon: Icons.link,
                        variant: AppButtonVariant.outlined,
                        onPressed: () async {
                          await context.push(
                            RoutePaths.workerAssignments(worker.id),
                          );
                          if (context.mounted) {
                            await context.read<WorkerDetailCubit>().loadWorker(
                              worker.id,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                )
              else
                ...detail.assignedProcesses.map((summary) {
                  final assignment = summary.assignment;
                  final currentRate = summary.currentRate;
                  final rateDisplay = currentRate != null
                      ? '${MoneyFormatter.formatPaise(currentRate.ratePaise)} ${l10n.ratesPerPieceSuffix}'
                      : l10n.ratesNoCurrentRate;
                  final periodText = currentRate != null
                      ? '${currentRate.effectiveFrom} - ${currentRate.effectiveTo ?? l10n.ratesOngoingLabel}'
                      : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () async {
                        await context.push(
                          RoutePaths.workerRates(
                            worker.id,
                            processId: assignment.processId,
                          ),
                        );
                        if (context.mounted) {
                          await context.read<WorkerDetailCubit>().loadWorker(
                            worker.id,
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  assignment.processName,
                                  variant: AppTextVariant.bodyLarge,
                                  fontWeight: FontWeight.w700,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AppText(
                                  '${l10n.ratesCurrentRateLabel}: $rateDisplay',
                                  fontWeight: FontWeight.w600,
                                ),
                                if (periodText != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  AppText(
                                    periodText,
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AppStatusBadge(
                                label: '${summary.totalRateHistoryCount}',
                                tone: currentRate != null
                                    ? AppStatusTone.good
                                    : AppStatusTone.pending,
                                icon: Icons.history,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
