import 'dart:ui';

import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/app_breadcrumb_bar.dart';
import 'package:business_manager/core/widgets/app_button.dart';
import 'package:business_manager/core/widgets/app_collapsible_header.dart';
import 'package:business_manager/core/widgets/app_glass_backdrop.dart';
import 'package:business_manager/core/widgets/responsive_navigation.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Centralized scroll & header presentation modes for [AppScaffold].
enum AppScrollMode {
  /// Fixed glass AppBar (`56dp`) + standard body. Best for forms, settings,
  /// security, and focused data-entry screens.
  standard,

  /// Adaptive sliver-based collapsible header (`SliverAppBar` + optional
  /// summary strip + optional pinned search/filter bar + lazy slivers).
  /// Adapts automatically across Mobile (`< 600dp`), Tablet (`600–1023dp`),
  /// and Desktop (`>= 1024dp`).
  collapsible,

  /// Minimal compact glass toolbar (`48dp`) with maximum working space and no
  /// expanded header animation.
  compact,
}

/// A page's main action, such as "Create lot".
///
/// [AppScaffold] shows it as a floating action button on compact screens
/// (phones, narrow windows) where it sits under the thumb and never crowds the
/// toolbar, and as a labelled toolbar button on tablet and desktop.
final class AppPrimaryAction {
  const AppPrimaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.guideTargetId,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? guideTargetId;
}

/// Centralized StitchFlow adaptive page scaffold supporting:
/// - [AppScrollMode.standard] (default, 100% backward-compatible)
/// - [AppScrollMode.collapsible] (native `CustomScrollView` + `SliverAppBar` +
///   collapsible summary strip + pinned search/filter header)
/// - [AppScrollMode.compact] (minimal toolbar, maximum workspace)
/// - [AppContentWidth] tiers (`narrow: 840dp`, `standard: 1160dp`,
///   `wide: 1480dp`, `fluid`)
/// - Automatic [ResponsiveShellScope] detection so nested routes inside the
///   persistent Desktop/Tablet shell never paint duplicate [AppGlassBackdrop]s.
final class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.scrollMode = AppScrollMode.standard,
    this.embedded = false,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.body,
    this.header,
    this.pinnedHeader,
    this.pinnedHeaderHeight = 112,
    this.slivers,
    this.scrollController,
    this.onRefresh,
    this.collapseOnDesktop = false,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding,
    this.constrainMaxWidth = true,
    this.contentWidth = AppContentWidth.standard,
    this.breadcrumbs,
    this.primaryAction,
    this.bottomAction,
  }) : assert(
         scrollMode == AppScrollMode.collapsible
             ? (slivers != null || body != null)
             : body != null,
         'Provide body (for standard/compact) or slivers/body (for collapsible).',
       );

  final AppScrollMode scrollMode;
  final bool embedded;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? body;
  final AppCollapsibleHeader? header;
  final Widget? pinnedHeader;
  final double pinnedHeaderHeight;
  final List<Widget>? slivers;
  final ScrollController? scrollController;
  final Future<void> Function()? onRefresh;
  final bool collapseOnDesktop;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry? padding;
  final bool constrainMaxWidth;
  final AppContentWidth contentWidth;
  final List<AppBreadcrumbItem>? breadcrumbs;

  /// The page's main action: FAB on compact, toolbar button elsewhere.
  final AppPrimaryAction? primaryAction;

  /// Save / Confirm area pinned to the bottom of the screen (above the
  /// keyboard and home indicator), so long forms never hide their main button.
  final Widget? bottomAction;

  double effectiveMaxWidth(BuildContext context) => constrainMaxWidth
      ? contentWidth.effectiveMaxWidth(isCompact: context.isCompactDensity)
      : double.infinity;

  static bool _isCompact(BuildContext context) =>
      AppBreakpoints.fromWidth(MediaQuery.sizeOf(context).width).isCompact;

  /// Toolbar actions plus [primaryAction] on tablet/desktop.
  List<Widget>? actionsFor(BuildContext context, List<Widget>? base) {
    final action = primaryAction;
    if (action == null || _isCompact(context)) return base;
    final d = context.density;
    Widget toolbarBtn = AppButton(
      label: action.label,
      icon: action.icon,
      onPressed: action.onPressed,
    );
    if (action.guideTargetId != null) {
      toolbarBtn = GuideTarget(id: action.guideTargetId!, child: toolbarBtn);
    }
    return [
      ...?base,
      Padding(
        padding: EdgeInsets.symmetric(horizontal: d.xs),
        child: Center(child: toolbarBtn),
      ),
    ];
  }

  /// Explicit FAB, or [primaryAction] as a FAB on compact screens.
  Widget? fabFor(BuildContext context) {
    if (floatingActionButton != null) return floatingActionButton;
    final action = primaryAction;
    if (action == null || !_isCompact(context)) return null;
    final d = context.density;
    Widget fab = FloatingActionButton.extended(
      heroTag: null,
      onPressed: action.onPressed,
      materialTapTargetSize: d.isCompact
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
      extendedPadding: d.isCompact
          ? EdgeInsets.symmetric(horizontal: d.md, vertical: d.xs)
          : null,
      icon: Icon(action.icon, size: d.iconMd),
      label: Text(action.label),
    );
    if (action.guideTargetId != null) {
      fab = GuideTarget(id: action.guideTargetId!, child: fab);
    }
    return fab;
  }

  /// [bottomAction] as a pinned bar, else the plain bottom bar.
  Widget? bottomBarFor(BuildContext context) {
    final action = bottomAction;
    if (action == null) return bottomNavigationBar;
    return AppStickyActionBar(child: action);
  }

  /// [leading], or a Home button when a compact page was opened directly
  /// (deep link, browser refresh, bookmark) and has nothing to go back to.
  Widget? leadingFor(BuildContext context, Widget? base) {
    if (base != null || embedded) return base;
    final shell = ResponsiveShellScope.maybeOf(context);
    if (shell == null || shell.hasPersistentChrome) return null;
    final route = ModalRoute.of(context);
    if (route == null || route.impliesAppBarDismissal) return null;
    final router = GoRouter.maybeOf(context);
    if (router == null) return null;
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const Icon(AppIcons.home),
      onPressed: () => router.go(RoutePaths.home),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget layout = switch (scrollMode) {
      AppScrollMode.standard => _StandardScaffoldLayout(config: this),
      AppScrollMode.collapsible => _CollapsibleScaffoldLayout(config: this),
      AppScrollMode.compact => _CompactScaffoldLayout(config: this),
    };
    // Embedded pages (root tabs inside the navigation shell) have no Scaffold
    // of their own, so the compact FAB floats over the content instead.
    if (embedded && primaryAction != null && _isCompact(context)) {
      final d = context.density;
      return Stack(
        children: [
          Positioned.fill(child: layout),
          Positioned(
            right: d.lg,
            bottom: d.lg,
            child: fabFor(context)!,
          ),
        ],
      );
    }
    return layout;
  }
}

/// Always paints an opaque canvas behind non-embedded routes so native
/// [MaterialPage] transitions (Android predictive back, iOS swipe-back,
/// Desktop FadeForwards) never let the previous page bleed through and snap
/// away at transition end. [AppGlassBackdrop] is a static `RepaintBoundary`
/// gradient with zero blur cost.
Widget _wrapWithBackdropIfNeeded(BuildContext context, Widget child) {
  return AppGlassBackdrop(child: child);
}

PreferredSizeWidget _buildGlassAppBar(
  BuildContext context, {
  required double toolbarHeight,
  String? title,
  Widget? titleWidget,
  Widget? leading,
  List<Widget>? actions,
}) {
  final tokens = context.surfaceTokens;
  return AppBar(
    toolbarHeight: toolbarHeight,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: leading,
    title: titleWidget ?? (title != null ? Text(title) : null),
    actions: actions,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        enabled: false, // v1.4 soft elevation: opaque surfaces
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.navGlassFill,
            border: Border(
              bottom: BorderSide(color: tokens.navGlassBorder, width: 0.9),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _StandardScaffoldLayout extends StatelessWidget {
  const _StandardScaffoldLayout({required this.config});

  final AppScaffold config;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    Widget content = config.body ?? const SizedBox.shrink();
    if (config.breadcrumbs != null && config.breadcrumbs!.isNotEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBreadcrumbBar(items: config.breadcrumbs!),
          SizedBox(height: d.xs),
          Expanded(child: content),
        ],
      );
    }
    final resolvedPadding = config.padding ?? d.screenAll;
    if (resolvedPadding != EdgeInsets.zero) {
      content = Padding(padding: resolvedPadding, child: content);
    }
    final maxW = config.effectiveMaxWidth(context);
    if (maxW.isFinite) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: content,
        ),
      );
    }

    if (config.embedded) {
      return content;
    }

    final showAppBar =
        config.title != null ||
        config.titleWidget != null ||
        config.actions != null ||
        config.primaryAction != null;

    return _wrapWithBackdropIfNeeded(
      context,
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: showAppBar
            ? _buildGlassAppBar(
                context,
                toolbarHeight: d.appBarHeight,
                title: config.title,
                titleWidget: config.titleWidget,
                leading: config.leadingFor(context, config.leading),
                actions: config.actionsFor(context, config.actions),
              )
            : null,
        body: SafeArea(bottom: config.bottomAction == null, child: content),
        floatingActionButton: config.fabFor(context),
        bottomNavigationBar: config.bottomBarFor(context),
      ),
    );
  }
}

final class _CompactScaffoldLayout extends StatelessWidget {
  const _CompactScaffoldLayout({required this.config});

  final AppScaffold config;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    Widget content = config.body ?? const SizedBox.shrink();
    final resolvedPadding = config.padding ?? d.screenAll;
    if (resolvedPadding != EdgeInsets.zero) {
      content = Padding(padding: resolvedPadding, child: content);
    }
    final maxW = config.effectiveMaxWidth(context);
    if (maxW.isFinite) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: content,
        ),
      );
    }

    if (config.embedded) {
      return content;
    }

    final showAppBar =
        config.title != null ||
        config.titleWidget != null ||
        config.actions != null ||
        config.primaryAction != null;

    return _wrapWithBackdropIfNeeded(
      context,
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: showAppBar
            ? _buildGlassAppBar(
                context,
                toolbarHeight: d.compactAppBarHeight,
                title: config.title,
                titleWidget: config.titleWidget,
                leading: config.leadingFor(context, config.leading),
                actions: config.actionsFor(context, config.actions),
              )
            : null,
        body: SafeArea(bottom: config.bottomAction == null, child: content),
        floatingActionButton: config.fabFor(context),
        bottomNavigationBar: config.bottomBarFor(context),
      ),
    );
  }
}

final class _CollapsibleScaffoldLayout extends StatefulWidget {
  const _CollapsibleScaffoldLayout({required this.config});

  final AppScaffold config;

  @override
  State<_CollapsibleScaffoldLayout> createState() =>
      _CollapsibleScaffoldLayoutState();
}

final class _CollapsibleScaffoldLayoutState
    extends State<_CollapsibleScaffoldLayout> {
  final BackdropKey _chromeBackdropKey = BackdropKey();

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final d = context.density;
    final shell = ResponsiveShellScope.maybeOf(context);
    final inPersistentShell = shell != null && shell.hasPersistentChrome;
    final baseHdr =
        config.header ??
        AppCollapsibleHeader(
          title: config.title ?? '',
          leading: config.leading,
          actions: config.actions,
        );
    // Short landscape phones: let the header scroll away so content has room.
    final shortScreen = MediaQuery.sizeOf(context).height < 480;
    final hdr = baseHdr.copyWith(
      leading: config.leadingFor(context, baseHdr.leading),
      actions: config.actionsFor(context, baseHdr.actions),
      pinned: shortScreen ? false : baseHdr.pinned,
    );

    final scrollBody = BackdropGroup(
      backdropKey: _chromeBackdropKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final sizeClass = AppBreakpoints.fromWidth(width);
          final useDesktopCompact =
              sizeClass.isExpanded && !config.collapseOnDesktop;

          final scaledExpanded =
              hdr.expandedHeight * d.collapsibleExpandedScale;
          final effectiveExpandedHeight = switch (sizeClass) {
            AppWindowSizeClass.compact => scaledExpanded,
            AppWindowSizeClass.medium => (scaledExpanded * 0.88).clamp(
              d.isCompact ? 96.0 : 132.0,
              d.isCompact ? 150.0 : 210.0,
            ),
            AppWindowSizeClass.expanded =>
              config.collapseOnDesktop
                  ? (scaledExpanded * 0.82).clamp(
                      d.isCompact ? 92.0 : 124.0,
                      d.isCompact ? 140.0 : 190.0,
                    )
                  : d.appBarHeight,
          };

          final maxW = config.effectiveMaxWidth(context);
          final horizontalInset = maxW.isFinite && width > maxW
              ? (width - maxW) / 2
              : 0.0;

          final effectivePinnedHeight =
              config.pinnedHeaderHeight * d.pinnedHeaderScale;

          final allSlivers = <Widget>[
            if (!useDesktopCompact)
              hdr.buildSliver(
                context,
                primary: !config.embedded && !inPersistentShell,
                effectiveExpandedHeight: effectiveExpandedHeight,
                backdropKey: _chromeBackdropKey,
              )
            else ...[
              // Desktop compact header preserving maximum workspace
              SliverAppBar(
                primary: !config.embedded && !inPersistentShell,
                pinned: hdr.pinned,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                toolbarHeight: d.appBarHeight,
                leading: hdr.leading,
                automaticallyImplyLeading: hdr.automaticallyImplyLeading,
                title: Text(
                  hdr.title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                actions: hdr.actions,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    enabled: false, // v1.4 soft elevation: opaque surfaces
                    backdropGroupKey: _chromeBackdropKey,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.surfaceTokens.navGlassFill,
                        border: Border(
                          bottom: BorderSide(
                            color: context.surfaceTokens.navGlassBorder,
                            width: 0.9,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (hdr.summary != null)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset + d.lg,
                    d.md,
                    horizontalInset + d.lg,
                    d.xs,
                  ),
                  sliver: SliverToBoxAdapter(child: hdr.summary),
                ),
            ],
            if (config.pinnedHeader != null)
              SliverPersistentHeader(
                pinned: !shortScreen,
                delegate: AppPinnedSliverHeader(
                  height: effectivePinnedHeight,
                  backdropKey: _chromeBackdropKey,
                  child: config.pinnedHeader!,
                ),
              ),
            if (config.slivers != null)
              for (final s in config.slivers!)
                horizontalInset > 0
                    ? SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalInset,
                        ),
                        sliver: s,
                      )
                    : s
            else if (config.body != null)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                sliver: SliverToBoxAdapter(child: config.body!),
              ),
          ];

          // Leave room so the floating action button never hides the last row.
          if (config.primaryAction != null && AppScaffold._isCompact(context)) {
            allSlivers.add(
              SliverToBoxAdapter(child: SizedBox(height: d.isCompact ? 64 : 88)),
            );
          }

          Widget scrollView = CustomScrollView(
            controller: config.scrollController,
            slivers: allSlivers,
          );

          if (config.onRefresh != null) {
            scrollView = RefreshIndicator(
              onRefresh: config.onRefresh!,
              child: scrollView,
            );
          }

          return scrollView;
        },
      ),
    );

    if (config.embedded) {
      return scrollBody;
    }

    return _wrapWithBackdropIfNeeded(
      context,
      Scaffold(
        backgroundColor: Colors.transparent,
        // Keep content clear of the home indicator and landscape notches.
        body: SafeArea(
          top: false,
          bottom: config.bottomAction == null,
          child: scrollBody,
        ),
        floatingActionButton: config.fabFor(context),
        bottomNavigationBar: config.bottomBarFor(context),
      ),
    );
  }
}

/// Bottom bar that pins a page's Save / Confirm action. It sits above the
/// keyboard when typing and clear of the home indicator otherwise.
final class AppStickyActionBar extends StatelessWidget {
  const AppStickyActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;
    final d = context.density;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        enabled: false, // v1.4 soft elevation: opaque surfaces
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.navGlassFill,
            border: Border(
              top: BorderSide(color: tokens.navGlassBorder, width: 0.9),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(d.lg, d.sm, d.lg, d.sm),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppContentWidth.narrow.effectiveMaxWidth(
                      isCompact: d.isCompact,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
