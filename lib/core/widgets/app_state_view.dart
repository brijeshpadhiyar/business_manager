import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/widgets/app_empty_state.dart';
import 'package:business_manager/core/widgets/app_error_view.dart';
import 'package:business_manager/core/widgets/app_skeleton.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// The phase of a screen's data, used by [AppStateView].
enum AppViewPhase { loading, error, empty, ready }

/// One place that decides what a data screen shows: a skeleton while loading,
/// an error with retry, a helpful empty state, or the content.
///
/// Using this on every page gives users the same loading feel everywhere
/// (skeletons, not spinners) and a gentle cross-fade between phases.
final class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.phase,
    required this.builder,
    this.loading,
    this.errorTitle,
    this.errorMessage,
    this.retryLabel,
    this.onRetry,
    this.emptyIcon = AppIcons.empty,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final AppViewPhase phase;
  final WidgetBuilder builder;

  /// Custom loading placeholder; defaults to [AppSkeletonList].
  final Widget? loading;

  final String? errorTitle;
  final String? errorMessage;
  final String? retryLabel;
  final VoidCallback? onRetry;

  final IconData emptyIcon;
  final String? emptyTitle;
  final String? emptySubtitle;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  Widget _child(BuildContext context) {
    return switch (phase) {
      AppViewPhase.loading => loading ?? const AppSkeletonList(),
      AppViewPhase.error => AppErrorView(
        title: errorTitle ?? '',
        message: errorMessage,
        retryLabel: retryLabel,
        onRetry: onRetry,
      ),
      AppViewPhase.empty => AppEmptyState(
        icon: emptyIcon,
        title: emptyTitle ?? '',
        subtitle: emptySubtitle,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      ),
      AppViewPhase.ready => builder(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.fast),
      switchInCurve: AppMotion.standardCurve,
      child: KeyedSubtree(key: ValueKey(phase), child: _child(context)),
    );
  }
}
