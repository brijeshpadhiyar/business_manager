import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/app_dialog.dart';
import 'package:business_manager/core/widgets/app_form_dirty_tracker.dart';
import 'package:material_ui/material_ui.dart';

/// Stops the user from losing form input by accident.
///
/// While [hasChanges] is true, a back gesture, the system back button or a
/// `Navigator.maybePop` shows a "Discard changes?" dialog. A direct
/// `Navigator.pop` / `context.pop` after a successful save is not blocked.
final class AppUnsavedChangesGuard extends StatelessWidget {
  const AppUnsavedChangesGuard({
    super.key,
    required this.hasChanges,
    required this.child,
  }) : tracker = null;

  /// Guards the page using an [AppFormDirtyTracker]; it rebuilds only this
  /// small wrapper when the dirty state flips, not the whole form.
  const AppUnsavedChangesGuard.tracked({
    super.key,
    required AppFormDirtyTracker this.tracker,
    required this.child,
  }) : hasChanges = false;

  final bool hasChanges;
  final AppFormDirtyTracker? tracker;
  final Widget child;

  /// Shows the discard dialog. Returns true when the user chose to discard.
  static Future<bool> confirmDiscard(BuildContext context) async {
    final l10n = context.l10n;
    final result = await AppDialog.showConfirmation(
      context,
      title: l10n.uxUnsavedTitle,
      message: l10n.uxUnsavedMessage,
      confirmLabel: l10n.uxUnsavedDiscard,
      cancelLabel: l10n.uxUnsavedKeepEditing,
      isDestructive: true,
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final tracker = this.tracker;
    if (tracker != null) {
      return ListenableBuilder(
        listenable: tracker,
        child: child,
        builder: (context, child) => _scope(context, tracker.isDirty, child!),
      );
    }
    return _scope(context, hasChanges, child);
  }

  Widget _scope(BuildContext context, bool hasChanges, Widget child) {
    return PopScope<Object?>(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await confirmDiscard(context);
        if (discard && navigator.mounted) {
          navigator.pop(result);
        }
      },
      child: child,
    );
  }
}
