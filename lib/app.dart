import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/app_scroll_behavior.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/app_session_controller.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/router/app_router.dart';
import 'package:business_manager/core/services/app_message_service.dart';
import 'package:business_manager/core/theme/density_cubit.dart';
import 'package:business_manager/core/theme/navigation_sidebar_cubit.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_cubit.dart';
import 'package:business_manager/features/guidance/presentation/widgets/guide_spotlight_host.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/widgets/app_lock_gate.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:business_manager/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:business_manager/features/sync/presentation/widgets/first_login_merge_dialog.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

final class BusinessManagerApp extends StatefulWidget {
  const BusinessManagerApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<BusinessManagerApp> createState() => _BusinessManagerAppState();
}

final class _BusinessManagerAppState extends State<BusinessManagerApp>
    with WidgetsBindingObserver {
  late GoRouter _router;
  bool _mergeDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = createAppRouter(widget.config);
    AppSessionController.instance.addListener(_onSessionReloaded);
    final lockCubit = getIt<AppLockCubit>();
    if (lockCubit.state.status == AppLockStatus.initializing) {
      lockCubit.initialize();
    }
    if (getIt.isRegistered<GuideCubit>()) {
      getIt<GuideCubit>().initialize();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && getIt.isRegistered<SyncCubit>()) {
      getIt<SyncCubit>().onAppResumed();
    }
  }

  void _onSessionReloaded() {
    if (!mounted) return;
    final oldRouter = _router;
    setState(() {
      _router = createAppRouter(widget.config);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => oldRouter.dispose());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppMessageService.cancelPendingTimers();
    AppSessionController.instance.removeListener(_onSessionReloaded);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionGen = AppSessionController.instance.generation;
    return KeyedSubtree(
      key: ValueKey<int>(sessionGen),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LocaleCubit>.value(value: getIt<LocaleCubit>()),
          BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
          BlocProvider<DensityCubit>.value(value: getIt<DensityCubit>()),
          if (getIt.isRegistered<NavigationSidebarCubit>())
            BlocProvider<NavigationSidebarCubit>.value(
              value: getIt<NavigationSidebarCubit>(),
            ),
          BlocProvider<AppLockCubit>.value(value: getIt<AppLockCubit>()),
          BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
          BlocProvider<SyncCubit>.value(value: getIt<SyncCubit>()),
          if (getIt.isRegistered<GuideCubit>())
            BlocProvider<GuideCubit>.value(value: getIt<GuideCubit>()),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthCubit, AuthState>(
              listenWhen: (prev, curr) => prev.user?.id != curr.user?.id,
              listener: (context, authState) {
                context.read<AppLockCubit>().syncAccountScope(
                  authState.user?.id,
                );
              },
            ),
            BlocListener<SyncCubit, SyncState>(
              listenWhen: (prev, curr) =>
                  prev.phase != curr.phase &&
                  curr.phase == SyncPhase.awaitingMergeChoice &&
                  curr.pendingMergeSummary != null,
              listener: (context, syncState) async {
                if (_mergeDialogOpen) return;
                final navCtx =
                    _router.routerDelegate.navigatorKey.currentContext;
                if (navCtx == null || !navCtx.mounted) return;
                _mergeDialogOpen = true;
                try {
                  final choice = await FirstLoginMergeDialog.show(
                    navCtx,
                    syncState.pendingMergeSummary!,
                  );
                  if (choice != null && mounted) {
                    await getIt<SyncCubit>().resolveFirstLoginMerge(choice);
                  }
                } finally {
                  _mergeDialogOpen = false;
                }
              },
            ),
          ],
          child: BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeState) {
                  return BlocBuilder<DensityCubit, DensityState>(
                    builder: (context, densityState) {
                      final vd = densityState.mode.visualDensity;
                      return MaterialApp.router(
                        debugShowCheckedModeBanner: widget.config.isDev,
                        onGenerateTitle: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          return widget.config.isDev
                              ? l10n.appTitleDev
                              : l10n.appTitle;
                        },
                        locale: localeState.preference.locale,
                        supportedLocales: AppLocalizations.supportedLocales,
                        localizationsDelegates: const [
                          AppLocalizations.delegate,
                          ...GlobalMaterialLocalizations.delegates,
                        ],
                        themeMode: themeState.preference.themeMode,
                        theme: AppTheme.light(
                          visualDensity: vd,
                          surfaceStyle: themeState.surfaceStyle,
                          preset: themeState.preset,
                        ),
                        darkTheme: AppTheme.dark(
                          visualDensity: vd,
                          surfaceStyle: themeState.surfaceStyle,
                          preset: themeState.preset,
                        ),
                        themeAnimationDuration: const Duration(
                          milliseconds: 240,
                        ),
                        themeAnimationCurve: Curves.easeOutCubic,
                        routerConfig: _router,
                        scrollBehavior: const AppScrollBehavior(),
                        // Respect the phone's font-size setting, but cap it so very
                        // large system fonts cannot break tables and forms.
                        // In Compact ERP mode, clamp a little tighter so high-density
                        // screens preserve maximum row visibility.
                        builder: (context, child) {
                          final isCompact =
                              densityState.mode == UiDensityMode.compact;
                          return MediaQuery.withClampedTextScaling(
                            minScaleFactor: isCompact ? 0.9 : 1.0,
                            maxScaleFactor: isCompact ? 1.25 : 1.5,
                            child: ToastificationWrapper(
                              child: AppLockGate(
                                onNavigateDeepLink: (routePath) =>
                                    _router.push(routePath),
                                child: GuideSpotlightHost(
                                  router: _router,
                                  child: child ?? const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
