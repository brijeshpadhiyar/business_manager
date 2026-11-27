import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps screens on the shared design system: buttons, chips, dividers, list
/// tiles, progress bars, dialogs, sheets, pickers and dropdowns must come
/// from the `App*` widgets in `lib/core/widgets/`, never raw Flutter widgets.
///
/// Also keeps the third-party picker packages behind their core wrappers, so
/// they can be swapped or upgraded in one place.
void main() {
  /// Raw widget (or show* helper) name → the shared widget to use instead.
  const rawWidgets = <String, String>{
    'ElevatedButton': 'AppButton',
    'FilledButton': 'AppButton',
    'TextButton': 'AppButton(variant: AppButtonVariant.text)',
    'OutlinedButton': 'AppButton(variant: AppButtonVariant.outlined)',
    'IconButton': 'AppIconButton',
    'Chip': 'AppChip',
    'FilterChip': 'AppChip / AppChipGroup',
    'ChoiceChip': 'AppChip / AppChipGroup',
    'ActionChip': 'AppChip',
    'InputChip': 'AppChip',
    'Divider': 'AppDivider',
    'VerticalDivider': 'AppDivider',
    'ListTile': 'AppListTile',
    'CheckboxListTile': 'AppCheckbox',
    'Checkbox': 'AppCheckbox',
    'LinearProgressIndicator': 'AppProgressBar',
    'CircularProgressIndicator': 'AppSpinner',
    'AlertDialog': 'AppDialog',
    'DropdownButton': 'AppSelect',
    'DropdownButtonFormField': 'AppSelect',
    'DropdownMenu': 'AppSelect',
    'showDialog': 'AppDialog.showCustom / showConfirmation',
    'showModalBottomSheet': 'AppBottomSheet',
    'showDatePicker': 'AppDateTimeDialogs.pickDate',
    'showDateRangePicker': 'AppDateTimeDialogs.pickRange',
    'showTimePicker': 'AppDateTimeDialogs.pickTime',
  };

  /// Files allowed to use raw widgets, with the reason. Keep this short.
  const allowedFiles = <String, String>{
    // The toast is drawn inside toastification's overlay with small
    // (still 48dp hit-area) controls that the shared buttons do not offer.
    'lib/core/services/app_message_service.dart': 'toast overlay',
  };

  const pickerPackages = ['dropdown_search', 'calendar_date_picker2'];

  Iterable<(String, List<String>)> dartFiles() sync* {
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.contains('/generated/') || path.endsWith('.g.dart')) continue;
      yield (path, entity.readAsLinesSync());
    }
  }

  bool isComment(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith('//') || trimmed.startsWith('*');
  }

  test('no raw Flutter widgets outside lib/core/widgets', () {
    // `Foo(`, `Foo.icon(`, `Foo<T>(`; not `AppFoo(` or `fooBar.Foo(`.
    final pattern = RegExp(
      r'(?<![A-Za-z0-9_.])(' +
          rawWidgets.keys.join('|') +
          r')(\.[a-z][A-Za-z]*)?(<[^>()]*>)?\(',
    );
    final offenders = <String>[];
    for (final (path, lines) in dartFiles()) {
      if (path.startsWith('lib/core/widgets/')) continue;
      if (allowedFiles.containsKey(path)) continue;
      for (var i = 0; i < lines.length; i++) {
        if (isComment(lines[i])) continue;
        for (final match in pattern.allMatches(lines[i])) {
          // `FilledButton.styleFrom(...)` builds a theme style, not a widget.
          if (match.group(2) == '.styleFrom') continue;
          final name = match.group(1)!;
          offenders.add('$path:${i + 1}  $name → ${rawWidgets[name]}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use the shared App* widgets from lib/core/widgets/ instead:\n'
          '${offenders.join('\n')}',
    );
  });

  test('picker packages are imported only by their core wrappers', () {
    final offenders = <String>[];
    for (final (path, lines) in dartFiles()) {
      if (path.startsWith('lib/core/widgets/selection/') ||
          path.startsWith('lib/core/widgets/date_time/')) {
        continue;
      }
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.trimLeft().startsWith('import ')) continue;
        if (pickerPackages.any((p) => line.contains('package:$p/'))) {
          offenders.add('$path:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use AppSelect / AppMultiSelect / AppDateTimeDialogs instead of '
          'importing the picker packages directly:\n${offenders.join('\n')}',
    );
  });

  test('allowlisted files still exist', () {
    for (final path in allowedFiles.keys) {
      expect(File(path).existsSync(), isTrue, reason: '$path was removed');
    }
  });
}
