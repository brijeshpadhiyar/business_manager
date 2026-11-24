import 'dart:ui';

import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_collapsible_header.dart';
import 'package:business_manager/core/widgets/app_glass_backdrop.dart';
import 'package:material_ui/material_ui.dart';

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

/// Centralized StitchFlow V1.3 adaptive page scaffold supporting:
/// - [AppScrollMode.standard] (default, 100% backward-compatible)
/// - [AppScrollMode.collapsible] (native `CustomScrollView` + `SliverAppBar` +
///   collapsible summary strip + pinned search/filter header)
/// - [AppScrollMode.compact] (minimal toolbar, maximum workspace)
///
/// Set [embedded] to `true` when rendering inside `ResponsiveNavigation`'s
/// shell `Scaffold` so `AppGlassBackdrop` and `Scaffold` are not duplicated.
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
    this.padding = AppSpacing.screenAll,
    this.constrainMaxWidth = true,
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

  @override
  Widget build(BuildContext context) {
    return switch (scrollMode) {
      AppScrollMode.standard => _StandardScaffoldLayout(config: this),
      AppScrollMode.collapsible => _CollapsibleScaffoldLayout(config: this),
      AppScrollMode.compact => _CompactScaffoldLayout(config: this),
    };
  }
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
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
    Widget content = config.body ?? const SizedBox.shrink();
    if (config.padding != null) {
      content = Padding(padding: config.padding!, child: content);
    }
    if (config.constrainMaxWidth) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizing.maxContentWidth,
          ),
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
        config.actions != null;

    return AppGlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: showAppBar
            ? _buildGlassAppBar(
                context,
                toolbarHeight: AppSizing.appBarHeight,
                title: config.title,
                titleWidget: config.titleWidget,
                leading: config.leading,
                actions: config.actions,
              )
            : null,
        body: SafeArea(child: content),
        floatingActionButton: config.floatingActionButton,
        bottomNavigationBar: config.bottomNavigationBar,
      ),
    );
  }
}

final class _CompactScaffoldLayout extends StatelessWidget {
  const _CompactScaffoldLayout({required this.config});

  final AppScaffold config;

  @override
  Widget build(BuildContext context) {
    Widget content = config.body ?? const SizedBox.shrink();
    if (config.padding != null && config.padding != EdgeInsets.zero) {
      content = Padding(padding: config.padding!, child: content);
    }
    if (config.constrainMaxWidth) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizing.maxContentWidth,
          ),
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
        config.actions != null;

    return AppGlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: showAppBar
            ? _buildGlassAppBar(
                context,
                toolbarHeight: 48,
                title: config.title,
                titleWidget: config.titleWidget,
                leading: config.leading,
                actions: config.actions,
              )
            : null,
        body: SafeArea(child: content),
        floatingActionButton: config.floatingActionButton,
        bottomNavigationBar: config.bottomNavigationBar,
      ),
    );
  }
}

final class _CollapsibleScaffoldLayout extends StatelessWidget {
  const _CollapsibleScaffoldLayout({required this.config});

  final AppScaffold config;

  @override
  Widget build(BuildContext context) {
    final hdr =
        config.header ??
        AppCollapsibleHeader(
          title: config.title ?? '',
          leading: config.leading,
          actions: config.actions,
        );

    final scrollBody = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final sizeClass = AppBreakpoints.fromWidth(width);
        final useDesktopCompact =
            sizeClass.isExpanded && !config.collapseOnDesktop;

        final effectiveExpandedHeight = switch (sizeClass) {
          AppWindowSizeClass.compact => hdr.expandedHeight,
          AppWindowSizeClass.medium => (hdr.expandedHeight * 0.88).clamp(
            132.0,
            210.0,
          ),
          AppWindowSizeClass.expanded =>
            config.collapseOnDesktop
                ? (hdr.expandedHeight * 0.82).clamp(124.0, 190.0)
                : AppSizing.appBarHeight,
        };

        final horizontalInset =
            config.constrainMaxWidth && width > AppSizing.maxContentWidth
            ? (width - AppSizing.maxContentWidth) / 2
            : 0.0;

        final allSlivers = <Widget>[
          if (!useDesktopCompact)
            hdr.buildSliver(
              context,
              primary: !config.embedded,
              effectiveExpandedHeight: effectiveExpandedHeight,
            )
          else ...[
            // Desktop compact header preserving maximum workspace
            SliverAppBar(
              primary: !config.embedded,
              pinned: hdr.pinned,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: AppSizing.appBarHeight,
              leading: hdr.leading,
              automaticallyImplyLeading: hdr.automaticallyImplyLeading,
              title: Text(
                hdr.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              actions: hdr.actions,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                  horizontalInset + AppSpacing.lg,
                  AppSpacing.md,
                  horizontalInset + AppSpacing.lg,
                  AppSpacing.xs,
                ),
                sliver: SliverToBoxAdapter(child: hdr.summary),
              ),
          ],
          if (config.pinnedHeader != null)
            SliverPersistentHeader(
              pinned: true,
              delegate: AppPinnedSliverHeader(
                height: config.pinnedHeaderHeight,
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
    );

    if (config.embedded) {
      return scrollBody;
    }

    return AppGlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: scrollBody,
        floatingActionButton: config.floatingActionButton,
        bottomNavigationBar: config.bottomNavigationBar,
      ),
    );
  }
}
