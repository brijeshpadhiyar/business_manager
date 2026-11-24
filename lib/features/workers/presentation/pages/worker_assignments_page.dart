import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/presentation/bloc/worker_assignments_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Manage many-to-many process assignments and optional custom per-process
/// labour rates for a specific worker while preserving historical records on
/// deactivation.
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
  final _customRateCtrl = TextEditingController();
  String? _selectedProcessId;
  String? _actionError;
  bool _isAssigning = false;

  @override
  void dispose() {
    _customRateCtrl.dispose();
    super.dispose();
  }

  String _mapError(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'duplicate_assignment' => l10n.assignmentsDuplicateError,
      'inactive_worker' => l10n.assignmentsInactiveWorkerError,
      'inactive_process' => l10n.assignmentsInactiveProcessError,
      _ => ValidationLocalizer.localizeDomainCode(l10n, code, fallback: code),
    };
  }

  Future<void> _assign(BuildContext context) async {
    final procId = _selectedProcessId;
    if (procId == null || _isAssigning) return;

    int? customRatePaise;
    final rawRate = _customRateCtrl.text.trim();
    if (rawRate.isNotEmpty) {
      final parsed = AppValidators.parseRupeesToPaiseExact(
        rawRate,
        isRequired: false,
        allowZero: true,
      );
      if (!parsed.validation.isValid || parsed.paise == null) {
        setState(
          () => _actionError = 'Enter a valid non-negative custom rate.',
        );
        return;
      }
      customRatePaise = parsed.paise;
    }

    setState(() {
      _isAssigning = true;
      _actionError = null;
    });
    final err = await context.read<WorkerAssignmentsCubit>().assignProcess(
      procId,
      customRatePaise: customRatePaise,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _isAssigning = false;
        _actionError = _mapError(this.context, err);
      });
    } else {
      setState(() {
        _isAssigning = false;
        _selectedProcessId = null;
        _customRateCtrl.clear();
      });
    }
  }

  Future<void> _reactivate(BuildContext context, String processId) async {
    if (_isAssigning) return;
    setState(() {
      _isAssigning = true;
      _actionError = null;
    });
    final err = await context.read<WorkerAssignmentsCubit>().assignProcess(
      processId,
    );
    if (!mounted) return;
    setState(() {
      _isAssigning = false;
      if (err != null) _actionError = _mapError(this.context, err);
    });
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
    final colorScheme = Theme.of(context).colorScheme;
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
        final selectedProc = availableProcesses
            .where((p) => p.id == effectiveSelection)
            .firstOrNull;

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
                        color: colorScheme.error,
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
                        value: selectedProc ?? availableProcesses.first,
                        items: availableProcesses,
                        itemLabelBuilder: (p) => p.defaultRatePaise > 0
                            ? '${p.name} (Default: ${MoneyFormatter.formatRatePaise(p.defaultRatePaise, pricingUnit: p.defaultPricingUnit)})'
                            : p.name,
                        onChanged: (p) =>
                            setState(() => _selectedProcessId = p?.id),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _customRateCtrl,
                        label: 'Custom Worker Rate (₹ / pc, optional)',
                        hint:
                            (selectedProc != null &&
                                selectedProc.defaultRatePaise > 0)
                            ? 'Leave blank to inherit ${MoneyFormatter.formatRatePaise(selectedProc.defaultRatePaise, pricingUnit: selectedProc.defaultPricingUnit)}'
                            : 'Leave blank to use process default',
                        prefixIcon: Icons.currency_rupee_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          AppInputFormatters.currencyDecimal,
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: l10n.assignmentsAddAction,
                        icon: Icons.add_link,
                        isExpanded: true,
                        isLoading: _isAssigning,
                        onPressed: effectiveSelection == null || _isAssigning
                            ? null
                            : () => _assign(context),
                      ),
                    ],
                    if (_actionError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText(_actionError!, color: colorScheme.error),
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
                    child: AppCard.listItem(
                      key: ValueKey<String>('active_assign_${a.id}'),
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
              if (state.inactiveAssignments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                AppHeading(
                  'Deactivated Assignments (${state.inactiveAssignments.length})',
                  level: AppHeadingLevel.h3,
                  subtitle:
                      'Historical labour transactions & rates remain preserved.',
                ),
                const SizedBox(height: AppSpacing.sm),
                ...state.inactiveAssignments.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard.listItem(
                      key: ValueKey<String>('inactive_assign_${a.id}'),
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
                                  label: l10n.statusInactive,
                                  tone: AppStatusTone.neutral,
                                ),
                              ],
                            ),
                          ),
                          if (worker.isActive && a.processIsActive)
                            AppButton(
                              label: 'Reactivate',
                              icon: Icons.play_circle_outline_rounded,
                              variant: AppButtonVariant.outlined,
                              onPressed: _isAssigning
                                  ? null
                                  : () => _reactivate(context, a.processId),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
