import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension L10nBuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  AppLocalizations? get l10nOrNull => AppLocalizations.of(this);
}
