import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/features/notifications/data/services/notification_refresh_coordinator.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/pages/app_lock_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Root widget wrapping `MaterialApp.router`'s `builder`.
///
/// Guarantees:
/// - Zero flash of Dashboard or sensitive routes while initializing or locked.
/// - Immediate opaque StitchFlow Privacy Shield on `inactive` / `hidden` / `paused`.
/// - Foreground inactivity reset on pointer events.
/// - Safe deferred deep-link delivery only after successful unlock.
final class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
    required this.onNavigateDeepLink,
  });

  final Widget child;
  final ValueChanged<String> onNavigateDeepLink;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

final class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  late final AppLockCubit _lockCubit;

  @override
  void initState() {
    super.initState();
    _lockCubit = context.read<AppLockCubit>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockCubit.pauseTimersOnUnmount();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<AppLockCubit>();
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        cubit.onAppInactiveOrHidden();
      case AppLifecycleState.paused:
        cubit.onAppPaused();
      case AppLifecycleState.resumed:
        cubit.onAppResumed();
        NotificationRefreshCoordinator.requestBackgroundRefreshIfRegistered();
      case AppLifecycleState.detached:
        break;
    }
  }

  void _flushPendingDeepLinkIfUnlocked(AppLockState state) {
    if (state.pendingDeepLinkRoute == null) return;
    if (state.status == AppLockStatus.unlocked ||
        state.status == AppLockStatus.disabled) {
      final route = context.read<AppLockCubit>().consumePendingDeepLinkRoute();
      if (route != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onNavigateDeepLink(route);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppLockCubit, AppLockState>(
      listener: (context, state) => _flushPendingDeepLinkIfUnlocked(state),
      builder: (context, state) {
        final showLock = state.status == AppLockStatus.locked;
        final showInitializing = state.status == AppLockStatus.initializing;
        final showShield = state.showPrivacyShield && !showLock;

        // While locked or initializing, do NOT even expose the child tree to
        // rendering/focus so Dashboard/ledger widgets never render before auth.
        if (showInitializing) {
          return const _PrivacyShieldOverlay(showProgress: true);
        }

        if (showLock) {
          // Dedicated Navigator provides Overlay + ScaffoldMessenger for
          // Tooltip, SelectableText, and recovery flows above the app router.
          return Navigator(
            key: const ValueKey<String>('stitchflow_lock_navigator'),
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => const AppLockScreen()),
          );
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) =>
              context.read<AppLockCubit>().recordUserActivity(),
          onPointerMove: (_) =>
              context.read<AppLockCubit>().recordUserActivity(),
          child: Stack(
            children: [
              widget.child,
              if (showShield)
                const Positioned.fill(child: _PrivacyShieldOverlay()),
            ],
          ),
        );
      },
    );
  }
}

final class _PrivacyShieldOverlay extends StatelessWidget {
  const _PrivacyShieldOverlay({this.showProgress = false});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.indigo950,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: context.themePresetPalette.heroGradientDark,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.onHero.withValues(alpha: 0.14),
                  borderRadius: AppRadius.xlBorder,
                  border: Border.all(
                    color: AppColors.onHero.withValues(alpha: 0.25),
                  ),
                ),
                child: Image.asset(
                  AppIdentity.symbolPngAsset,
                  cacheWidth: 192,
                  cacheHeight: 192,
                  errorBuilder: (_, _, _) => const Icon(
                    AppIcons.shield,
                    color: AppColors.onHero,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppIdentity.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onHero,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showProgress) ...[
                const SizedBox(height: AppSpacing.md),
                AppSpinner(
                  size: 20,
                  color: AppColors.onHero.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
