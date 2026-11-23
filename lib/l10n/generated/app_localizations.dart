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

  /// Official English display name of the application.
  ///
  /// In en, this message translates to:
  /// **'StitchFlow'**
  String get appTitle;

  /// Development flavor display name of the application.
  ///
  /// In en, this message translates to:
  /// **'StitchFlow Dev'**
  String get appTitleDev;

  /// Official StitchFlow brand tagline.
  ///
  /// In en, this message translates to:
  /// **'From Fabric to Finished.'**
  String get appTagline;

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

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navLots.
  ///
  /// In en, this message translates to:
  /// **'Lots'**
  String get navLots;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navBusinessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get navBusinessProfile;

  /// No description provided for @navDesignShowcase.
  ///
  /// In en, this message translates to:
  /// **'Design System Showcase'**
  String get navDesignShowcase;

  /// No description provided for @dashboardWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline-first Garment & Production Management'**
  String get dashboardWelcomeSubtitle;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardPreferences.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get dashboardPreferences;

  /// No description provided for @businessProfileHeading.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfileHeading;

  /// No description provided for @businessProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your workshop details separately from the StitchFlow app name.'**
  String get businessProfileSubtitle;

  /// No description provided for @businessNameEnLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Name (English)'**
  String get businessNameEnLabel;

  /// No description provided for @businessNameGuLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Name (Gujarati)'**
  String get businessNameGuLabel;

  /// No description provided for @businessOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner / Operator Name'**
  String get businessOwnerLabel;

  /// No description provided for @businessPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get businessPhoneLabel;

  /// No description provided for @businessAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Workshop Address'**
  String get businessAddressLabel;

  /// No description provided for @businessDefaultBillingLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Labour Billing Mode'**
  String get businessDefaultBillingLabel;

  /// No description provided for @billingModeReceivedQty.
  ///
  /// In en, this message translates to:
  /// **'Pay on Received Quantity (Default)'**
  String get billingModeReceivedQty;

  /// No description provided for @billingModeGivenQty.
  ///
  /// In en, this message translates to:
  /// **'Pay on Given Quantity'**
  String get billingModeGivenQty;

  /// No description provided for @businessProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Business profile saved.'**
  String get businessProfileSaved;

  /// No description provided for @lotsHeading.
  ///
  /// In en, this message translates to:
  /// **'Lots'**
  String get lotsHeading;

  /// No description provided for @lotsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by lot number, title, or notes'**
  String get lotsSearchHint;

  /// No description provided for @lotsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get lotsFilterAll;

  /// No description provided for @lotsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get lotsStatusActive;

  /// No description provided for @lotsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get lotsStatusCompleted;

  /// No description provided for @lotsStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get lotsStatusArchived;

  /// No description provided for @lotsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Lots Yet'**
  String get lotsEmptyTitle;

  /// No description provided for @lotsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first lot to start tracking designs, colours, and initial quantities.'**
  String get lotsEmptySubtitle;

  /// No description provided for @lotCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New Lot'**
  String get lotCreateAction;

  /// No description provided for @lotEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Lot'**
  String get lotEditAction;

  /// No description provided for @lotArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive Lot'**
  String get lotArchiveAction;

  /// No description provided for @lotArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Lot?'**
  String get lotArchiveConfirmTitle;

  /// No description provided for @lotArchiveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This lot will be archived without deleting historical records.'**
  String get lotArchiveConfirmMessage;

  /// No description provided for @lotNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Lot Number'**
  String get lotNumberLabel;

  /// No description provided for @lotTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title (Optional)'**
  String get lotTitleLabel;

  /// No description provided for @lotNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get lotNotesLabel;

  /// No description provided for @lotDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Lot Date (IST)'**
  String get lotDateLabel;

  /// No description provided for @lotStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get lotStatusLabel;

  /// No description provided for @lotDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'An active lot with this lot number already exists.'**
  String get lotDuplicateError;

  /// No description provided for @lotPhotosHeading.
  ///
  /// In en, this message translates to:
  /// **'Lot Photos'**
  String get lotPhotosHeading;

  /// No description provided for @lotPhotosEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photos attached yet.'**
  String get lotPhotosEmpty;

  /// No description provided for @lotAddPhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get lotAddPhotoCamera;

  /// No description provided for @lotAddPhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get lotAddPhotoGallery;

  /// No description provided for @lotPhotoRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo from the lot?'**
  String get lotPhotoRemoveConfirm;

  /// No description provided for @lotPhotoMissing.
  ///
  /// In en, this message translates to:
  /// **'Photo file is unavailable.'**
  String get lotPhotoMissing;

  /// No description provided for @designsHeading.
  ///
  /// In en, this message translates to:
  /// **'Designs & Colours'**
  String get designsHeading;

  /// No description provided for @designsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter designs or colours'**
  String get designsSearchHint;

  /// No description provided for @designsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Designs Added'**
  String get designsEmptyTitle;

  /// No description provided for @designsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a design to this lot, then add independent colour quantities and prices.'**
  String get designsEmptySubtitle;

  /// No description provided for @designAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add Design'**
  String get designAddAction;

  /// No description provided for @designEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Design'**
  String get designEditAction;

  /// No description provided for @designDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Design?'**
  String get designDeleteConfirmTitle;

  /// No description provided for @designDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This design will be archived from active listings.'**
  String get designDeleteConfirmMessage;

  /// No description provided for @designNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Design Name / Code'**
  String get designNameLabel;

  /// No description provided for @designDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'A design with this name already exists in this lot.'**
  String get designDuplicateError;

  /// No description provided for @colourAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add Colour'**
  String get colourAddAction;

  /// No description provided for @colourEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Colour'**
  String get colourEditAction;

  /// No description provided for @colourDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Colour?'**
  String get colourDeleteConfirmTitle;

  /// No description provided for @colourDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This colour entry will be archived from active listings.'**
  String get colourDeleteConfirmMessage;

  /// No description provided for @colourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Colour Name'**
  String get colourNameLabel;

  /// No description provided for @colourInitialQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial Quantity'**
  String get colourInitialQtyLabel;

  /// No description provided for @colourUnitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per Piece (₹)'**
  String get colourUnitPriceLabel;

  /// No description provided for @colourDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'This colour already exists in this design.'**
  String get colourDuplicateError;

  /// No description provided for @validationPositiveInt.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number greater than 0.'**
  String get validationPositiveInt;

  /// No description provided for @validationValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid non-negative price (e.g. 250 or 250.50).'**
  String get validationValidPrice;

  /// No description provided for @inventoryHeading.
  ///
  /// In en, this message translates to:
  /// **'Initial Inventory Overview'**
  String get inventoryHeading;

  /// No description provided for @inventoryNote.
  ///
  /// In en, this message translates to:
  /// **'Shows recorded Initial Quantities only. Stock movements and pending balances arrive in later milestones.'**
  String get inventoryNote;

  /// No description provided for @inventoryTotalLots.
  ///
  /// In en, this message translates to:
  /// **'Active Lots'**
  String get inventoryTotalLots;

  /// No description provided for @inventoryTotalDesigns.
  ///
  /// In en, this message translates to:
  /// **'Designs'**
  String get inventoryTotalDesigns;

  /// No description provided for @inventoryTotalCombinations.
  ///
  /// In en, this message translates to:
  /// **'Design + Colour'**
  String get inventoryTotalCombinations;

  /// No description provided for @inventoryTotalInitialQty.
  ///
  /// In en, this message translates to:
  /// **'Total Initial Qty'**
  String get inventoryTotalInitialQty;

  /// No description provided for @inventoryTabLots.
  ///
  /// In en, this message translates to:
  /// **'Lot-wise'**
  String get inventoryTabLots;

  /// No description provided for @inventoryTabDesigns.
  ///
  /// In en, this message translates to:
  /// **'Design-wise'**
  String get inventoryTabDesigns;

  /// No description provided for @inventoryTabColours.
  ///
  /// In en, this message translates to:
  /// **'Colour-wise'**
  String get inventoryTabColours;

  /// No description provided for @inventoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Initial Inventory Yet'**
  String get inventoryEmptyTitle;

  /// No description provided for @inventoryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add lots, designs, and colours to see initial quantity totals here.'**
  String get inventoryEmptySubtitle;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionDelete;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @piecesUnit.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get piecesUnit;

  /// No description provided for @navProcesses.
  ///
  /// In en, this message translates to:
  /// **'Processes'**
  String get navProcesses;

  /// No description provided for @navWorkers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get navWorkers;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get filterInactive;

  /// No description provided for @processesHeading.
  ///
  /// In en, this message translates to:
  /// **'Production Processes'**
  String get processesHeading;

  /// No description provided for @processesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search processes by name or description'**
  String get processesSearchHint;

  /// No description provided for @processesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Processes Yet'**
  String get processesEmptyTitle;

  /// No description provided for @processesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your own production processes in any order your workshop uses.'**
  String get processesEmptySubtitle;

  /// No description provided for @processCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New Process'**
  String get processCreateAction;

  /// No description provided for @processEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Process'**
  String get processEditAction;

  /// No description provided for @processDetailsHeading.
  ///
  /// In en, this message translates to:
  /// **'Process Details'**
  String get processDetailsHeading;

  /// No description provided for @processNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Process Name'**
  String get processNameLabel;

  /// No description provided for @processDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get processDescriptionLabel;

  /// No description provided for @processBillingOverrideLabel.
  ///
  /// In en, this message translates to:
  /// **'Labour Billing Mode'**
  String get processBillingOverrideLabel;

  /// No description provided for @processBillingInheritGlobal.
  ///
  /// In en, this message translates to:
  /// **'Use Business Default'**
  String get processBillingInheritGlobal;

  /// No description provided for @processIncludeDamagedLabel.
  ///
  /// In en, this message translates to:
  /// **'Include damaged pieces in labour'**
  String get processIncludeDamagedLabel;

  /// No description provided for @processActivateAction.
  ///
  /// In en, this message translates to:
  /// **'Activate Process'**
  String get processActivateAction;

  /// No description provided for @processDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Process'**
  String get processDeactivateAction;

  /// No description provided for @processDeactivateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Process?'**
  String get processDeactivateConfirmTitle;

  /// No description provided for @processDeactivateConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Historical records remain intact, but new assignments and issues will be blocked while inactive.'**
  String get processDeactivateConfirmMessage;

  /// No description provided for @processDuplicateNameError.
  ///
  /// In en, this message translates to:
  /// **'A process with this name already exists.'**
  String get processDuplicateNameError;

  /// No description provided for @processAssignedWorkersHeading.
  ///
  /// In en, this message translates to:
  /// **'Assigned Workers'**
  String get processAssignedWorkersHeading;

  /// No description provided for @processNoAssignedWorkers.
  ///
  /// In en, this message translates to:
  /// **'No workers are currently assigned to this process.'**
  String get processNoAssignedWorkers;

  /// No description provided for @processAuditHistoryHeading.
  ///
  /// In en, this message translates to:
  /// **'Audit History'**
  String get processAuditHistoryHeading;

  /// No description provided for @processNoAuditHistory.
  ///
  /// In en, this message translates to:
  /// **'No audit entries recorded yet.'**
  String get processNoAuditHistory;

  /// No description provided for @createdAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdAtLabel;

  /// No description provided for @updatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get updatedAtLabel;

  /// No description provided for @workersHeading.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workersHeading;

  /// No description provided for @workersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search workers by name, phone, or address'**
  String get workersSearchHint;

  /// No description provided for @workersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Workers Yet'**
  String get workersEmptyTitle;

  /// No description provided for @workersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your workshop workers to assign processes and configure per-piece rates.'**
  String get workersEmptySubtitle;

  /// No description provided for @workerCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New Worker'**
  String get workerCreateAction;

  /// No description provided for @workerEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Worker'**
  String get workerEditAction;

  /// No description provided for @workerDetailsHeading.
  ///
  /// In en, this message translates to:
  /// **'Worker Profile'**
  String get workerDetailsHeading;

  /// No description provided for @workerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker Name'**
  String get workerNameLabel;

  /// No description provided for @workerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get workerPhoneLabel;

  /// No description provided for @workerAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get workerAddressLabel;

  /// No description provided for @workerNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get workerNotesLabel;

  /// No description provided for @workerActivateAction.
  ///
  /// In en, this message translates to:
  /// **'Activate Worker'**
  String get workerActivateAction;

  /// No description provided for @workerDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Worker'**
  String get workerDeactivateAction;

  /// No description provided for @workerDeactivateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Worker?'**
  String get workerDeactivateConfirmTitle;

  /// No description provided for @workerDeactivateConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Historical records and rates are preserved. Inactive workers cannot receive new assignments.'**
  String get workerDeactivateConfirmMessage;

  /// No description provided for @workerContactHeading.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get workerContactHeading;

  /// No description provided for @workerNoContactInfo.
  ///
  /// In en, this message translates to:
  /// **'No phone or address recorded.'**
  String get workerNoContactInfo;

  /// No description provided for @workerAssignedProcessesHeading.
  ///
  /// In en, this message translates to:
  /// **'Assigned Processes & Current Rates'**
  String get workerAssignedProcessesHeading;

  /// No description provided for @workerNoAssignedProcesses.
  ///
  /// In en, this message translates to:
  /// **'No processes assigned yet.'**
  String get workerNoAssignedProcesses;

  /// No description provided for @workerManageAssignmentsAction.
  ///
  /// In en, this message translates to:
  /// **'Manage Assignments'**
  String get workerManageAssignmentsAction;

  /// No description provided for @workerViewRateHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Rate History'**
  String get workerViewRateHistoryAction;

  /// No description provided for @workerAddRateAction.
  ///
  /// In en, this message translates to:
  /// **'Add Rate'**
  String get workerAddRateAction;

  /// No description provided for @assignmentsHeading.
  ///
  /// In en, this message translates to:
  /// **'Worker Process Assignments'**
  String get assignmentsHeading;

  /// No description provided for @assignmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A worker can be assigned to multiple processes with no fixed sequence.'**
  String get assignmentsSubtitle;

  /// No description provided for @assignmentsAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Active Process'**
  String get assignmentsAddLabel;

  /// No description provided for @assignmentsAddAction.
  ///
  /// In en, this message translates to:
  /// **'Assign Process'**
  String get assignmentsAddAction;

  /// No description provided for @assignmentsRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get assignmentsRemoveAction;

  /// No description provided for @assignmentsRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Assignment?'**
  String get assignmentsRemoveConfirmTitle;

  /// No description provided for @assignmentsRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This deactivates the assignment while preserving historical rate and work records.'**
  String get assignmentsRemoveConfirmMessage;

  /// No description provided for @assignmentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Active Assignments'**
  String get assignmentsEmptyTitle;

  /// No description provided for @assignmentsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign one or more active processes to this worker.'**
  String get assignmentsEmptySubtitle;

  /// No description provided for @assignmentsNoAvailableProcesses.
  ///
  /// In en, this message translates to:
  /// **'All active processes are already assigned or no active processes exist.'**
  String get assignmentsNoAvailableProcesses;

  /// No description provided for @assignmentsDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'This process is already assigned to the worker.'**
  String get assignmentsDuplicateError;

  /// No description provided for @assignmentsInactiveWorkerError.
  ///
  /// In en, this message translates to:
  /// **'Activate this worker before adding process assignments.'**
  String get assignmentsInactiveWorkerError;

  /// No description provided for @assignmentsInactiveProcessError.
  ///
  /// In en, this message translates to:
  /// **'Only active processes can be assigned.'**
  String get assignmentsInactiveProcessError;

  /// No description provided for @ratesHistoryHeading.
  ///
  /// In en, this message translates to:
  /// **'Per-Piece Rate History'**
  String get ratesHistoryHeading;

  /// No description provided for @ratesFilterProcessLabel.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get ratesFilterProcessLabel;

  /// No description provided for @ratesCurrentRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Rate'**
  String get ratesCurrentRateLabel;

  /// No description provided for @ratesNoCurrentRate.
  ///
  /// In en, this message translates to:
  /// **'No current rate'**
  String get ratesNoCurrentRate;

  /// No description provided for @ratesPerPieceSuffix.
  ///
  /// In en, this message translates to:
  /// **'/ pc'**
  String get ratesPerPieceSuffix;

  /// No description provided for @ratesOngoingLabel.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ratesOngoingLabel;

  /// No description provided for @ratesEffectiveFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective From (IST)'**
  String get ratesEffectiveFromLabel;

  /// No description provided for @ratesEffectiveToLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective To (IST, Optional)'**
  String get ratesEffectiveToLabel;

  /// No description provided for @ratesClearEffectiveTo.
  ///
  /// In en, this message translates to:
  /// **'Clear End Date (Ongoing)'**
  String get ratesClearEffectiveTo;

  /// No description provided for @ratesAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate per Piece (₹)'**
  String get ratesAmountLabel;

  /// No description provided for @ratesNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason / Notes (Optional)'**
  String get ratesNotesLabel;

  /// No description provided for @ratesAddHeading.
  ///
  /// In en, this message translates to:
  /// **'Add Historical Rate'**
  String get ratesAddHeading;

  /// No description provided for @ratesEditHeading.
  ///
  /// In en, this message translates to:
  /// **'Edit Rate'**
  String get ratesEditHeading;

  /// No description provided for @ratesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Rates Configured'**
  String get ratesEmptyTitle;

  /// No description provided for @ratesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an effective-dated per-piece rate for this worker and process.'**
  String get ratesEmptySubtitle;

  /// No description provided for @ratesSelectProcessHint.
  ///
  /// In en, this message translates to:
  /// **'Select Process'**
  String get ratesSelectProcessHint;

  /// No description provided for @ratesAutoCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Previous Ongoing Rate?'**
  String get ratesAutoCloseTitle;

  /// No description provided for @ratesAutoCloseMessage.
  ///
  /// In en, this message translates to:
  /// **'An ongoing rate exists for this process. Saving will close it on the previous day and start the new rate from your chosen date.'**
  String get ratesAutoCloseMessage;

  /// No description provided for @ratesOverlapError.
  ///
  /// In en, this message translates to:
  /// **'This date range overlaps with an existing rate.'**
  String get ratesOverlapError;

  /// No description provided for @ratesMultipleOpenEndedError.
  ///
  /// In en, this message translates to:
  /// **'Another ongoing rate already exists for this worker and process.'**
  String get ratesMultipleOpenEndedError;

  /// No description provided for @ratesToBeforeFromError.
  ///
  /// In en, this message translates to:
  /// **'Effective To date cannot be earlier than Effective From date.'**
  String get ratesToBeforeFromError;

  /// No description provided for @ratesLockedByHistoryError.
  ///
  /// In en, this message translates to:
  /// **'This rate is already used in historical transactions and cannot be edited.'**
  String get ratesLockedByHistoryError;

  /// No description provided for @ratesHistoricalNotice.
  ///
  /// In en, this message translates to:
  /// **'Historical rates are preserved. To change a rate, add a new effective-dated entry.'**
  String get ratesHistoricalNotice;

  /// No description provided for @navStockMovements.
  ///
  /// In en, this message translates to:
  /// **'Stock Movements'**
  String get navStockMovements;

  /// No description provided for @navAccounting.
  ///
  /// In en, this message translates to:
  /// **'Labour & Payments'**
  String get navAccounting;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get navBackupRestore;

  /// No description provided for @stockHeading.
  ///
  /// In en, this message translates to:
  /// **'Stock Movements'**
  String get stockHeading;

  /// No description provided for @stockIssueAction.
  ///
  /// In en, this message translates to:
  /// **'Issue Stock'**
  String get stockIssueAction;

  /// No description provided for @stockReturnAction.
  ///
  /// In en, this message translates to:
  /// **'Receive Return'**
  String get stockReturnAction;

  /// No description provided for @stockRepairAction.
  ///
  /// In en, this message translates to:
  /// **'Repair Damaged'**
  String get stockRepairAction;

  /// No description provided for @stockTabOpenIssues.
  ///
  /// In en, this message translates to:
  /// **'Pending Issues'**
  String get stockTabOpenIssues;

  /// No description provided for @stockTabBalances.
  ///
  /// In en, this message translates to:
  /// **'Live Stock'**
  String get stockTabBalances;

  /// No description provided for @stockTabHistory.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get stockTabHistory;

  /// No description provided for @stockTabWorkers.
  ///
  /// In en, this message translates to:
  /// **'By Worker'**
  String get stockTabWorkers;

  /// No description provided for @stockTabProcesses.
  ///
  /// In en, this message translates to:
  /// **'By Process'**
  String get stockTabProcesses;

  /// No description provided for @stockAvailableGoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Good'**
  String get stockAvailableGoodLabel;

  /// No description provided for @stockPendingWorkerLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending w/ Workers'**
  String get stockPendingWorkerLabel;

  /// No description provided for @stockDamagedBucketLabel.
  ///
  /// In en, this message translates to:
  /// **'Damaged Stock'**
  String get stockDamagedBucketLabel;

  /// No description provided for @stockLostLabel.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get stockLostLabel;

  /// No description provided for @stockShortageLabel.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get stockShortageLabel;

  /// No description provided for @stockIssuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get stockIssuedLabel;

  /// No description provided for @stockGoodReturnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Good Returned'**
  String get stockGoodReturnedLabel;

  /// No description provided for @stockRemainingPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining Pending'**
  String get stockRemainingPendingLabel;

  /// No description provided for @stockSelectLotLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Lot'**
  String get stockSelectLotLabel;

  /// No description provided for @stockSelectDesignLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Design'**
  String get stockSelectDesignLabel;

  /// No description provided for @stockSelectColourLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Colour'**
  String get stockSelectColourLabel;

  /// No description provided for @stockSelectProcessLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Process'**
  String get stockSelectProcessLabel;

  /// No description provided for @stockSelectWorkerLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Eligible Worker'**
  String get stockSelectWorkerLabel;

  /// No description provided for @stockIssueQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue Quantity (pcs)'**
  String get stockIssueQuantityLabel;

  /// No description provided for @stockTransactionDateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date & Time (IST)'**
  String get stockTransactionDateTimeLabel;

  /// No description provided for @stockResolvedRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked Per-Piece Rate'**
  String get stockResolvedRateLabel;

  /// No description provided for @stockRateMissingWarning.
  ///
  /// In en, this message translates to:
  /// **'No effective historical rate exists for this worker and process on the chosen IST date.'**
  String get stockRateMissingWarning;

  /// No description provided for @stockRateConflictWarning.
  ///
  /// In en, this message translates to:
  /// **'Conflicting overlapping rates exist on this date.'**
  String get stockRateConflictWarning;

  /// No description provided for @stockRateOverrideToggle.
  ///
  /// In en, this message translates to:
  /// **'Manual Rate Override (Audited)'**
  String get stockRateOverrideToggle;

  /// No description provided for @stockOverrideRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Override Rate (₹ / pc)'**
  String get stockOverrideRateLabel;

  /// No description provided for @stockOverrideReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Override Reason (Required)'**
  String get stockOverrideReasonLabel;

  /// No description provided for @stockNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get stockNotesLabel;

  /// No description provided for @stockIssueSuccess.
  ///
  /// In en, this message translates to:
  /// **'Stock issued successfully.'**
  String get stockIssueSuccess;

  /// No description provided for @stockNoEligibleWorkers.
  ///
  /// In en, this message translates to:
  /// **'No active workers are assigned to this process.'**
  String get stockNoEligibleWorkers;

  /// No description provided for @stockInsufficientGoodError.
  ///
  /// In en, this message translates to:
  /// **'Cannot issue more than available good stock.'**
  String get stockInsufficientGoodError;

  /// No description provided for @stockInvalidQtyError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive piece quantity.'**
  String get stockInvalidQtyError;

  /// No description provided for @stockSettlementHeading.
  ///
  /// In en, this message translates to:
  /// **'Receive Return / Settlement'**
  String get stockSettlementHeading;

  /// No description provided for @stockGoodReturnQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Good Returned (pcs)'**
  String get stockGoodReturnQtyLabel;

  /// No description provided for @stockDamagedReturnQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Damaged Returned (pcs)'**
  String get stockDamagedReturnQtyLabel;

  /// No description provided for @stockLostQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Lost (pcs)'**
  String get stockLostQtyLabel;

  /// No description provided for @stockShortageQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Shortage / Missing (pcs)'**
  String get stockShortageQtyLabel;

  /// No description provided for @stockSettlementReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (Required for Damaged / Lost / Shortage)'**
  String get stockSettlementReasonLabel;

  /// No description provided for @stockSettlementTotalExceedsError.
  ///
  /// In en, this message translates to:
  /// **'Total settled quantity exceeds remaining pending quantity.'**
  String get stockSettlementTotalExceedsError;

  /// No description provided for @stockSettlementEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one quantity greater than zero.'**
  String get stockSettlementEmptyError;

  /// No description provided for @stockSettlementReasonRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Reason is required for damaged, lost, or shortage settlements.'**
  String get stockSettlementReasonRequiredError;

  /// No description provided for @stockSettlementSuccess.
  ///
  /// In en, this message translates to:
  /// **'Return / settlement recorded.'**
  String get stockSettlementSuccess;

  /// No description provided for @stockInheritedRateNotice.
  ///
  /// In en, this message translates to:
  /// **'Original locked issue rate and billing rule will be inherited automatically.'**
  String get stockInheritedRateNotice;

  /// No description provided for @stockRepairHeading.
  ///
  /// In en, this message translates to:
  /// **'Damaged-to-Good Repair Adjustment'**
  String get stockRepairHeading;

  /// No description provided for @stockRepairQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Repaired Quantity (pcs)'**
  String get stockRepairQuantityLabel;

  /// No description provided for @stockRepairReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Repair Reason (Required)'**
  String get stockRepairReasonLabel;

  /// No description provided for @stockRepairExceedsDamagedError.
  ///
  /// In en, this message translates to:
  /// **'Quantity exceeds current damaged stock bucket.'**
  String get stockRepairExceedsDamagedError;

  /// No description provided for @stockRepairSuccess.
  ///
  /// In en, this message translates to:
  /// **'Damaged stock adjusted back to good stock.'**
  String get stockRepairSuccess;

  /// No description provided for @stockNoDamagedAvailable.
  ///
  /// In en, this message translates to:
  /// **'No damaged stock is currently available for repair.'**
  String get stockNoDamagedAvailable;

  /// No description provided for @stockReverseAction.
  ///
  /// In en, this message translates to:
  /// **'Reverse Entry'**
  String get stockReverseAction;

  /// No description provided for @stockReverseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse Movement?'**
  String get stockReverseConfirmTitle;

  /// No description provided for @stockReverseReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reversal Reason (Required)'**
  String get stockReverseReasonLabel;

  /// No description provided for @stockReverseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Movement reversed with full audit trail.'**
  String get stockReverseSuccess;

  /// No description provided for @stockReverseBlockedDownstream.
  ///
  /// In en, this message translates to:
  /// **'Cannot reverse: downstream stock movements depend on these pieces.'**
  String get stockReverseBlockedDownstream;

  /// No description provided for @stockReverseBlockedChildren.
  ///
  /// In en, this message translates to:
  /// **'Reverse child returns/settlements before reversing this issue.'**
  String get stockReverseBlockedChildren;

  /// No description provided for @stockReversedBadge.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get stockReversedBadge;

  /// No description provided for @stockEmptyIssuesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Pending Issues'**
  String get stockEmptyIssuesTitle;

  /// No description provided for @stockEmptyIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All issued pieces have been settled, or no stock has been issued yet.'**
  String get stockEmptyIssuesSubtitle;

  /// No description provided for @stockEmptyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No Stock Movements Yet'**
  String get stockEmptyHistoryTitle;

  /// No description provided for @stockEmptyHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Issue stock to a worker and process to start tracking movements.'**
  String get stockEmptyHistorySubtitle;

  /// No description provided for @stockSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search lot, design, colour, worker, process...'**
  String get stockSearchHint;

  /// No description provided for @stockFilterAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get stockFilterAllTypes;

  /// No description provided for @stockTypeIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get stockTypeIssue;

  /// No description provided for @stockTypeReturnGood.
  ///
  /// In en, this message translates to:
  /// **'Good Return'**
  String get stockTypeReturnGood;

  /// No description provided for @stockTypeReturnDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged Return'**
  String get stockTypeReturnDamaged;

  /// No description provided for @stockTypeLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get stockTypeLost;

  /// No description provided for @stockTypeShortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get stockTypeShortage;

  /// No description provided for @stockTypeRepair.
  ///
  /// In en, this message translates to:
  /// **'Damaged -> Good'**
  String get stockTypeRepair;

  /// No description provided for @stockTypeReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversal'**
  String get stockTypeReversal;

  /// No description provided for @stockDetailsHeading.
  ///
  /// In en, this message translates to:
  /// **'Issue & Return Details'**
  String get stockDetailsHeading;

  /// No description provided for @accountingHeading.
  ///
  /// In en, this message translates to:
  /// **'Labour & Worker Accounts'**
  String get accountingHeading;

  /// No description provided for @accountingTabWorkers.
  ///
  /// In en, this message translates to:
  /// **'Worker Balances'**
  String get accountingTabWorkers;

  /// No description provided for @accountingTabPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get accountingTabPayments;

  /// No description provided for @accountingTabLabour.
  ///
  /// In en, this message translates to:
  /// **'Labour Entries'**
  String get accountingTabLabour;

  /// No description provided for @accountingEarnedLabourLabel.
  ///
  /// In en, this message translates to:
  /// **'Earned Labour'**
  String get accountingEarnedLabourLabel;

  /// No description provided for @accountingIssuedLabourInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Issued Labour (Info)'**
  String get accountingIssuedLabourInfoLabel;

  /// No description provided for @accountingReceivedLabourInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Received Labour (Info)'**
  String get accountingReceivedLabourInfoLabel;

  /// No description provided for @accountingRegularPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Regular Payments'**
  String get accountingRegularPaidLabel;

  /// No description provided for @accountingAdvancePaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Advances Paid'**
  String get accountingAdvancePaidLabel;

  /// No description provided for @accountingAdvanceRefundLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance Refunds'**
  String get accountingAdvanceRefundLabel;

  /// No description provided for @accountingAdjustmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get accountingAdjustmentsLabel;

  /// No description provided for @accountingOutstandingPayableLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Payable'**
  String get accountingOutstandingPayableLabel;

  /// No description provided for @accountingAdvanceCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance Credit'**
  String get accountingAdvanceCreditLabel;

  /// No description provided for @accountingNetBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get accountingNetBalanceLabel;

  /// No description provided for @accountingRecordPaymentAction.
  ///
  /// In en, this message translates to:
  /// **'Record Payment / Advance'**
  String get accountingRecordPaymentAction;

  /// No description provided for @accountingAddAdjustmentAction.
  ///
  /// In en, this message translates to:
  /// **'Add Adjustment'**
  String get accountingAddAdjustmentAction;

  /// No description provided for @accountingOpenLedgerAction.
  ///
  /// In en, this message translates to:
  /// **'Worker Ledger'**
  String get accountingOpenLedgerAction;

  /// No description provided for @accountingPaymentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get accountingPaymentTypeLabel;

  /// No description provided for @accountingPaymentTypeRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular Payment'**
  String get accountingPaymentTypeRegular;

  /// No description provided for @accountingPaymentTypeAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance Payment'**
  String get accountingPaymentTypeAdvance;

  /// No description provided for @accountingPaymentTypeRefund.
  ///
  /// In en, this message translates to:
  /// **'Advance Refund'**
  String get accountingPaymentTypeRefund;

  /// No description provided for @accountingPaymentModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get accountingPaymentModeLabel;

  /// No description provided for @accountingModeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountingModeCash;

  /// No description provided for @accountingModeUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get accountingModeUpi;

  /// No description provided for @accountingModeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get accountingModeBank;

  /// No description provided for @accountingModeCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get accountingModeCheque;

  /// No description provided for @accountingModeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get accountingModeOther;

  /// No description provided for @accountingAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get accountingAmountLabel;

  /// No description provided for @accountingReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference / Receipt No. (Optional)'**
  String get accountingReferenceLabel;

  /// No description provided for @accountingPaymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully.'**
  String get accountingPaymentSaved;

  /// No description provided for @accountingAdjustmentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Type'**
  String get accountingAdjustmentTypeLabel;

  /// No description provided for @accountingAdjustmentCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit (+ Add to Payable)'**
  String get accountingAdjustmentCredit;

  /// No description provided for @accountingAdjustmentDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit (- Deduct from Payable)'**
  String get accountingAdjustmentDebit;

  /// No description provided for @accountingAdjustmentReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Reason (Required)'**
  String get accountingAdjustmentReasonLabel;

  /// No description provided for @accountingAdjustmentSaved.
  ///
  /// In en, this message translates to:
  /// **'Worker ledger adjustment recorded.'**
  String get accountingAdjustmentSaved;

  /// No description provided for @accountingReversePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse Payment?'**
  String get accountingReversePaymentTitle;

  /// No description provided for @accountingReversePaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment reversed cleanly.'**
  String get accountingReversePaymentSuccess;

  /// No description provided for @accountingReverseAdjustmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse Adjustment?'**
  String get accountingReverseAdjustmentTitle;

  /// No description provided for @accountingReverseAdjustmentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Adjustment reversed cleanly.'**
  String get accountingReverseAdjustmentSuccess;

  /// No description provided for @accountingLedgerHeading.
  ///
  /// In en, this message translates to:
  /// **'Worker Ledger'**
  String get accountingLedgerHeading;

  /// No description provided for @accountingOpeningBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get accountingOpeningBalanceLabel;

  /// No description provided for @accountingRunningBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Running Bal.'**
  String get accountingRunningBalanceLabel;

  /// No description provided for @accountingFromDateLabel.
  ///
  /// In en, this message translates to:
  /// **'From Date (IST)'**
  String get accountingFromDateLabel;

  /// No description provided for @accountingToDateLabel.
  ///
  /// In en, this message translates to:
  /// **'To Date (IST)'**
  String get accountingToDateLabel;

  /// No description provided for @accountingClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get accountingClearFilters;

  /// No description provided for @accountingEmptyLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'No Ledger Entries'**
  String get accountingEmptyLedgerTitle;

  /// No description provided for @accountingEmptyLedgerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earned labour, advances, payments, and adjustments will appear here.'**
  String get accountingEmptyLedgerSubtitle;

  /// No description provided for @accountingAdvanceNote.
  ///
  /// In en, this message translates to:
  /// **'Advances are tracked separately and never counted as earned labour.'**
  String get accountingAdvanceNote;

  /// No description provided for @accountingPayableBadge.
  ///
  /// In en, this message translates to:
  /// **'Payable'**
  String get accountingPayableBadge;

  /// No description provided for @accountingInfoBadge.
  ///
  /// In en, this message translates to:
  /// **'Info Only'**
  String get accountingInfoBadge;

  /// No description provided for @backupHeading.
  ///
  /// In en, this message translates to:
  /// **'Backup, Restore & Data Safety'**
  String get backupHeading;

  /// No description provided for @backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'100% offline local backup of your SQLite database and private lot photos.'**
  String get backupSubtitle;

  /// No description provided for @backupCreateFullAction.
  ///
  /// In en, this message translates to:
  /// **'Create Full Backup (.zip)'**
  String get backupCreateFullAction;

  /// No description provided for @backupCreateFullDesc.
  ///
  /// In en, this message translates to:
  /// **'Packages a WAL-consistent SQLite snapshot, all private lot photos, and an integrity manifest into a portable ZIP archive.'**
  String get backupCreateFullDesc;

  /// No description provided for @backupRestoreFullAction.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup (.zip)'**
  String get backupRestoreFullAction;

  /// No description provided for @backupRestoreFullDesc.
  ///
  /// In en, this message translates to:
  /// **'Validates archive integrity, checksums, and schema compatibility before atomically replacing local data with automatic rollback protection.'**
  String get backupRestoreFullDesc;

  /// No description provided for @backupRawSqliteAction.
  ///
  /// In en, this message translates to:
  /// **'Export Raw SQLite (.sqlite)'**
  String get backupRawSqliteAction;

  /// No description provided for @backupRawSqliteDesc.
  ///
  /// In en, this message translates to:
  /// **'Creates a clean standalone .sqlite file for inspection in external SQLite viewers. Does not include photos.'**
  String get backupRawSqliteDesc;

  /// No description provided for @backupShareLastAction.
  ///
  /// In en, this message translates to:
  /// **'Share / Save File'**
  String get backupShareLastAction;

  /// No description provided for @backupLastCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Exported File'**
  String get backupLastCreatedLabel;

  /// No description provided for @backupValidationPassed.
  ///
  /// In en, this message translates to:
  /// **'Backup Archive Verified'**
  String get backupValidationPassed;

  /// No description provided for @backupValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup Validation Failed'**
  String get backupValidationFailed;

  /// No description provided for @backupConfirmRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Overwrite Local Data?'**
  String get backupConfirmRestoreTitle;

  /// No description provided for @backupConfirmRestoreMessage.
  ///
  /// In en, this message translates to:
  /// **'Restoring this backup will replace your current local database and photos. A temporary rollback safety copy will be made automatically before swapping.'**
  String get backupConfirmRestoreMessage;

  /// No description provided for @backupConfirmRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Yes, Restore Now'**
  String get backupConfirmRestoreAction;

  /// No description provided for @backupRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored and verified successfully.'**
  String get backupRestoreSuccess;

  /// No description provided for @backupExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully.'**
  String get backupExportSuccess;

  /// No description provided for @backupProgressWorking.
  ///
  /// In en, this message translates to:
  /// **'Processing securely...'**
  String get backupProgressWorking;

  /// No description provided for @backupLimitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Backup Notes'**
  String get backupLimitationsTitle;

  /// No description provided for @backupLimitationsBody.
  ///
  /// In en, this message translates to:
  /// **'• Backups are unencrypted in V1 so you can inspect .sqlite files directly.\n• Keep backup ZIP files in a safe personal folder or external drive.\n• Restoring a Dev backup into Production StitchFlow is blocked for safety.'**
  String get backupLimitationsBody;

  /// No description provided for @dashboardLiveOverview.
  ///
  /// In en, this message translates to:
  /// **'Business Overview'**
  String get dashboardLiveOverview;

  /// No description provided for @dashboardStockHealth.
  ///
  /// In en, this message translates to:
  /// **'Inventory & Production Health'**
  String get dashboardStockHealth;

  /// No description provided for @dashboardFinanceHealth.
  ///
  /// In en, this message translates to:
  /// **'Worker Accounting Summary'**
  String get dashboardFinanceHealth;

  /// No description provided for @dashboardProcessPending.
  ///
  /// In en, this message translates to:
  /// **'Process-Wise Pending Work'**
  String get dashboardProcessPending;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Audit Activity'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardNoProcessPending.
  ///
  /// In en, this message translates to:
  /// **'No pending stock across processes.'**
  String get dashboardNoProcessPending;

  /// No description provided for @dashboardNoRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity logged yet.'**
  String get dashboardNoRecentActivity;

  /// No description provided for @dashboardTotalLotsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Lots'**
  String get dashboardTotalLotsLabel;

  /// No description provided for @dashboardTotalDesignsColoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Designs / Colours'**
  String get dashboardTotalDesignsColoursLabel;

  /// No description provided for @reportsHeading.
  ///
  /// In en, this message translates to:
  /// **'Business Reports'**
  String get reportsHeading;

  /// No description provided for @reportsTabStockSummary.
  ///
  /// In en, this message translates to:
  /// **'Stock Summary'**
  String get reportsTabStockSummary;

  /// No description provided for @reportsTabLots.
  ///
  /// In en, this message translates to:
  /// **'Lot-Wise'**
  String get reportsTabLots;

  /// No description provided for @reportsTabColours.
  ///
  /// In en, this message translates to:
  /// **'Design / Colour'**
  String get reportsTabColours;

  /// No description provided for @reportsTabWorkers.
  ///
  /// In en, this message translates to:
  /// **'Worker Stock'**
  String get reportsTabWorkers;

  /// No description provided for @reportsTabProcesses.
  ///
  /// In en, this message translates to:
  /// **'Process Stock'**
  String get reportsTabProcesses;

  /// No description provided for @reportsTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Stock'**
  String get reportsTabPending;

  /// No description provided for @reportsTabDamagedLost.
  ///
  /// In en, this message translates to:
  /// **'Damaged & Lost'**
  String get reportsTabDamagedLost;

  /// No description provided for @reportsTabLabour.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get reportsTabLabour;

  /// No description provided for @reportsTabWorkerLedger.
  ///
  /// In en, this message translates to:
  /// **'Worker Accounts'**
  String get reportsTabWorkerLedger;

  /// No description provided for @reportsTabPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get reportsTabPayments;

  /// No description provided for @reportsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter reports by lot, design, colour, worker...'**
  String get reportsSearchHint;

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Matching Records'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust your date range or filters to view matching business data.'**
  String get reportsEmptySubtitle;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navStockShort.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get navStockShort;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @lotLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Lot'**
  String get lotLabelShort;

  /// No description provided for @refLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Ref'**
  String get refLabelShort;

  /// No description provided for @inventoryUpdatedNote.
  ///
  /// In en, this message translates to:
  /// **'Shows recorded initial quantities across lots, designs, and colours. Open Stock Movements for live balances.'**
  String get inventoryUpdatedNote;

  /// No description provided for @auditActionCreate.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get auditActionCreate;

  /// No description provided for @auditActionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get auditActionUpdate;

  /// No description provided for @auditActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get auditActionDelete;

  /// No description provided for @auditActionRateOverride.
  ///
  /// In en, this message translates to:
  /// **'Rate Override'**
  String get auditActionRateOverride;

  /// No description provided for @auditActionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get auditActionRestore;

  /// No description provided for @settingsHeading.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsHeading;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage appearance, business profile, stock rules, backups, and workshop guidance.'**
  String get settingsSubtitle;

  /// No description provided for @settingsAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme mode (System / Light / Dark) and app language (English / Gujarati).'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsAppearancePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Preview'**
  String get settingsAppearancePreviewTitle;

  /// No description provided for @settingsAppearancePreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Verify text readability, Gujarati script clarity, and contrast before returning to daily work.'**
  String get settingsAppearancePreviewBody;

  /// No description provided for @settingsBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get settingsBusinessTitle;

  /// No description provided for @settingsBusinessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Workshop names in English & Gujarati, owner, phone, address, and default billing.'**
  String get settingsBusinessSubtitle;

  /// No description provided for @settingsStockLabourTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock & Labour Preferences'**
  String get settingsStockLabourTitle;

  /// No description provided for @settingsStockLabourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Global billing rule and per-process labour override overview.'**
  String get settingsStockLabourSubtitle;

  /// No description provided for @settingsGlobalBillingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Default Labour Billing Mode'**
  String get settingsGlobalBillingSectionTitle;

  /// No description provided for @settingsGlobalBillingExplanationReceived.
  ///
  /// In en, this message translates to:
  /// **'Workers earn labour when returned good pieces are recorded. Damaged pieces are excluded unless enabled on a specific process.'**
  String get settingsGlobalBillingExplanationReceived;

  /// No description provided for @settingsGlobalBillingExplanationGiven.
  ///
  /// In en, this message translates to:
  /// **'Workers earn labour immediately when stock is issued to them. Return entries stay informational to prevent double-counting.'**
  String get settingsGlobalBillingExplanationGiven;

  /// No description provided for @settingsProcessOverridesTitle.
  ///
  /// In en, this message translates to:
  /// **'Process-Level Rules'**
  String get settingsProcessOverridesTitle;

  /// No description provided for @settingsProcessOverridesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each process inherits the global billing mode unless overridden. Tap any process to configure.'**
  String get settingsProcessOverridesSubtitle;

  /// No description provided for @settingsProcessInheritsGlobal.
  ///
  /// In en, this message translates to:
  /// **'Inherits Global Default'**
  String get settingsProcessInheritsGlobal;

  /// No description provided for @settingsProcessOverridesGlobal.
  ///
  /// In en, this message translates to:
  /// **'Process Override'**
  String get settingsProcessOverridesGlobal;

  /// No description provided for @settingsDamagedIncludedShort.
  ///
  /// In en, this message translates to:
  /// **'Damaged Included'**
  String get settingsDamagedIncludedShort;

  /// No description provided for @settingsDamagedExcludedShort.
  ///
  /// In en, this message translates to:
  /// **'Damaged Excluded'**
  String get settingsDamagedExcludedShort;

  /// No description provided for @settingsNoProcessesYet.
  ///
  /// In en, this message translates to:
  /// **'No production processes created yet.'**
  String get settingsNoProcessesYet;

  /// No description provided for @settingsBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Data Safety'**
  String get settingsBackupTitle;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create full ZIP backups, restore safely, or export raw SQLite.'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Guidance'**
  String get settingsHelpTitle;

  /// No description provided for @settingsHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step workshop instructions for every StitchFlow workflow.'**
  String get settingsHelpSubtitle;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About StitchFlow'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, flavor, local data privacy, and open-source licenses.'**
  String get settingsAboutSubtitle;

  /// No description provided for @helpSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search help topics (e.g. issue, return, rate, backup)...'**
  String get helpSearchHint;

  /// No description provided for @helpWhenToUseLabel.
  ///
  /// In en, this message translates to:
  /// **'When to Use'**
  String get helpWhenToUseLabel;

  /// No description provided for @helpStepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Step-by-Step Guide'**
  String get helpStepsLabel;

  /// No description provided for @helpExampleLabel.
  ///
  /// In en, this message translates to:
  /// **'Practical Workshop Example'**
  String get helpExampleLabel;

  /// No description provided for @helpNoResults.
  ///
  /// In en, this message translates to:
  /// **'No help topics match your search.'**
  String get helpNoResults;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersionLabel;

  /// No description provided for @aboutBuildLabel.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get aboutBuildLabel;

  /// No description provided for @aboutPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'100% Offline & Private Local Data'**
  String get aboutPrivacyTitle;

  /// No description provided for @aboutPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'All lots, stock movements, worker rates, ledgers, and photos stay strictly on your device in local SQLite storage. StitchFlow never uploads your business records to external servers.'**
  String get aboutPrivacyBody;

  /// No description provided for @aboutDescriptionBody.
  ///
  /// In en, this message translates to:
  /// **'StitchFlow is an offline-first garment workshop production, stock movement, and worker accounting application built for fast daily shop-floor operations.'**
  String get aboutDescriptionBody;

  /// No description provided for @aboutLicensesAction.
  ///
  /// In en, this message translates to:
  /// **'Open-Source Licenses'**
  String get aboutLicensesAction;

  /// No description provided for @stockStepSelectStock.
  ///
  /// In en, this message translates to:
  /// **'Select Stock'**
  String get stockStepSelectStock;

  /// No description provided for @stockStepSelectWork.
  ///
  /// In en, this message translates to:
  /// **'Select Work'**
  String get stockStepSelectWork;

  /// No description provided for @stockStepEnterQty.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get stockStepEnterQty;

  /// No description provided for @stockStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get stockStepConfirm;

  /// No description provided for @stockSearchStockHint.
  ///
  /// In en, this message translates to:
  /// **'Search by lot, design, or colour...'**
  String get stockSearchStockHint;

  /// No description provided for @stockOnlyAvailableFilter.
  ///
  /// In en, this message translates to:
  /// **'In Stock Only'**
  String get stockOnlyAvailableFilter;

  /// No description provided for @stockOutOfStockBadge.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get stockOutOfStockBadge;

  /// No description provided for @stockNoStockItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Stock Available'**
  String get stockNoStockItemsTitle;

  /// No description provided for @stockNoStockItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a lot with designs and colours first, or receive returned stock to replenish in-house good stock.'**
  String get stockNoStockItemsSubtitle;

  /// No description provided for @stockSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get stockSelectedLabel;

  /// No description provided for @stockChangeSelection.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get stockChangeSelection;

  /// No description provided for @stockActiveProcessesLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Process'**
  String get stockActiveProcessesLabel;

  /// No description provided for @stockEligibleWorkersLabel.
  ///
  /// In en, this message translates to:
  /// **'Eligible Assigned Worker'**
  String get stockEligibleWorkersLabel;

  /// No description provided for @stockNoActiveProcessesWarning.
  ///
  /// In en, this message translates to:
  /// **'No active processes exist. Create a process before issuing stock.'**
  String get stockNoActiveProcessesWarning;

  /// No description provided for @stockBillingModePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked Billing Mode'**
  String get stockBillingModePreviewLabel;

  /// No description provided for @stockExpectedLabourLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Labour'**
  String get stockExpectedLabourLabel;

  /// No description provided for @stockPayableOnIssueNote.
  ///
  /// In en, this message translates to:
  /// **'Payable immediately on issue (Given Qty mode).'**
  String get stockPayableOnIssueNote;

  /// No description provided for @stockPayableOnReturnNote.
  ///
  /// In en, this message translates to:
  /// **'Earned when good pieces are returned (Received Qty mode).'**
  String get stockPayableOnReturnNote;

  /// No description provided for @stockAdvancedOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Date/Time, Notes & Audited Rate Override'**
  String get stockAdvancedOptionsTitle;

  /// No description provided for @stockQuickAllAvailable.
  ///
  /// In en, this message translates to:
  /// **'All Available'**
  String get stockQuickAllAvailable;

  /// No description provided for @stockConfirmSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Stock Issue'**
  String get stockConfirmSummaryTitle;

  /// No description provided for @stockConfirmIssueAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Issue Stock'**
  String get stockConfirmIssueAction;

  /// No description provided for @stockIssueSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock Issued Successfully'**
  String get stockIssueSuccessTitle;

  /// No description provided for @stockIssueSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The issue and locked rate have been saved in the stock ledger.'**
  String get stockIssueSuccessSubtitle;

  /// No description provided for @stockUpdatedAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated Available Good Stock'**
  String get stockUpdatedAvailableLabel;

  /// No description provided for @stockIssueMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Issue More Stock'**
  String get stockIssueMoreAction;

  /// No description provided for @stockViewIssueDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'View Issue / Receive Return'**
  String get stockViewIssueDetailsAction;

  /// No description provided for @stockReceiveReturnHeading.
  ///
  /// In en, this message translates to:
  /// **'Receive Return'**
  String get stockReceiveReturnHeading;

  /// No description provided for @stockSelectPendingIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Pending Issue'**
  String get stockSelectPendingIssueTitle;

  /// No description provided for @stockSelectPendingIssueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an open issue below to record returned good, damaged, lost, or shortage pieces.'**
  String get stockSelectPendingIssueSubtitle;

  /// No description provided for @stockFilterAllWorkers.
  ///
  /// In en, this message translates to:
  /// **'All Workers'**
  String get stockFilterAllWorkers;

  /// No description provided for @stockFilterAllProcesses.
  ///
  /// In en, this message translates to:
  /// **'All Processes'**
  String get stockFilterAllProcesses;

  /// No description provided for @stockPreviouslyReturnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get stockPreviouslyReturnedLabel;

  /// No description provided for @stockFillAllRemaining.
  ///
  /// In en, this message translates to:
  /// **'All Good'**
  String get stockFillAllRemaining;

  /// No description provided for @stockLiveRemainingAfterReturn.
  ///
  /// In en, this message translates to:
  /// **'Remaining Pending After Save'**
  String get stockLiveRemainingAfterReturn;

  /// No description provided for @stockOverReturnErrorLive.
  ///
  /// In en, this message translates to:
  /// **'Total entered exceeds remaining pending quantity.'**
  String get stockOverReturnErrorLive;

  /// No description provided for @stockConsequencesTitle.
  ///
  /// In en, this message translates to:
  /// **'What Will Happen on Save'**
  String get stockConsequencesTitle;

  /// No description provided for @stockConsequenceGood.
  ///
  /// In en, this message translates to:
  /// **'Returning to in-house good stock'**
  String get stockConsequenceGood;

  /// No description provided for @stockConsequenceDamaged.
  ///
  /// In en, this message translates to:
  /// **'Moving into damaged inventory bucket'**
  String get stockConsequenceDamaged;

  /// No description provided for @stockConsequenceLost.
  ///
  /// In en, this message translates to:
  /// **'Recorded as permanently lost stock'**
  String get stockConsequenceLost;

  /// No description provided for @stockConsequenceShortage.
  ///
  /// In en, this message translates to:
  /// **'Recorded as shortage discrepancy'**
  String get stockConsequenceShortage;

  /// No description provided for @stockConsequencePending.
  ///
  /// In en, this message translates to:
  /// **'Remaining pending with worker'**
  String get stockConsequencePending;

  /// No description provided for @stockConsequenceLabourEarned.
  ///
  /// In en, this message translates to:
  /// **'Payable labour credited to worker'**
  String get stockConsequenceLabourEarned;

  /// No description provided for @stockConsequenceLabourAlreadyGiven.
  ///
  /// In en, this message translates to:
  /// **'Labour was already credited on Issue (Given Qty mode) — no duplicate labour added.'**
  String get stockConsequenceLabourAlreadyGiven;

  /// No description provided for @stockConsequenceLabourNone.
  ///
  /// In en, this message translates to:
  /// **'No additional payable labour for this entry.'**
  String get stockConsequenceLabourNone;

  /// No description provided for @stockLostHelper.
  ///
  /// In en, this message translates to:
  /// **'Pieces physically lost or misplaced (cannot be recovered).'**
  String get stockLostHelper;

  /// No description provided for @stockShortageHelper.
  ///
  /// In en, this message translates to:
  /// **'Count difference / short pieces reported during settlement.'**
  String get stockShortageHelper;

  /// No description provided for @stockConfirmSaveReturnAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Save Return'**
  String get stockConfirmSaveReturnAction;

  /// No description provided for @stockReturnSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Recorded Successfully'**
  String get stockReturnSuccessTitle;

  /// No description provided for @stockReturnFullySettledBadge.
  ///
  /// In en, this message translates to:
  /// **'Fully Settled'**
  String get stockReturnFullySettledBadge;

  /// No description provided for @stockReturnUpdatedPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated Remaining Pending'**
  String get stockReturnUpdatedPendingLabel;

  /// No description provided for @stockIssueNextProcessAction.
  ///
  /// In en, this message translates to:
  /// **'Issue Returned Stock to Next Process'**
  String get stockIssueNextProcessAction;

  /// No description provided for @stockReceiveAnotherReturnAction.
  ///
  /// In en, this message translates to:
  /// **'Receive Another Return'**
  String get stockReceiveAnotherReturnAction;

  /// No description provided for @stockTabPendingReturns.
  ///
  /// In en, this message translates to:
  /// **'Pending Returns'**
  String get stockTabPendingReturns;

  /// No description provided for @stockTabMovementHistory.
  ///
  /// In en, this message translates to:
  /// **'Movement History'**
  String get stockTabMovementHistory;

  /// No description provided for @stockTabSummary.
  ///
  /// In en, this message translates to:
  /// **'Worker & Process'**
  String get stockTabSummary;
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
