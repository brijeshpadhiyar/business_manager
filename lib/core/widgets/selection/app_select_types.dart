/// Async page loader for [AppSelect] / [AppMultiSelect].
///
/// Called with the current search [query] (already debounced), the number of
/// rows to skip ([offset]) and the page size ([limit]). Return at most [limit]
/// items; returning fewer tells the popup that there are no more pages.
///
/// Back it with a repository/DAO search (`LIKE ? LIMIT ? OFFSET ?`) so large
/// lists (workers, lots, processes) never load fully into memory.
typedef AppSelectLoader<T> = Future<List<T>> Function(
  String query,
  int offset,
  int limit,
);

/// How the option list opens.
enum AppSelectPresentation {
  /// Bottom sheet on compact (phone) widths, anchored menu on tablet/desktop.
  auto,

  /// Anchored menu under the field.
  menu,

  /// Modal bottom sheet.
  bottomSheet,

  /// Centered dialog.
  dialog,
}
