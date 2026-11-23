import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
  ];

  /// Default English display name of the application.
  ///
  /// In en, this message translates to:
  /// **'Business Manager'**
  String get appTitle;

  /// Development flavor display name of the application.
  ///
  /// In en, this message translates to:
  /// **'Business Manager Dev'**
  String get appTitleDev;

  /// Heading on the foundation status section.
  ///
  /// In en, this message translates to:
  /// **'Project Foundation Ready'**
  String get foundationTitle;

  /// Subtitle on the foundation status section.
  ///
  /// In en, this message translates to:
  /// **'Offline-first architecture, flavors, Material 3 design system, and bilingual localization are configured.'**
  String get foundationSubtitle;

  /// Section heading for flavor and environment metadata.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environmentSectionTitle;

  /// Label for active flavor name.
  ///
  /// In en, this message translates to:
  /// **'Flavor'**
  String get environmentFlavorLabel;

  /// Human-readable label for the dev flavor.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get environmentFlavorDev;

  /// Human-readable label for the prod flavor.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get environmentFlavorProd;

  /// Label for configured local SQLite database filename.
  ///
  /// In en, this message translates to:
  /// **'Database File'**
  String get environmentDatabaseLabel;

  /// Label for debug logging status.
  ///
  /// In en, this message translates to:
  /// **'Debug Logging'**
  String get environmentLoggingLabel;

  /// Generic enabled status label.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get statusEnabled;

  /// Generic disabled status label.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get statusDisabled;

  /// Section heading for language selector.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// Option to follow device system language.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystemDefault;

  /// Option to select English language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Option to select Gujarati language.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી (Gujarati)'**
  String get languageGujarati;

  /// Section heading for theme mode selector.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSectionTitle;

  /// Option to follow system theme mode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Option to select light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Option to select dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Common save button label.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Common cancel button label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Common confirm button label.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// Common retry button label.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Generic fallback error message.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorUnexpected;

  /// Showcase navigation tab for overview and settings.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// Showcase navigation tab for form inputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get navInputs;

  /// Showcase navigation tab for badges, dialogs, states, and tables.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get navFeedback;

  /// Heading for button variants preview.
  ///
  /// In en, this message translates to:
  /// **'Buttons & Actions'**
  String get showcaseButtonsHeading;

  /// Label for primary button preview.
  ///
  /// In en, this message translates to:
  /// **'Primary Action'**
  String get showcasePrimaryAction;

  /// Label for secondary button preview.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get showcaseSecondaryAction;

  /// Label for outlined button preview.
  ///
  /// In en, this message translates to:
  /// **'Outlined'**
  String get showcaseOutlinedAction;

  /// Label for destructive button preview.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get showcaseDestructiveAction;

  /// Label for loading button preview.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get showcaseLoadingAction;

  /// Label for disabled button preview.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get showcaseDisabledAction;

  /// Heading for form inputs preview.
  ///
  /// In en, this message translates to:
  /// **'Form Controls'**
  String get showcaseInputsHeading;

  /// Sample text field label in design system showcase.
  ///
  /// In en, this message translates to:
  /// **'Reference Name'**
  String get showcaseSampleFieldLabel;

  /// Sample text field hint in design system showcase.
  ///
  /// In en, this message translates to:
  /// **'Enter a sample value'**
  String get showcaseSampleFieldHint;

  /// Validation message when a required field is empty.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get validationRequired;

  /// Sample dropdown label in showcase.
  ///
  /// In en, this message translates to:
  /// **'Sample Category'**
  String get showcaseDropdownLabel;

  /// Sample option 1.
  ///
  /// In en, this message translates to:
  /// **'Option One'**
  String get showcaseOptionOne;

  /// Sample option 2.
  ///
  /// In en, this message translates to:
  /// **'Option Two'**
  String get showcaseOptionTwo;

  /// Sample date picker label.
  ///
  /// In en, this message translates to:
  /// **'Business Date (IST)'**
  String get showcaseDatePickerLabel;

  /// Sample checkbox label.
  ///
  /// In en, this message translates to:
  /// **'Mark as verified'**
  String get showcaseCheckboxLabel;

  /// Sample switch label.
  ///
  /// In en, this message translates to:
  /// **'Enable compact preview'**
  String get showcaseSwitchLabel;

  /// Button to trigger sample form validation.
  ///
  /// In en, this message translates to:
  /// **'Validate Form'**
  String get showcaseValidateButton;

  /// Heading for semantic status badges.
  ///
  /// In en, this message translates to:
  /// **'Status Badges'**
  String get showcaseBadgesHeading;

  /// Semantic badge label for good stock.
  ///
  /// In en, this message translates to:
  /// **'Good Stock'**
  String get statusGood;

  /// Semantic badge label for pending items.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Semantic badge label for damaged items.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get statusDamaged;

  /// Semantic badge label for advance credit.
  ///
  /// In en, this message translates to:
  /// **'Advance Credit'**
  String get statusAdvanceCredit;

  /// Button label to preview AppDialog.
  ///
  /// In en, this message translates to:
  /// **'Open Dialog'**
  String get showcaseOpenDialog;

  /// Button label to preview AppBottomSheet.
  ///
  /// In en, this message translates to:
  /// **'Open Adaptive Sheet'**
  String get showcaseOpenSheet;

  /// Title of preview dialog.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get showcaseDialogTitle;

  /// Body text of preview dialog.
  ///
  /// In en, this message translates to:
  /// **'This preview verifies consistent Material 3 spacing, typography, and bilingual wrapping.'**
  String get showcaseDialogMessage;

  /// Heading for typography and long text wrapping verification.
  ///
  /// In en, this message translates to:
  /// **'Typography & Long Text Sample'**
  String get showcaseLongTextHeading;

  /// Long paragraph sample to verify English and Gujarati wrapping.
  ///
  /// In en, this message translates to:
  /// **'All design tokens, typography weights, and bilingual labels wrap cleanly across compact Android phones, tablets, and desktop layouts without clipping or overflow.'**
  String get showcaseLongTextSample;

  /// Heading for AppDataTable preview.
  ///
  /// In en, this message translates to:
  /// **'Responsive Data Table'**
  String get showcaseTableHeading;

  /// Sample table column 1.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get showcaseColName;

  /// Sample table column 2.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get showcaseColQty;

  /// Sample table column 3.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get showcaseColAmount;

  /// Preview title for AppEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No Records Yet'**
  String get showcaseEmptyTitle;

  /// Preview subtitle for AppEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Items will appear here once added.'**
  String get showcaseEmptySubtitle;

  /// Preview title for AppErrorView.
  ///
  /// In en, this message translates to:
  /// **'Unable to Load Preview'**
  String get showcaseErrorTitle;

  /// Preview message for AppLoader.
  ///
  /// In en, this message translates to:
  /// **'Loading preview...'**
  String get showcaseLoadingMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
