/// Android-first responsive layout breakpoints (dp).
enum AppWindowSizeClass {
  compact, // < 600dp (Mobile portrait)
  medium, // 600..1023dp (Tablet / foldable)
  expanded; // >= 1024dp (Desktop / wide Web)

  bool get isCompact => this == AppWindowSizeClass.compact;
  bool get isMedium => this == AppWindowSizeClass.medium;
  bool get isExpanded => this == AppWindowSizeClass.expanded;
}

abstract final class AppBreakpoints {
  static const double tabletMinWidth = 600;
  static const double desktopMinWidth = 1024;

  static AppWindowSizeClass fromWidth(double width) {
    if (width >= desktopMinWidth) return AppWindowSizeClass.expanded;
    if (width >= tabletMinWidth) return AppWindowSizeClass.medium;
    return AppWindowSizeClass.compact;
  }
}
