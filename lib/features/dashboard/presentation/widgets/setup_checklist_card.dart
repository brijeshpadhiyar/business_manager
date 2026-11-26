import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/services/form_draft_service.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:material_ui/material_ui.dart';

/// Dismissible 4-step First-Run Workshop Setup Checklist displayed on
/// [DashboardPage] while core workshop master data is still being configured.
final class SetupChecklistCard extends StatefulWidget {
  const SetupChecklistCard({
    super.key,
    required this.snapshot,
    required this.onNavigate,
  });

  final DashboardSnapshot snapshot;
  final ValueChanged<String> onNavigate;

  @override
  State<SetupChecklistCard> createState() => _SetupChecklistCardState();
}

final class _SetupChecklistCardState extends State<SetupChecklistCard> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<FormDraftService>()) {
      _dismissed = getIt<FormDraftService>().isSetupChecklistDismissed;
    }
  }

  bool get _profileCustomized =>
      widget.snapshot.businessNameEn != 'Business Manager' ||
      widget.snapshot.businessNameGu != 'બિઝનેસ મેનેજર';

  bool get _hasProcesses => widget.snapshot.activeProcessesCount > 0;
  bool get _hasWorkers => widget.snapshot.activeWorkersCount > 0;
  bool get _hasLots => widget.snapshot.totalLots > 0;

  int get _completedCount =>
      (_profileCustomized ? 1 : 0) +
      (_hasProcesses ? 1 : 0) +
      (_hasWorkers ? 1 : 0) +
      (_hasLots ? 1 : 0);

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    if (getIt.isRegistered<FormDraftService>()) {
      await getIt<FormDraftService>().setSetupChecklistDismissed(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _completedCount == 4) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        borderColor: colorScheme.primary.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppActionRow(
              content: Row(
                children: [
                  Icon(AppIcons.checklist, color: colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          l10n.setupChecklistTitle,
                          variant: AppTextVariant.bodyLarge,
                          fontWeight: FontWeight.w700,
                        ),
                        AppText(
                          l10n.setupChecklistSubtitle,
                          variant: AppTextVariant.bodySmall,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                AppStatusBadge(
                  label: '$_completedCount / 4',
                  tone: AppStatusTone.info,
                ),
                AppButton(
                  label: l10n.setupChecklistDismissAction,
                  variant: AppButtonVariant.text,
                  onPressed: _dismiss,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: _completedCount / 4),
            const SizedBox(height: AppSpacing.sm),
            _ChecklistStepTile(
              done: _profileCustomized,
              label: l10n.setupStepProfile,
              onTap: () => widget.onNavigate(RoutePaths.settingsBusinessProfile),
            ),
            _ChecklistStepTile(
              done: _hasProcesses,
              label: l10n.setupStepProcesses,
              onTap: () => widget.onNavigate(RoutePaths.processes),
            ),
            _ChecklistStepTile(
              done: _hasWorkers,
              label: l10n.setupStepWorkers,
              onTap: () => widget.onNavigate(RoutePaths.workerCreate),
            ),
            _ChecklistStepTile(
              done: _hasLots,
              label: l10n.setupStepFirstLot,
              onTap: () => widget.onNavigate(RoutePaths.lotCreate),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ChecklistStepTile extends StatelessWidget {
  const _ChecklistStepTile({
    required this.done,
    required this.label,
    required this.onTap,
  });

  final bool done;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        done ? AppIcons.success : AppIcons.currentStep,
        color: done ? colorScheme.secondary : colorScheme.primary,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
        ),
      ),
      trailing: done ? null : const Icon(AppIcons.chevronRight, size: 18),
      onTap: done ? null : onTap,
    );
  }
}
