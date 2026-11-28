import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Utilities for parsing, normalizing, and contrasting textile HEX/RGB colours.
abstract final class AppColourUtils {
  static const Map<String, String> _namedFallbacks = {
    'red': '#DC2626',
    'maroon': '#7F1D1D',
    'navy': '#1E3A8A',
    'navy blue': '#1E3A8A',
    'blue': '#2563EB',
    'royal blue': '#2563EB',
    'sky blue': '#38BDF8',
    'teal': '#0D9488',
    'green': '#16A34A',
    'bottle green': '#14532D',
    'mustard': '#CA8A04',
    'yellow': '#FACC15',
    'orange': '#EA580C',
    'peach': '#FDBA74',
    'pink': '#EC4899',
    'magenta': '#BE185D',
    'purple': '#7C3AED',
    'white': '#FFFFFF',
    'ivory': '#FFFFF0',
    'cream': '#FEF3C7',
    'beige': '#D6C7AE',
    'grey': '#6B7280',
    'gray': '#6B7280',
    'black': '#111827',
  };

  /// Normalizes a HEX input (`dc2626` or `#dc2626`) to `#DC2626`, or `null` if invalid.
  static String? normalizeHex(String? raw) {
    if (raw == null) return null;
    var s = raw.trim().toUpperCase();
    if (s.isEmpty) return null;
    if (!s.startsWith('#')) s = '#$s';
    if (RegExp(r'^#[0-9A-F]{6}$').hasMatch(s)) return s;
    return null;
  }

  /// Resolves a [Color] from [hex], falling back to known textile colour names
  /// so even legacy records without `colourHex` display a realistic swatch.
  static Color resolveColor(String? hex, {String? fallbackName}) {
    final normalized =
        normalizeHex(hex) ??
        _namedFallbacks[fallbackName?.trim().toLowerCase() ?? ''];
    if (normalized != null) {
      final value = int.parse(normalized.substring(1), radix: 16);
      return Color(0xFF000000 | value);
    }
    if (fallbackName != null && fallbackName.trim().isNotEmpty) {
      final hash = fallbackName.toLowerCase().codeUnits.fold<int>(
        0,
        (a, b) => (a * 31 + b) & 0xFFFFFF,
      );
      return HSLColor.fromAHSL(
        1,
        (hash % 360).toDouble(),
        0.55,
        0.48,
      ).toColor();
    }
    return const Color(0xFF64748B);
  }

  /// Returns `#RRGGBB` string for any [Color].
  static String toHex(Color color) {
    final r = (color.r * 255).round().clamp(0, 255);
    final g = (color.g * 255).round().clamp(0, 255);
    final b = (color.b * 255).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  /// Converts RGB (0..255) to `#RRGGBB`.
  static String rgbToHex(int r, int g, int b) {
    return '#${r.clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
            '${g.clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
            '${b.clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  /// Formats a [Color] as `RGB(r, g, b)`.
  static String formatRgb(Color color) {
    final r = (color.r * 255).round().clamp(0, 255);
    final g = (color.g * 255).round().clamp(0, 255);
    final b = (color.b * 255).round().clamp(0, 255);
    return 'RGB($r, $g, $b)';
  }

  /// Returns a crisp high-contrast foreground color (Slate 900 or white) so
  /// white, ivory, cream, yellow, and pastel swatches remain 100% legible.
  static Color contrastForeground(Color bg) {
    return bg.computeLuminance() > 0.56 ? AppColors.slate900 : Colors.white;
  }

  /// Returns a subtle contrast border so very light or very dark swatches
  /// never blend invisibly into Light Glass or Dark Glass cards.
  static Color swatchBorderColor(Color swatch, Brightness brightness) {
    final lum = swatch.computeLuminance();
    if (brightness == Brightness.light) {
      return lum > 0.72
          ? AppColors.slate900.withValues(alpha: 0.28)
          : AppColors.slate900.withValues(alpha: 0.14);
    }
    return lum < 0.12
        ? Colors.white.withValues(alpha: 0.34)
        : Colors.white.withValues(alpha: 0.20);
  }
}

/// High-contrast visual colour swatch with subtle gloss sheen, adaptive border
/// for white/yellow/pastel shades, and optional selected checkmark.
final class AppColourSwatch extends StatelessWidget {
  const AppColourSwatch({
    super.key,
    required this.color,
    this.size,
    this.borderRadius,
    this.isSelected = false,
    this.semanticLabel,
  });

  final Color color;
  final double? size;
  final BorderRadius? borderRadius;
  final bool isSelected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final d = context.density;
    final resolvedSize = size ?? (d.isCompact ? 26.0 : 36.0);
    final resolvedRadius = borderRadius ?? d.radiusMdBorder;
    final fg = AppColourUtils.contrastForeground(color);
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.secondary
        : AppColourUtils.swatchBorderColor(color, brightness);

    return Semantics(
      label: semanticLabel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: resolvedSize,
        height: resolvedSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: resolvedRadius,
          border: Border.all(color: borderColor, width: isSelected ? 2.4 : 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: resolvedRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.22),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: isSelected
              ? Center(
                  child: Icon(
                    AppIcons.confirm,
                    size: resolvedSize * 0.52,
                    color: fg,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
