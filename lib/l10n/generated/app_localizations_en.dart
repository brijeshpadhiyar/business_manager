// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Business Manager';

  @override
  String get appTitleDev => 'Business Manager Dev';

  @override
  String get foundationTitle => 'Project Foundation Ready';

  @override
  String get foundationSubtitle =>
      'Offline-first architecture, flavors, and bilingual localization are configured.';

  @override
  String get environmentSectionTitle => 'Environment';

  @override
  String get environmentFlavorLabel => 'Flavor';

  @override
  String get environmentFlavorDev => 'Development';

  @override
  String get environmentFlavorProd => 'Production';

  @override
  String get environmentDatabaseLabel => 'Database File';

  @override
  String get environmentLoggingLabel => 'Debug Logging';

  @override
  String get statusEnabled => 'Enabled';

  @override
  String get statusDisabled => 'Disabled';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSystemDefault => 'System Default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGujarati => 'ગુજરાતી (Gujarati)';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get errorUnexpected =>
      'An unexpected error occurred. Please try again.';
}
