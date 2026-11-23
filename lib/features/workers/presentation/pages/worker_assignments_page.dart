import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/presentation/bloc/worker_assignments_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Manage many-to-many process assignments for a specific worker.
final class WorkerAssignmentsPage extends StatelessWidget {
  const WorkerAssignmentsPage({super.key, required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkerAssignmentsCubit>(
      create: (_) => getIt<WorkerAssignmentsCubit>()..load(workerId),
      child: _WorkerAssignmentsView(workerId: workerId),
    );
  }
}

final class _WorkerAssignmentsView extends StatefulWidget {
  const _WorkerAssignmentsView({required this.workerId});

  final String workerId;

  @override
  State<_WorkerAssignmentsView> createState() => _WorkerAssignmentsViewState();
}

final class _WorkerAssignmentsViewState extends State<_WorkerAssignmentsView> {
  String? _selectedProcessId;
  String? _actionError;

  String _mapError(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'duplicate_assignment' => l10n.assignmentsDuplicateError,
      'inactive_worker' => l10n.assignmentsInactiveWorkerError,
      'inactive_process' => l10n.assignmentsInactiveProcessError,
      _ => code,
    };
  }

  Future<void> _assign(BuildContext context) async {
    final procId = _selectedProcessId;
    if (procId == null) return;
    setState(() => _actionError = null);
    final err = await context.read<WorkerAssignmentsCubit>().assignProcess(
      procId,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _actionError = _mapError(this.context, err));
    } else {
      setState(() => _selectedProcessId = null);
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WorkerProcessAssignmentEntity assignment,
  ) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: l10n.assignmentsRemoveConfirmTitle,
      message: l10n.assignmentsRemoveConfirmMessage,
      confirmLabel: l10n.assignmentsRemoveAction,
      cancelLabel: l10n.actionCancel,
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      final err = await context
          .read<WorkerAssignmentsCubit>()
          .deactivateAssignment(assignment.processId);
      if (err != null && mounted) {
        setState(() => _actionError = _mapError(this.context, err));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<WorkerAssignmentsCubit, WorkerAssignmentsState>(
      builder: (context, state) {
        if (state.status == WorkerAssignmentsStatus.loading ||
            state.status == WorkerAssignmentsStatus.initial) {
          return AppScaffold(
            title: l10n.assignmentsHeading,
            body: const AppLoader(),
          );
        }
        if (state.status == WorkerAssignmentsStatus.error ||
            state.worker == null) {
          return AppScaffold(
            title: l10n.assignmentsHeading,
            body: AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () =>
                  context.read<WorkerAssignmentsCubit>().load(widget.workerId),
            ),
          );
        }

        final worker = state.worker!;
        final assignedIds = state.assignments.map((a) => a.processId).toSet();
        final availableProcesses = state.activeProcesses
            .where((p) => !assignedIds.contains(p.id))
            .toList();
        final effectiveSelection =
            availableProcesses.any((p) => p.id == _selectedProcessId)
            ? _selectedProcessId
            : (availableProcesses.isNotEmpty
                  ? availableProcesses.first.id
                  : null);
        if (effectiveSelection != _selectedProcessId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedProcessId = effectiveSelection);
            }
          });
        }

        return AppScaffold(
          title: '${worker.name} — ${l10n.assignmentsHeading}',
          body: ListView(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      l10n.assignmentsSubtitle,
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!worker.isActive)
                      AppText(
                        l10n.assignmentsInactiveWorkerError,
                        color: Theme.of(context).colorScheme.error,
                      )
                    else if (availableProcesses.isEmpty)
                      AppText(
                        l10n.assignmentsNoAvailableProcesses,
                        variant: AppTextVariant.bodySmall,
                      )
                    else ...[
                      AppDropdown<ProcessEntity>(
                        key: ValueKey(
                          'assign_${availableProcesses.map((e) => e.id).join(',')}',
                        ),
                        label: l10n.assignmentsAddLabel,
                        value: availableProcesses.firstWhere(
                          (p) => p.id == effectiveSelection,
                          orElse: () => availableProcesses.first,
                        ),
                        items: availableProcesses,
                        itemLabelBuilder: (p) => p.name,
                        onChanged: (p) =>
                            setState(() => _selectedProcessId = p?.id),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: l10n.assignmentsAddAction,
                        icon: Icons.add_link,
                        isExpanded: true,
                        onPressed: effectiveSelection == null
                            ? null
                            : () => _assign(context),
                      ),
                    ],
                    if (_actionError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText(
                        _actionError!,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.assignments.isEmpty)
                AppEmptyState(
                  icon: Icons.link_off,
                  title: l10n.assignmentsEmptyTitle,
                  subtitle: l10n.assignmentsEmptySubtitle,
                )
              else
                ...state.assignments.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  a.processName,
                                  variant: AppTextVariant.bodyLarge,
                                  fontWeight: FontWeight.w600,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AppStatusBadge(
                                  label: a.processIsActive
                                      ? l10n.statusActive
                                      : l10n.statusInactive,
                                  tone: a.processIsActive
                                      ? AppStatusTone.good
                                      : AppStatusTone.neutral,
                                ),
                              ],
                            ),
                          ),
                          AppIconButton(
                            icon: Icons.currency_rupee,
                            tooltip: l10n.workerViewRateHistoryAction,
                            onPressed: () => context.push(
                              RoutePaths.workerRates(
                                worker.id,
                                processId: a.processId,
                              ),
                            ),
                          ),
                          AppIconButton(
                            icon: Icons.link_off,
                            tooltip: l10n.assignmentsRemoveAction,
                            onPressed: () => _confirmRemove(context, a),
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
