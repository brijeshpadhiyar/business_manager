import 'package:business_manager/features/guidance/presentation/bloc/guide_cubit.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_state.dart';
import 'package:business_manager/features/guidance/presentation/widgets/guide_action_coach_banner.dart';
import 'package:business_manager/features/guidance/presentation/widgets/guide_spotlight_overlay.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Root host mounted inside [BusinessManagerApp] (below [AppLockGate]) that:
/// 1. Synchronizes GoRouter route changes with [GuideCubit].
/// 2. Automatically navigates to each step's screen when advancing through the
///    9-chapter End-to-End Training Journey.
/// 3. Renders [GuideSpotlightOverlay] or [GuideActionCoachBanner] above all
///    routes and persistent navigation bars.
final class GuideSpotlightHost extends StatefulWidget {
  const GuideSpotlightHost({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<GuideSpotlightHost> createState() => _GuideSpotlightHostState();
}

final class _GuideSpotlightHostState extends State<GuideSpotlightHost> {
  String _lastSyncedRoute = '/';

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRouterChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRouterChanged());
  }

  @override
  void didUpdateWidget(covariant GuideSpotlightHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_onRouterChanged);
      widget.router.routerDelegate.addListener(_onRouterChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) => _onRouterChanged());
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouterChanged);
    super.dispose();
  }

  void _onRouterChanged() {
    if (!mounted) return;
    final cubit = context.read<GuideCubit?>();
    if (cubit == null) return;
    final path = widget.router.routeInformationProvider.value.uri.path;
    if (path != _lastSyncedRoute) {
      _lastSyncedRoute = path;
      cubit.updateRouteLocation(path);
    }
  }

  void _navigateIfNeededForStep(GuideState state) {
    final step = state.currentStep;
    if (step == null) return;
    final currentPath = widget.router.routeInformationProvider.value.uri.path;
    if (currentPath == step.routePath) return;

    // Only auto-navigate when starting/moving in End-to-End Journey or when
    // launching a specific screen tour from the User Guide Hub.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final latestPath = widget.router.routeInformationProvider.value.uri.path;
      if (latestPath != step.routePath) {
        widget.router.go(step.routePath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final guideCubit = context.read<GuideCubit?>();
    if (guideCubit == null) return widget.child;

    return BlocConsumer<GuideCubit, GuideState>(
      listenWhen: (prev, curr) =>
          prev.currentStep?.id != curr.currentStep?.id ||
          (prev.mode != curr.mode && curr.isActive),
      listener: (context, state) {
        if (state.isActive) {
          _navigateIfNeededForStep(state);
        }
      },
      builder: (context, state) {
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (state.showSpotlightOverlay) GuideSpotlightOverlay(state: state),
            if (state.showActionCoachBanner)
              GuideActionCoachBanner(state: state),
          ],
        );
      },
    );
  }
}
