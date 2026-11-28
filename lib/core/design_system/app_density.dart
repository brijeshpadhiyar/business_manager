import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// Density-aware design tokens injected via [ThemeData.extensions].
///
/// Use `context.density` across `lib/core/widgets/` and feature screens so
/// switching between [UiDensityMode.comfortable] and [UiDensityMode.compact]
/// scales spacing, component heights, radii, table rows, and grid density
/// consistently across the entire app.
@immutable
final class AppDensityTokens extends ThemeExtension<AppDensityTokens> {
  const AppDensityTokens({
    required this.isCompact,
    required this.xxs,
    required this.xs,
    required this.xsm,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.buttonVertical,
    required this.buttonHorizontal,
    required this.inputVertical,
    required this.inputHorizontal,
    required this.chipHorizontal,
    required this.chipVertical,
    required this.segmentHorizontal,
    required this.segmentVertical,
    required this.cardHorizontal,
    required this.cardVertical,
    required this.dialogPadding,
    required this.sheetPadding,
    required this.inputHeight,
    required this.buttonHeight,
    required this.appBarHeight,
    required this.compactAppBarHeight,
    required this.navBarHeight,
    required this.desktopSidebarWidth,
    required this.navigationRailWidth,
    required this.touchTargetMin,
    required this.quickActionMinHeight,
    required this.avatarSize,
    required this.metricIconBoxSize,
    required this.iconSm,
    required this.iconMd,
    required this.iconLg,
    required this.iconXl,
    required this.iconHero,
    required this.tableHeadingHeight,
    required this.tableRowMinHeight,
    required this.tableRowMaxHeight,
    required this.tableHorizontalMargin,
    required this.tableColumnSpacingExpanded,
    required this.tableColumnSpacingMedium,
    required this.tableDefaultPageSize,
    required this.tablePageSizeOptions,
    required this.collapsibleExpandedScale,
    required this.pinnedHeaderScale,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
  });

  static const AppDensityTokens comfortable = AppDensityTokens(
    isCompact: false,
    xxs: 2,
    xs: 4,
    xsm: 6,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    buttonVertical: 10,
    buttonHorizontal: 14,
    inputVertical: 14,
    inputHorizontal: 14,
    chipHorizontal: 10,
    chipVertical: 6,
    segmentHorizontal: 10,
    segmentVertical: 8,
    cardHorizontal: 12,
    cardVertical: 12,
    dialogPadding: 24,
    sheetPadding: 16,
    inputHeight: 48,
    buttonHeight: 44,
    appBarHeight: 56,
    compactAppBarHeight: 48,
    navBarHeight: 62,
    desktopSidebarWidth: 220,
    navigationRailWidth: 60,
    touchTargetMin: 48,
    quickActionMinHeight: 72,
    avatarSize: 40,
    metricIconBoxSize: 34,
    iconSm: 16,
    iconMd: 20,
    iconLg: 24,
    iconXl: 32,
    iconHero: 48,
    tableHeadingHeight: 46,
    tableRowMinHeight: 48,
    tableRowMaxHeight: 62,
    tableHorizontalMargin: 24,
    tableColumnSpacingExpanded: 24,
    tableColumnSpacingMedium: 12,
    tableDefaultPageSize: 25,
    tablePageSizeOptions: [10, 25, 50],
    collapsibleExpandedScale: 1.0,
    pinnedHeaderScale: 1.0,
    radiusSm: 6,
    radiusMd: 10,
    radiusLg: 14,
    radiusXl: 18,
  );

  static const AppDensityTokens compact = AppDensityTokens(
    isCompact: true,
    xxs: 1,
    xs: 2,
    xsm: 3,
    sm: 4,
    md: 6,
    lg: 8,
    xl: 12,
    buttonVertical: 5,
    buttonHorizontal: 10,
    inputVertical: 8,
    inputHorizontal: 10,
    chipHorizontal: 6,
    chipVertical: 2,
    segmentHorizontal: 8,
    segmentVertical: 4,
    cardHorizontal: 8,
    cardVertical: 6,
    dialogPadding: 12,
    sheetPadding: 10,
    inputHeight: 36,
    buttonHeight: 34,
    appBarHeight: 42,
    compactAppBarHeight: 38,
    navBarHeight: 50,
    desktopSidebarWidth: 192,
    navigationRailWidth: 52,
    touchTargetMin: 34,
    quickActionMinHeight: 44,
    avatarSize: 28,
    metricIconBoxSize: 24,
    iconSm: 14,
    iconMd: 16,
    iconLg: 20,
    iconXl: 24,
    iconHero: 34,
    tableHeadingHeight: 32,
    tableRowMinHeight: 32,
    tableRowMaxHeight: 42,
    tableHorizontalMargin: 10,
    tableColumnSpacingExpanded: 12,
    tableColumnSpacingMedium: 8,
    tableDefaultPageSize: 50,
    tablePageSizeOptions: [25, 50, 100],
    collapsibleExpandedScale: 0.68,
    pinnedHeaderScale: 0.76,
    radiusSm: 4,
    radiusMd: 6,
    radiusLg: 8,
    radiusXl: 10,
  );

  final bool isCompact;
  final double xxs;
  final double xs;
  final double xsm;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  final double buttonVertical;
  final double buttonHorizontal;
  final double inputVertical;
  final double inputHorizontal;
  final double chipHorizontal;
  final double chipVertical;
  final double segmentHorizontal;
  final double segmentVertical;
  final double cardHorizontal;
  final double cardVertical;
  final double dialogPadding;
  final double sheetPadding;

  final double inputHeight;
  final double buttonHeight;
  final double appBarHeight;
  final double compactAppBarHeight;
  final double navBarHeight;
  final double desktopSidebarWidth;
  final double navigationRailWidth;
  final double touchTargetMin;
  final double quickActionMinHeight;
  final double avatarSize;
  final double metricIconBoxSize;

  final double iconSm;
  final double iconMd;
  final double iconLg;
  final double iconXl;
  final double iconHero;

  final double tableHeadingHeight;
  final double tableRowMinHeight;
  final double tableRowMaxHeight;
  final double tableHorizontalMargin;
  final double tableColumnSpacingExpanded;
  final double tableColumnSpacingMedium;
  final int tableDefaultPageSize;
  final List<int> tablePageSizeOptions;

  final double collapsibleExpandedScale;
  final double pinnedHeaderScale;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;

  EdgeInsets get screenAll => EdgeInsets.all(lg);
  EdgeInsets get screenHorizontal => EdgeInsets.symmetric(horizontal: lg);
  EdgeInsets get cardPadding =>
      EdgeInsets.symmetric(horizontal: cardHorizontal, vertical: cardVertical);
  EdgeInsets get chipPadding =>
      EdgeInsets.symmetric(horizontal: chipHorizontal, vertical: chipVertical);
  EdgeInsets get segmentPadding => EdgeInsets.symmetric(
    horizontal: segmentHorizontal,
    vertical: segmentVertical,
  );
  EdgeInsets get buttonPadding => EdgeInsets.symmetric(
    horizontal: buttonHorizontal,
    vertical: buttonVertical,
  );

  BorderRadius get radiusSmBorder => BorderRadius.all(Radius.circular(radiusSm));
  BorderRadius get radiusMdBorder => BorderRadius.all(Radius.circular(radiusMd));
  BorderRadius get radiusLgBorder => BorderRadius.all(Radius.circular(radiusLg));
  BorderRadius get radiusXlBorder => BorderRadius.all(Radius.circular(radiusXl));

  @override
  AppDensityTokens copyWith({bool? isCompact}) {
    if (isCompact == null || isCompact == this.isCompact) return this;
    return isCompact ? compact : comfortable;
  }

  @override
  AppDensityTokens lerp(covariant AppDensityTokens? other, double t) {
    if (other == null) return this;
    return AppDensityTokens(
      isCompact: t < 0.5 ? isCompact : other.isCompact,
      xxs: lerpDouble(xxs, other.xxs, t)!,
      xs: lerpDouble(xs, other.xs, t)!,
      xsm: lerpDouble(xsm, other.xsm, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      buttonVertical: lerpDouble(buttonVertical, other.buttonVertical, t)!,
      buttonHorizontal: lerpDouble(buttonHorizontal, other.buttonHorizontal, t)!,
      inputVertical: lerpDouble(inputVertical, other.inputVertical, t)!,
      inputHorizontal: lerpDouble(inputHorizontal, other.inputHorizontal, t)!,
      chipHorizontal: lerpDouble(chipHorizontal, other.chipHorizontal, t)!,
      chipVertical: lerpDouble(chipVertical, other.chipVertical, t)!,
      segmentHorizontal: lerpDouble(
        segmentHorizontal,
        other.segmentHorizontal,
        t,
      )!,
      segmentVertical: lerpDouble(segmentVertical, other.segmentVertical, t)!,
      cardHorizontal: lerpDouble(cardHorizontal, other.cardHorizontal, t)!,
      cardVertical: lerpDouble(cardVertical, other.cardVertical, t)!,
      dialogPadding: lerpDouble(dialogPadding, other.dialogPadding, t)!,
      sheetPadding: lerpDouble(sheetPadding, other.sheetPadding, t)!,
      inputHeight: lerpDouble(inputHeight, other.inputHeight, t)!,
      buttonHeight: lerpDouble(buttonHeight, other.buttonHeight, t)!,
      appBarHeight: lerpDouble(appBarHeight, other.appBarHeight, t)!,
      compactAppBarHeight: lerpDouble(
        compactAppBarHeight,
        other.compactAppBarHeight,
        t,
      )!,
      navBarHeight: lerpDouble(navBarHeight, other.navBarHeight, t)!,
      desktopSidebarWidth: lerpDouble(
        desktopSidebarWidth,
        other.desktopSidebarWidth,
        t,
      )!,
      navigationRailWidth: lerpDouble(
        navigationRailWidth,
        other.navigationRailWidth,
        t,
      )!,
      touchTargetMin: lerpDouble(touchTargetMin, other.touchTargetMin, t)!,
      quickActionMinHeight: lerpDouble(
        quickActionMinHeight,
        other.quickActionMinHeight,
        t,
      )!,
      avatarSize: lerpDouble(avatarSize, other.avatarSize, t)!,
      metricIconBoxSize: lerpDouble(
        metricIconBoxSize,
        other.metricIconBoxSize,
        t,
      )!,
      iconSm: lerpDouble(iconSm, other.iconSm, t)!,
      iconMd: lerpDouble(iconMd, other.iconMd, t)!,
      iconLg: lerpDouble(iconLg, other.iconLg, t)!,
      iconXl: lerpDouble(iconXl, other.iconXl, t)!,
      iconHero: lerpDouble(iconHero, other.iconHero, t)!,
      tableHeadingHeight: lerpDouble(
        tableHeadingHeight,
        other.tableHeadingHeight,
        t,
      )!,
      tableRowMinHeight: lerpDouble(
        tableRowMinHeight,
        other.tableRowMinHeight,
        t,
      )!,
      tableRowMaxHeight: lerpDouble(
        tableRowMaxHeight,
        other.tableRowMaxHeight,
        t,
      )!,
      tableHorizontalMargin: lerpDouble(
        tableHorizontalMargin,
        other.tableHorizontalMargin,
        t,
      )!,
      tableColumnSpacingExpanded: lerpDouble(
        tableColumnSpacingExpanded,
        other.tableColumnSpacingExpanded,
        t,
      )!,
      tableColumnSpacingMedium: lerpDouble(
        tableColumnSpacingMedium,
        other.tableColumnSpacingMedium,
        t,
      )!,
      tableDefaultPageSize:
          t < 0.5 ? tableDefaultPageSize : other.tableDefaultPageSize,
      tablePageSizeOptions:
          t < 0.5 ? tablePageSizeOptions : other.tablePageSizeOptions,
      collapsibleExpandedScale: lerpDouble(
        collapsibleExpandedScale,
        other.collapsibleExpandedScale,
        t,
      )!,
      pinnedHeaderScale: lerpDouble(
        pinnedHeaderScale,
        other.pinnedHeaderScale,
        t,
      )!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t)!,
    );
  }
}

extension AppDensityBuildContext on BuildContext {
  AppDensityTokens get density =>
      Theme.of(this).extension<AppDensityTokens>() ??
      AppDensityTokens.comfortable;

  bool get isCompactDensity => density.isCompact;
}
