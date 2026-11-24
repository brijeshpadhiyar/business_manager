/// Centralized component dimension tokens (dp).
abstract final class AppSizing {
  static const double inputHeight = 48;
  static const double buttonHeight = 44;
  static const double appBarHeight = 56;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double touchTargetMin = 48;

  /// Standardized content width tiers.
  static const double narrowContentWidth = 840;
  static const double standardContentWidth = 1160;
  static const double wideContentWidth = 1480;

  /// Backward-compatible default content width alias.
  static const double maxContentWidth = standardContentWidth;

  static const double maxDialogWidth = 540;
  static const double desktopSidebarWidth = 256;
}
