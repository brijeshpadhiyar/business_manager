import 'package:business_manager/core/design_system/app_density.dart';
import 'package:material_ui/material_ui.dart';

/// Adaptive responsive layout breakpoints (dp).
enum AppWindowSizeClass {
  compact, // < 600dp (Mobile portrait)
  medium, // 600..1023dp (Tablet / foldable)
  expanded; // >= 1024dp (Desktop / wide Web)

  bool get isCompact => this == AppWindowSizeClass.compact;
  bool get isMedium => this == AppWindowSizeClass.medium;
  bool get isExpanded => this == AppWindowSizeClass.expanded;
}

/// Standardized content max-width tiers across Mobile, Tablet, Desktop & Web.
enum AppContentWidth {
  /// Focused forms, settings, security, and confirmation workflows (`840dp`).
  narrow(840),

  /// Detail screens, timelines, and single-entity workspaces (`1160dp`).
  standard(1160),

  /// Dashboards, operational lists, ledgers, history, and reports (`1480dp`).
  wide(1480),

  /// Full available viewport width (no max width cap).
  fluid(double.infinity);

  const AppContentWidth(this.maxWidth);

  final double maxWidth;

  /// Returns widened content cap when [isCompact] ERP density is enabled so
  /// wide screens pack more columns and rows without artificial margins.
  double effectiveMaxWidth({required bool isCompact}) {
    if (!isCompact) return maxWidth;
    return switch (this) {
      AppContentWidth.narrow => 1040,
      AppContentWidth.standard => 1400,
      AppContentWidth.wide => double.infinity,
      AppContentWidth.fluid => double.infinity,
    };
  }
}

abstract final class AppBreakpoints {
  static const double tabletMinWidth = 600;
  static const double desktopMinWidth = 1024;
  static const double largeDesktopMinWidth = 1440;

  static AppWindowSizeClass fromWidth(double width) {
    if (width >= desktopMinWidth) return AppWindowSizeClass.expanded;
    if (width >= tabletMinWidth) return AppWindowSizeClass.medium;
    return AppWindowSizeClass.compact;
  }

  /// Constraint-aware adaptive page padding that scales smoothly from 360dp
  /// phones up to 1920dp desktop displays, tightened in compact density mode.
  static EdgeInsets pagePaddingForWidth(
    double width, {
    AppDensityTokens? density,
  }) {
    final d = density ?? AppDensityTokens.comfortable;
    if (d.isCompact) {
      return EdgeInsets.all(d.lg);
    }
    if (width >= desktopMinWidth) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    if (width >= tabletMinWidth) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
    return const EdgeInsets.all(16);
  }

  /// Responsive column count helper driven by available layout width.
  static int gridColumns(
    double width, {
    int compact = 1,
    int medium = 2,
    int expanded = 3,
    int? largeExpanded,
  }) {
    if (largeExpanded != null && width >= largeDesktopMinWidth) {
      return largeExpanded;
    }
    if (width >= desktopMinWidth) return expanded;
    if (width >= tabletMinWidth) return medium;
    return compact;
  }

  /// Density-aware grid column count helper adding extra columns in Compact mode.
  static int denseGridColumns(
    BuildContext context,
    double width, {
    int compact = 2,
    int medium = 3,
    int expanded = 4,
    int? largeExpanded,
  }) {
    final isCompact = context.isCompactDensity;
    if (largeExpanded != null && width >= largeDesktopMinWidth) {
      return largeExpanded + (isCompact ? 2 : 0);
    }
    if (width >= desktopMinWidth) return expanded + (isCompact ? 2 : 0);
    if (width >= tabletMinWidth) return medium + (isCompact ? 1 : 0);
    return compact + (isCompact ? 1 : 0);
  }
}
