import 'package:business_manager/core/design_system/app_density.dart';
import 'package:material_ui/material_ui.dart';

/// Round initials avatar for people (workers, team members).
///
/// The tint comes from a stable hash of [name], so the same person always
/// gets the same colour, which helps users scan long lists. Colours are taken
/// from the theme's container roles, so it works in light and dark mode.
/// Decorative for screen readers: the name is always shown next to it.
final class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size,
    this.dimmed = false,
  });

  final String name;
  final double? size;

  /// Greys the avatar out, e.g. for an inactive worker.
  final bool dimmed;

  /// Up to two initials: first letters of the first and last words.
  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    String first(String w) => String.fromCharCode(w.runes.first);
    if (words.length == 1) return first(words.first).toUpperCase();
    return (first(words.first) + first(words.last)).toUpperCase();
  }

  // String.hashCode can differ between runs and platforms; this does not.
  static int _stableHash(String name) => name
      .trim()
      .toLowerCase()
      .codeUnits
      .fold(0, (h, c) => (h * 31 + c) & 0x7fffffff);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = context.density;
    final resolvedSize = size ?? d.avatarSize;
    final palette = <(Color, Color)>[
      (scheme.primaryContainer, scheme.onPrimaryContainer),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    ];
    final (bg, fg) = dimmed
        ? (scheme.surfaceContainerHighest, scheme.onSurfaceVariant)
        : palette[_stableHash(name) % palette.length];

    return ExcludeSemantics(
      child: Container(
        width: resolvedSize,
        height: resolvedSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(
          initialsOf(name),
          maxLines: 1,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
