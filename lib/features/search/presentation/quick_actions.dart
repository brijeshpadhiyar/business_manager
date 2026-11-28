import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/app_gap.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// One everyday task the user can start in a single tap.
final class AppQuickAction {
  const AppQuickAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.route,
  });

  final String id;
  final IconData icon;
  final String label;
  final String route;
}

/// The daily tasks of a job-work business, in the order people do them most.
List<AppQuickAction> buildQuickActions(BuildContext context) {
  final l10n = context.l10n;
  return [
    AppQuickAction(
      id: 'issue',
      icon: AppIcons.stockIssue,
      label: l10n.uxActionIssueStock,
      route: RoutePaths.stockIssuePath,
    ),
    AppQuickAction(
      id: 'receive',
      icon: AppIcons.receiveReturn,
      label: l10n.uxActionReceiveWork,
      route: RoutePaths.stockReturnPicker,
    ),
    AppQuickAction(
      id: 'payment',
      icon: AppIcons.payment,
      label: l10n.uxActionRecordPayment,
      route: RoutePaths.paymentCreatePath,
    ),
    AppQuickAction(
      id: 'lot',
      icon: AppIcons.lotAdd,
      label: l10n.uxActionNewLot,
      route: RoutePaths.lotCreate,
    ),
    AppQuickAction(
      id: 'inspect',
      icon: AppIcons.qcInspect,
      label: l10n.uxActionInspections,
      route: RoutePaths.inspectionQueue,
    ),
    AppQuickAction(
      id: 'worker',
      icon: AppIcons.workerAdd,
      label: l10n.uxActionAddWorker,
      route: RoutePaths.workerCreate,
    ),
    AppQuickAction(
      id: 'workStage',
      icon: AppIcons.process,
      label: l10n.processQuickCreateAction,
      route: RoutePaths.processCreate,
    ),
    AppQuickAction(
      id: 'dispatch',
      icon: AppIcons.dispatch,
      label: l10n.dispatchNewAction,
      route: RoutePaths.dispatchCreatePath,
    ),
    AppQuickAction(
      id: 'expense',
      icon: AppIcons.expense,
      label: l10n.cashbookRecordExpenseAction,
      route: RoutePaths.expenseCreate,
    ),
  ];
}

/// Large, thumb-friendly buttons for the everyday tasks, shown at the top of
/// the dashboard. Two columns on phones, three on tablets, one row on desktop.
final class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key, this.onReturn, this.showTitle = true});

  /// Hide the built-in title when the host page already has a heading.
  final bool showTitle;

  /// Called after the user comes back from a quick action, so the dashboard
  /// can refresh its numbers.
  final VoidCallback? onReturn;

  String? _guideTargetFor(String id) {
    return switch (id) {
      'issue' => GuideTargetId.dashQuickIssue,
      'receive' => GuideTargetId.dashQuickReceive,
      'payment' => GuideTargetId.dashQuickPayment,
      'lot' => GuideTargetId.dashQuickNewLot,
      'inspect' => GuideTargetId.dashQuickInspect,
      'worker' => GuideTargetId.dashQuickAddWorker,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final actions = buildQuickActions(context);
    final theme = Theme.of(context);
    final d = context.density;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            context.l10n.uxQuickActions,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const AppGap.sm(),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1024
                ? actions.length
                : width >= 600
                ? (d.isCompact ? 4 : 3)
                : (d.isCompact ? 3 : 2);
            final gap = d.sm;
            final tileWidth = (width - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final a in actions)
                  SizedBox(
                    width: tileWidth,
                    child: () {
                      final tile = _QuickActionTile(
                        action: a,
                        onReturn: onReturn,
                      );
                      final targetId = _guideTargetFor(a.id);
                      return targetId == null
                          ? tile
                          : GuideTarget(id: targetId, child: tile);
                    }(),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

final class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, this.onReturn});

  final AppQuickAction action;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = context.density;
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: Material(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(borderRadius: d.radiusLgBorder),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await context.push<Object?>(action.route);
            onReturn?.call();
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: d.quickActionMinHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: d.isCompact ? d.sm : d.md,
                vertical: d.isCompact ? d.xs : d.md,
              ),
              child: Row(
                children: [
                  Icon(
                    action.icon,
                    size: d.iconMd,
                    color: scheme.onSecondaryContainer,
                  ),
                  SizedBox(width: d.isCompact ? d.xs : d.sm),
                  Expanded(
                    child: Text(
                      action.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (d.isCompact
                                  ? Theme.of(context).textTheme.labelMedium
                                  : Theme.of(context).textTheme.labelLarge)
                              ?.copyWith(
                                color: scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
