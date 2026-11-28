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

  /// Generic title for a page that failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this page'**
  String get errorLoadTitle;

  /// Validation message when a required field is empty.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get validationRequired;

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

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActions;

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
  /// **'Search design, colour, or lot number...'**
  String get designsSearchHint;

  /// No description provided for @designsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Designs Recorded Yet'**
  String get designsEmptyTitle;

  /// No description provided for @designsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a lot with designs and colours to see them tracked here across lots.'**
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
  /// **'Work Stages'**
  String get navProcesses;

  /// Short bottom-navigation label for the Work Stages tab.
  ///
  /// In en, this message translates to:
  /// **'Stages'**
  String get navWorkStagesShort;

  /// No description provided for @processQuickCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New Work Stage'**
  String get processQuickCreateAction;

  /// No description provided for @settingsManageWorkStagesAction.
  ///
  /// In en, this message translates to:
  /// **'Manage Work Stages'**
  String get settingsManageWorkStagesAction;

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
  /// **'Work Stages'**
  String get processesHeading;

  /// No description provided for @processesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search work stages by name or description'**
  String get processesSearchHint;

  /// No description provided for @processesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Work Stages Yet'**
  String get processesEmptyTitle;

  /// No description provided for @processesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your own work stages in any order your workshop uses.'**
  String get processesEmptySubtitle;

  /// No description provided for @processCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New Work Stage'**
  String get processCreateAction;

  /// No description provided for @processEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Work Stage'**
  String get processEditAction;

  /// No description provided for @processDetailsHeading.
  ///
  /// In en, this message translates to:
  /// **'Work Stage Details'**
  String get processDetailsHeading;

  /// No description provided for @processNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Stage Name'**
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
  /// **'Activate Work Stage'**
  String get processActivateAction;

  /// No description provided for @processDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Work Stage'**
  String get processDeactivateAction;

  /// No description provided for @processDeactivateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Work Stage?'**
  String get processDeactivateConfirmTitle;

  /// No description provided for @processDeactivateConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Historical records remain intact, but new assignments and issues will be blocked while inactive.'**
  String get processDeactivateConfirmMessage;

  /// No description provided for @processDuplicateNameError.
  ///
  /// In en, this message translates to:
  /// **'A work stage with this name already exists.'**
  String get processDuplicateNameError;

  /// No description provided for @processAssignedWorkersHeading.
  ///
  /// In en, this message translates to:
  /// **'Assigned Workers'**
  String get processAssignedWorkersHeading;

  /// No description provided for @processNoAssignedWorkers.
  ///
  /// In en, this message translates to:
  /// **'No workers are currently assigned to this work stage.'**
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
  /// **'Add your workshop workers to assign work stages and configure per-piece rates.'**
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
  /// **'Assigned Work Stages & Current Rates'**
  String get workerAssignedProcessesHeading;

  /// No description provided for @workerNoAssignedProcesses.
  ///
  /// In en, this message translates to:
  /// **'No work stages assigned yet.'**
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
  /// **'Worker Stage Assignments'**
  String get assignmentsHeading;

  /// No description provided for @assignmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A worker can be assigned to multiple work stages with no fixed sequence.'**
  String get assignmentsSubtitle;

  /// No description provided for @assignmentsAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Active Work Stage'**
  String get assignmentsAddLabel;

  /// No description provided for @assignmentsAddAction.
  ///
  /// In en, this message translates to:
  /// **'Assign Work Stage'**
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
  /// **'Assign one or more active work stages to this worker.'**
  String get assignmentsEmptySubtitle;

  /// No description provided for @assignmentsNoAvailableProcesses.
  ///
  /// In en, this message translates to:
  /// **'All active work stages are already assigned or no active work stages exist.'**
  String get assignmentsNoAvailableProcesses;

  /// No description provided for @assignmentsDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'This work stage is already assigned to the worker.'**
  String get assignmentsDuplicateError;

  /// No description provided for @assignmentsInactiveWorkerError.
  ///
  /// In en, this message translates to:
  /// **'Activate this worker before adding work stage assignments.'**
  String get assignmentsInactiveWorkerError;

  /// No description provided for @assignmentsInactiveProcessError.
  ///
  /// In en, this message translates to:
  /// **'Only active work stages can be assigned.'**
  String get assignmentsInactiveProcessError;

  /// No description provided for @ratesHistoryHeading.
  ///
  /// In en, this message translates to:
  /// **'Per-Piece Rate History'**
  String get ratesHistoryHeading;

  /// No description provided for @ratesFilterProcessLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Stage'**
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
  /// **'Add an effective-dated per-piece rate for this worker and work stage.'**
  String get ratesEmptySubtitle;

  /// No description provided for @ratesSelectProcessHint.
  ///
  /// In en, this message translates to:
  /// **'Select Work Stage'**
  String get ratesSelectProcessHint;

  /// No description provided for @ratesAutoCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Previous Ongoing Rate?'**
  String get ratesAutoCloseTitle;

  /// No description provided for @ratesAutoCloseMessage.
  ///
  /// In en, this message translates to:
  /// **'An ongoing rate exists for this work stage. Saving will close it on the previous day and start the new rate from your chosen date.'**
  String get ratesAutoCloseMessage;

  /// No description provided for @ratesOverlapError.
  ///
  /// In en, this message translates to:
  /// **'This date range overlaps with an existing rate.'**
  String get ratesOverlapError;

  /// No description provided for @ratesMultipleOpenEndedError.
  ///
  /// In en, this message translates to:
  /// **'Another ongoing rate already exists for this worker and work stage.'**
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

  /// No description provided for @stockTabBalances.
  ///
  /// In en, this message translates to:
  /// **'Live Stock'**
  String get stockTabBalances;

  /// No description provided for @stockTabWorkers.
  ///
  /// In en, this message translates to:
  /// **'By Worker'**
  String get stockTabWorkers;

  /// No description provided for @stockTabProcesses.
  ///
  /// In en, this message translates to:
  /// **'By Work Stage'**
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

  /// No description provided for @stockSelectColourLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Colour'**
  String get stockSelectColourLabel;

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
  /// **'No effective historical rate exists for this worker and work stage on the chosen IST date.'**
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

  /// No description provided for @stockNoEligibleWorkers.
  ///
  /// In en, this message translates to:
  /// **'No active workers are assigned to this work stage.'**
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
  /// **'Issue stock to a worker and work stage to start tracking movements.'**
  String get stockEmptyHistorySubtitle;

  /// No description provided for @stockSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search lot, design, colour, worker, work stage...'**
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
  /// **'Stage-Wise Pending Work'**
  String get dashboardProcessPending;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Audit Activity'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardNoProcessPending.
  ///
  /// In en, this message translates to:
  /// **'No pending stock across work stages.'**
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
  /// **'Global billing rule and per-stage labour override overview.'**
  String get settingsStockLabourSubtitle;

  /// No description provided for @settingsGlobalBillingExplanationReceived.
  ///
  /// In en, this message translates to:
  /// **'Workers earn labour when returned good pieces are recorded. Damaged pieces are excluded unless enabled on a specific work stage.'**
  String get settingsGlobalBillingExplanationReceived;

  /// No description provided for @settingsGlobalBillingExplanationGiven.
  ///
  /// In en, this message translates to:
  /// **'Workers earn labour immediately when stock is issued to them. Return entries stay informational to prevent double-counting.'**
  String get settingsGlobalBillingExplanationGiven;

  /// No description provided for @settingsProcessOverridesTitle.
  ///
  /// In en, this message translates to:
  /// **'Stage-Level Rules'**
  String get settingsProcessOverridesTitle;

  /// No description provided for @settingsProcessOverridesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each work stage inherits the global billing mode unless overridden. Tap any work stage to configure.'**
  String get settingsProcessOverridesSubtitle;

  /// No description provided for @settingsProcessInheritsGlobal.
  ///
  /// In en, this message translates to:
  /// **'Inherits Global Default'**
  String get settingsProcessInheritsGlobal;

  /// No description provided for @settingsProcessOverridesGlobal.
  ///
  /// In en, this message translates to:
  /// **'Work Stage Override'**
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
  /// **'No work stages created yet.'**
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

  /// No description provided for @stockChangeSelection.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get stockChangeSelection;

  /// No description provided for @stockActiveProcessesLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Work Stage'**
  String get stockActiveProcessesLabel;

  /// No description provided for @stockEligibleWorkersLabel.
  ///
  /// In en, this message translates to:
  /// **'Eligible Assigned Worker'**
  String get stockEligibleWorkersLabel;

  /// No description provided for @stockNoActiveProcessesWarning.
  ///
  /// In en, this message translates to:
  /// **'No active work stages exist. Create a work stage before issuing stock.'**
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
  /// **'All Work Stages'**
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
  /// **'Issue Returned Stock to Next Work Stage'**
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
  /// **'Worker & Work Stage'**
  String get stockTabSummary;

  /// No description provided for @auditActionDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get auditActionDeactivate;

  /// No description provided for @auditActionReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivated'**
  String get auditActionReactivate;

  /// No description provided for @auditActionBackupExport.
  ///
  /// In en, this message translates to:
  /// **'Backup Created'**
  String get auditActionBackupExport;

  /// No description provided for @auditActionBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup Restored'**
  String get auditActionBackupRestore;

  /// No description provided for @auditEntityBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get auditEntityBackup;

  /// No description provided for @auditEntityAppSecurity.
  ///
  /// In en, this message translates to:
  /// **'App Security'**
  String get auditEntityAppSecurity;

  /// No description provided for @settingsSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'App Lock & Security'**
  String get settingsSecurityTitle;

  /// No description provided for @settingsSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local PIN, optional fingerprint unlock, auto-lock timeout, and recovery key.'**
  String get settingsSecuritySubtitle;

  /// No description provided for @securityBadgeEnabled.
  ///
  /// In en, this message translates to:
  /// **'PIN Protected'**
  String get securityBadgeEnabled;

  /// No description provided for @securityBadgeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get securityBadgeOff;

  /// No description provided for @securityStatusProtected.
  ///
  /// In en, this message translates to:
  /// **'StitchFlow Is PIN Protected'**
  String get securityStatusProtected;

  /// No description provided for @securityStatusProtectedDesc.
  ///
  /// In en, this message translates to:
  /// **'{pinLength}-digit PIN • Auto-lock: {timeout}'**
  String securityStatusProtectedDesc(int pinLength, String timeout);

  /// No description provided for @securityStatusOff.
  ///
  /// In en, this message translates to:
  /// **'App Lock Is Off'**
  String get securityStatusOff;

  /// No description provided for @securityStatusOffDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a local PIN to prevent casual unauthorized access on your phone.'**
  String get securityStatusOffDesc;

  /// No description provided for @securitySetupPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up App PIN'**
  String get securitySetupPinTitle;

  /// No description provided for @securitySetupBenefitsBody.
  ///
  /// In en, this message translates to:
  /// **'Keep workshop stock, rates, and karigar accounts private with a 4- or 6-digit offline PIN and optional fingerprint unlock.'**
  String get securitySetupBenefitsBody;

  /// No description provided for @securityEnablePinAction.
  ///
  /// In en, this message translates to:
  /// **'Enable App PIN'**
  String get securityEnablePinAction;

  /// No description provided for @securityLockNowAction.
  ///
  /// In en, this message translates to:
  /// **'Lock Now'**
  String get securityLockNowAction;

  /// No description provided for @securityChangePinAction.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get securityChangePinAction;

  /// No description provided for @securityDisablePinAction.
  ///
  /// In en, this message translates to:
  /// **'Disable App PIN'**
  String get securityDisablePinAction;

  /// No description provided for @securityDisablePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove the local PIN and open StitchFlow without unlocking.'**
  String get securityDisablePinDesc;

  /// No description provided for @securityDisablePinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable App PIN?'**
  String get securityDisablePinConfirmTitle;

  /// No description provided for @securityDisablePinConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Anyone using this phone will be able to open StitchFlow without entering a PIN.'**
  String get securityDisablePinConfirmMessage;

  /// No description provided for @securityRegenerateRecoveryKeyAction.
  ///
  /// In en, this message translates to:
  /// **'New Recovery Key'**
  String get securityRegenerateRecoveryKeyAction;

  /// No description provided for @securityPinLength4Label.
  ///
  /// In en, this message translates to:
  /// **'4-Digit PIN (Fast)'**
  String get securityPinLength4Label;

  /// No description provided for @securityPinLength6Label.
  ///
  /// In en, this message translates to:
  /// **'6-Digit PIN'**
  String get securityPinLength6Label;

  /// No description provided for @securityCreatePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your PIN'**
  String get securityCreatePinTitle;

  /// No description provided for @securityEnterNewPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter New PIN'**
  String get securityEnterNewPinTitle;

  /// No description provided for @securityCreatePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a {pinLength}-digit numeric PIN.'**
  String securityCreatePinSubtitle(int pinLength);

  /// No description provided for @securityConfirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your PIN'**
  String get securityConfirmPinTitle;

  /// No description provided for @securityConfirmPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-enter the same PIN to confirm.'**
  String get securityConfirmPinSubtitle;

  /// No description provided for @securityPinMismatchError.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match. Please try again.'**
  String get securityPinMismatchError;

  /// No description provided for @securityStartOverAction.
  ///
  /// In en, this message translates to:
  /// **'Start Over'**
  String get securityStartOverAction;

  /// No description provided for @securityRecoveryKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Your Offline Recovery Key'**
  String get securityRecoveryKeyTitle;

  /// No description provided for @securityNewRecoveryKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your New Recovery Key'**
  String get securityNewRecoveryKeyTitle;

  /// No description provided for @securityRecoveryKeyWriteDownBody.
  ///
  /// In en, this message translates to:
  /// **'Write this 8-character code on paper and keep it safely in your workshop diary. It is shown only once and is the only way to reset a forgotten PIN without losing data.'**
  String get securityRecoveryKeyWriteDownBody;

  /// No description provided for @securityRecoveryKeyConfirmedCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I have written down this Recovery Key in a safe place.'**
  String get securityRecoveryKeyConfirmedCheckbox;

  /// No description provided for @securityActivateAppLockAction.
  ///
  /// In en, this message translates to:
  /// **'Activate App Lock'**
  String get securityActivateAppLockAction;

  /// No description provided for @securityPinEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'App PIN enabled successfully.'**
  String get securityPinEnabledSuccess;

  /// No description provided for @securityPinChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'App PIN updated successfully.'**
  String get securityPinChangedSuccess;

  /// No description provided for @securityPinDisabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'App PIN disabled.'**
  String get securityPinDisabledSuccess;

  /// No description provided for @securityUnlockOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock & Privacy Options'**
  String get securityUnlockOptionsTitle;

  /// No description provided for @securityEnableBiometricLabel.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint / Biometric Unlock'**
  String get securityEnableBiometricLabel;

  /// No description provided for @securityEnableBiometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock StitchFlow quickly with your phone\'s fingerprint or biometric sensor. PIN always remains available.'**
  String get securityEnableBiometricSubtitle;

  /// No description provided for @securityBiometricNotEnrolledHint.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint or biometric is set up in Android Settings yet.'**
  String get securityBiometricNotEnrolledHint;

  /// No description provided for @securityBiometricNoHardwareHint.
  ///
  /// In en, this message translates to:
  /// **'This device does not support biometric hardware.'**
  String get securityBiometricNoHardwareHint;

  /// No description provided for @securityBiometricUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is currently unavailable on this device.'**
  String get securityBiometricUnavailableHint;

  /// No description provided for @securityScreenshotProtectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Block Screenshots & App Preview'**
  String get securityScreenshotProtectionLabel;

  /// No description provided for @securityScreenshotProtectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hides workshop data in Android Recent Apps and blocks screenshots while enabled.'**
  String get securityScreenshotProtectionSubtitle;

  /// No description provided for @securityAutoLockTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-Lock Timeout'**
  String get securityAutoLockTimeoutTitle;

  /// No description provided for @securityAutoLockTimeoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically lock StitchFlow after switching apps or staying idle.'**
  String get securityAutoLockTimeoutSubtitle;

  /// No description provided for @securityTimeoutImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get securityTimeoutImmediate;

  /// No description provided for @securityTimeout30s.
  ///
  /// In en, this message translates to:
  /// **'30 sec'**
  String get securityTimeout30s;

  /// No description provided for @securityTimeout1m.
  ///
  /// In en, this message translates to:
  /// **'1 min'**
  String get securityTimeout1m;

  /// No description provided for @securityTimeout5m.
  ///
  /// In en, this message translates to:
  /// **'5 min'**
  String get securityTimeout5m;

  /// No description provided for @securityTimeout15m.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get securityTimeout15m;

  /// No description provided for @securityLockScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'StitchFlow Locked'**
  String get securityLockScreenTitle;

  /// No description provided for @securityLockScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to access workshop records.'**
  String get securityLockScreenSubtitle;

  /// No description provided for @securityWrongPinError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please try again.'**
  String get securityWrongPinError;

  /// No description provided for @securityLockoutCountdown.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {remaining}.'**
  String securityLockoutCountdown(String remaining);

  /// No description provided for @securityUseBiometricAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Biometrics'**
  String get securityUseBiometricAction;

  /// No description provided for @securityBiometricPromptReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock StitchFlow workshop records'**
  String get securityBiometricPromptReason;

  /// No description provided for @securityBiometricLockoutFallback.
  ///
  /// In en, this message translates to:
  /// **'Biometrics temporarily locked by device. Enter your PIN instead.'**
  String get securityBiometricLockoutFallback;

  /// No description provided for @securityBiometricUnavailableFallback.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock unavailable. Enter your PIN.'**
  String get securityBiometricUnavailableFallback;

  /// No description provided for @securityBiometricFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'Biometric check did not match. Enter your PIN.'**
  String get securityBiometricFailedFallback;

  /// No description provided for @securityForgotPinAction.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get securityForgotPinAction;

  /// No description provided for @securityRecoveryHeading.
  ///
  /// In en, this message translates to:
  /// **'PIN Recovery'**
  String get securityRecoveryHeading;

  /// No description provided for @securityRecoveryEnterKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Offline Recovery Key'**
  String get securityRecoveryEnterKeyTitle;

  /// No description provided for @securityRecoveryEnterKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-character Recovery Key you wrote down when setting up your PIN.'**
  String get securityRecoveryEnterKeySubtitle;

  /// No description provided for @securityRecoveryKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery Key'**
  String get securityRecoveryKeyLabel;

  /// No description provided for @securityVerifyRecoveryKeyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify Recovery Key'**
  String get securityVerifyRecoveryKeyAction;

  /// No description provided for @securityRecoveryKeyInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Invalid Recovery Key. Check your code and try again.'**
  String get securityRecoveryKeyInvalidError;

  /// No description provided for @securityCompleteRecoveryAction.
  ///
  /// In en, this message translates to:
  /// **'Save New PIN & Unlock'**
  String get securityCompleteRecoveryAction;

  /// No description provided for @securityLostBothTitle.
  ///
  /// In en, this message translates to:
  /// **'Lost Both PIN and Recovery Key?'**
  String get securityLostBothTitle;

  /// No description provided for @securityLostBothBody.
  ///
  /// In en, this message translates to:
  /// **'For your privacy, StitchFlow never silently bypasses App Lock. If you have a saved StitchFlow .zip backup, you can clear app data or reinstall and restore your backup.'**
  String get securityLostBothBody;

  /// No description provided for @securityVerifyCurrentPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Current PIN'**
  String get securityVerifyCurrentPinTitle;

  /// No description provided for @securityVerifyChangePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your current PIN before choosing a new PIN.'**
  String get securityVerifyChangePinSubtitle;

  /// No description provided for @securityVerifyDisablePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your current PIN before disabling App Lock.'**
  String get securityVerifyDisablePinSubtitle;

  /// No description provided for @securityVerifyRecoveryRegenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your current PIN to generate a new Recovery Key.'**
  String get securityVerifyRecoveryRegenSubtitle;

  /// No description provided for @securityReauthRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get securityReauthRequiredTitle;

  /// No description provided for @securityReauthRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your PIN or fingerprint before restoring a backup.'**
  String get securityReauthRestoreSubtitle;

  /// No description provided for @securityReauthRawSqliteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your PIN or fingerprint before exporting the raw SQLite database.'**
  String get securityReauthRawSqliteSubtitle;

  /// No description provided for @securityPrivacyNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'How Local App Lock Works'**
  String get securityPrivacyNoteTitle;

  /// No description provided for @securityPrivacyNoteBody.
  ///
  /// In en, this message translates to:
  /// **'• Your PIN is stored only as a salted PBKDF2-HMAC-SHA256 hash inside Android Keystore secure storage — never in plain text, logs, SQLite, or backup ZIPs.\n• App Lock prevents casual unauthorized access on your phone; it does not encrypt the local SQLite database file on disk. Keep Android screen lock enabled and store exported backups safely.'**
  String get securityPrivacyNoteBody;

  /// No description provided for @dashboardTodayHeading.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Workshop'**
  String get dashboardTodayHeading;

  /// No description provided for @dashboardDailySummaryAction.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dashboardDailySummaryAction;

  /// No description provided for @dashboardTodayIssuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Issued Today'**
  String get dashboardTodayIssuedLabel;

  /// No description provided for @dashboardTodayReturnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Returned Good Today'**
  String get dashboardTodayReturnedLabel;

  /// No description provided for @dashboardTodayLabourLabel.
  ///
  /// In en, this message translates to:
  /// **'Labour Earned Today'**
  String get dashboardTodayLabourLabel;

  /// No description provided for @dashboardTodayPaymentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payments Today'**
  String get dashboardTodayPaymentsLabel;

  /// No description provided for @dashboardTodayDamagedLostAlert.
  ///
  /// In en, this message translates to:
  /// **'Damaged / Lost Today'**
  String get dashboardTodayDamagedLostAlert;

  /// No description provided for @dashboardImportantPendingHeading.
  ///
  /// In en, this message translates to:
  /// **'Important Pending Work'**
  String get dashboardImportantPendingHeading;

  /// No description provided for @dashboardViewAllPendingAction.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get dashboardViewAllPendingAction;

  /// No description provided for @dailySummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'Daily Production Summary'**
  String get dailySummaryHeading;

  /// No description provided for @dailySummaryPickDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Business Date (IST)'**
  String get dailySummaryPickDateLabel;

  /// No description provided for @dailySummaryDamagedLostLabel.
  ///
  /// In en, this message translates to:
  /// **'Damaged / Lost'**
  String get dailySummaryDamagedLostLabel;

  /// No description provided for @dailySummaryNoActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No Workshop Activity Recorded'**
  String get dailySummaryNoActivityTitle;

  /// No description provided for @dailySummaryNoActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No stock issues, returns, or payments were recorded for this IST date.'**
  String get dailySummaryNoActivitySubtitle;

  /// No description provided for @dailySummaryProcessActivityHeading.
  ///
  /// In en, this message translates to:
  /// **'Stage-Wise Activity'**
  String get dailySummaryProcessActivityHeading;

  /// No description provided for @dailySummaryWorkerActivityHeading.
  ///
  /// In en, this message translates to:
  /// **'Worker-Wise Activity'**
  String get dailySummaryWorkerActivityHeading;

  /// No description provided for @dailySummaryLivePendingNote.
  ///
  /// In en, this message translates to:
  /// **'Current Live Workshop Balances'**
  String get dailySummaryLivePendingNote;

  /// No description provided for @reportPresetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportPresetToday;

  /// No description provided for @reportPresetYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get reportPresetYesterday;

  /// No description provided for @pendingAgeDaysBadge.
  ///
  /// In en, this message translates to:
  /// **'{days}d pending'**
  String pendingAgeDaysBadge(int days);

  /// No description provided for @stockRecentStockSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recently Used In-Stock Colours'**
  String get stockRecentStockSuggestionsLabel;

  /// No description provided for @stockRecentWorkPairsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent Work Stage & Worker'**
  String get stockRecentWorkPairsLabel;

  /// No description provided for @stockUnusualConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Please Confirm Unusual Issue'**
  String get stockUnusualConfirmTitle;

  /// No description provided for @stockUnusualFullStockWarning.
  ///
  /// In en, this message translates to:
  /// **'You are issuing all {qty} available pieces (100% of remaining stock).'**
  String stockUnusualFullStockWarning(int qty);

  /// No description provided for @stockUnusualRateOverrideWarning.
  ///
  /// In en, this message translates to:
  /// **'Manual rate override is enabled for this issue.'**
  String get stockUnusualRateOverrideWarning;

  /// No description provided for @stockUnusualBackdatedWarning.
  ///
  /// In en, this message translates to:
  /// **'Transaction date is backdated by {days} days.'**
  String stockUnusualBackdatedWarning(int days);

  /// No description provided for @stockSortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get stockSortOldestFirst;

  /// No description provided for @stockSortHighestPending.
  ///
  /// In en, this message translates to:
  /// **'Highest Pending'**
  String get stockSortHighestPending;

  /// No description provided for @stockSortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get stockSortNewestFirst;

  /// No description provided for @stockShortcutHalf.
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get stockShortcutHalf;

  /// No description provided for @stockFillRemainingGood.
  ///
  /// In en, this message translates to:
  /// **'Fill Remaining Good'**
  String get stockFillRemainingGood;

  /// No description provided for @workerWorkOverviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Live Work & Balance Overview'**
  String get workerWorkOverviewHeading;

  /// No description provided for @workerOpenIssuesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'open issues'**
  String get workerOpenIssuesCountLabel;

  /// No description provided for @workerOpenIssuesHeading.
  ///
  /// In en, this message translates to:
  /// **'Open Pending Work'**
  String get workerOpenIssuesHeading;

  /// No description provided for @workerRecentPaymentsHeading.
  ///
  /// In en, this message translates to:
  /// **'Recent Payments'**
  String get workerRecentPaymentsHeading;

  /// No description provided for @reportPresetThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get reportPresetThisWeek;

  /// No description provided for @reportPresetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get reportPresetThisMonth;

  /// No description provided for @reportPresetPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Prev. Month'**
  String get reportPresetPreviousMonth;

  /// No description provided for @reportPresetAllTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get reportPresetAllTime;

  /// No description provided for @reportPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reportPresetCustom;

  /// No description provided for @reportCategoryDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Workshop'**
  String get reportCategoryDaily;

  /// No description provided for @reportCategoryWorkers.
  ///
  /// In en, this message translates to:
  /// **'Worker Performance'**
  String get reportCategoryWorkers;

  /// No description provided for @reportCategoryProcesses.
  ///
  /// In en, this message translates to:
  /// **'Work Stage Performance'**
  String get reportCategoryProcesses;

  /// No description provided for @reportCategoryInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get reportCategoryInventory;

  /// No description provided for @reportCategoryFinancial.
  ///
  /// In en, this message translates to:
  /// **'Labour & Financial'**
  String get reportCategoryFinancial;

  /// No description provided for @reportCategoryInsights.
  ///
  /// In en, this message translates to:
  /// **'Business Insights'**
  String get reportCategoryInsights;

  /// No description provided for @reportFiltersButton.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get reportFiltersButton;

  /// No description provided for @reportAllOption.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reportAllOption;

  /// No description provided for @reportIncludeReversedLabel.
  ///
  /// In en, this message translates to:
  /// **'Include Reversed Movements'**
  String get reportIncludeReversedLabel;

  /// No description provided for @reportInvSubSummary.
  ///
  /// In en, this message translates to:
  /// **'Stock Summary'**
  String get reportInvSubSummary;

  /// No description provided for @reportInvSubLots.
  ///
  /// In en, this message translates to:
  /// **'Lot-Wise'**
  String get reportInvSubLots;

  /// No description provided for @reportInvSubColours.
  ///
  /// In en, this message translates to:
  /// **'Design & Colour'**
  String get reportInvSubColours;

  /// No description provided for @reportInvSubHistory.
  ///
  /// In en, this message translates to:
  /// **'Movement History'**
  String get reportInvSubHistory;

  /// No description provided for @reportFinSubLabour.
  ///
  /// In en, this message translates to:
  /// **'Labour Earned'**
  String get reportFinSubLabour;

  /// No description provided for @reportFinSubSummary.
  ///
  /// In en, this message translates to:
  /// **'Worker Summary'**
  String get reportFinSubSummary;

  /// No description provided for @reportFinSubPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get reportFinSubPayments;

  /// No description provided for @reportRefStockValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference Stock Value'**
  String get reportRefStockValueLabel;

  /// No description provided for @reportRefStockValueNote.
  ///
  /// In en, this message translates to:
  /// **'Reference value from good stock × unit cost (not sales or profit).'**
  String get reportRefStockValueNote;

  /// No description provided for @reportLabourCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Labour Cost'**
  String get reportLabourCostLabel;

  /// No description provided for @reportCurrentStandingBadge.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get reportCurrentStandingBadge;

  /// No description provided for @reportPeriodFlowBadge.
  ///
  /// In en, this message translates to:
  /// **'Selected Period'**
  String get reportPeriodFlowBadge;

  /// No description provided for @reportAvgTurnaroundLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg. Completion Time'**
  String get reportAvgTurnaroundLabel;

  /// No description provided for @reportTurnaroundSampleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} settled issues'**
  String reportTurnaroundSampleCount(int count);

  /// No description provided for @reportDefectRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Defect / Loss Rate'**
  String get reportDefectRateLabel;

  /// No description provided for @reportWorkerProcessBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Stage-Wise Productivity'**
  String get reportWorkerProcessBreakdown;

  /// No description provided for @reportProcessWorkerContribution.
  ///
  /// In en, this message translates to:
  /// **'Worker Contributions'**
  String get reportProcessWorkerContribution;

  /// No description provided for @reportNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get reportNotAvailable;

  /// No description provided for @reportInsightsTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Production Trends'**
  String get reportInsightsTrendsTitle;

  /// No description provided for @reportInsightsWeeklyNote.
  ///
  /// In en, this message translates to:
  /// **'Grouped by IST week'**
  String get reportInsightsWeeklyNote;

  /// No description provided for @reportInsightsDailyNote.
  ///
  /// In en, this message translates to:
  /// **'Grouped by IST day'**
  String get reportInsightsDailyNote;

  /// No description provided for @reportInsightsComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Period-over-Period Comparison'**
  String get reportInsightsComparisonTitle;

  /// No description provided for @reportInsightsNoPriorData.
  ///
  /// In en, this message translates to:
  /// **'No prior data'**
  String get reportInsightsNoPriorData;

  /// No description provided for @reportInsightsBottlenecksTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Stage Bottlenecks'**
  String get reportInsightsBottlenecksTitle;

  /// No description provided for @reportInsightsNoBottlenecks.
  ///
  /// In en, this message translates to:
  /// **'All work stages are clear — no pending bottlenecks.'**
  String get reportInsightsNoBottlenecks;

  /// No description provided for @reportInsightsWorkerTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Worker Productivity'**
  String get reportInsightsWorkerTrendsTitle;

  /// No description provided for @reportInsightsDefectReasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Damaged / Lost Reasons'**
  String get reportInsightsDefectReasonsTitle;

  /// No description provided for @reportInsightsLabourShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Labour Cost by Work Stage'**
  String get reportInsightsLabourShareTitle;

  /// No description provided for @reportExportAction.
  ///
  /// In en, this message translates to:
  /// **'Export / Print'**
  String get reportExportAction;

  /// No description provided for @reportExportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Export & Print Report'**
  String get reportExportSheetTitle;

  /// No description provided for @reportExportPrintPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Print / Save as PDF'**
  String get reportExportPrintPdfTitle;

  /// No description provided for @reportExportPrintPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gujarati-accurate A4 layout via Android Print dialog.'**
  String get reportExportPrintPdfSubtitle;

  /// No description provided for @reportExportExcelTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Excel (.xlsx)'**
  String get reportExportExcelTitle;

  /// No description provided for @reportExportExcelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share current report sheet to WhatsApp, Drive, or Files.'**
  String get reportExportExcelSubtitle;

  /// No description provided for @reportExportFullWorkbookTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Excel Workbook (.xlsx)'**
  String get reportExportFullWorkbookTitle;

  /// No description provided for @reportExportFullWorkbookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All sheets: Daily, Workers, Work Stages, Inventory, Labour & Payments.'**
  String get reportExportFullWorkbookSubtitle;

  /// No description provided for @reportExportCsvTitle.
  ///
  /// In en, this message translates to:
  /// **'Export CSV (UTF-8)'**
  String get reportExportCsvTitle;

  /// No description provided for @reportExportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fast Gujarati-compatible CSV for Excel & large datasets.'**
  String get reportExportCsvSubtitle;

  /// No description provided for @reportExportLargeNotice.
  ///
  /// In en, this message translates to:
  /// **'This view has {rows} rows. Excel or CSV export is recommended over multi-page PDF printing.'**
  String reportExportLargeNotice(int rows);

  /// No description provided for @reportExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report exported: {name}'**
  String reportExportSuccess(String name);

  /// No description provided for @reportExportPrintOpened.
  ///
  /// In en, this message translates to:
  /// **'Android Print / PDF dialog opened.'**
  String get reportExportPrintOpened;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Reminders'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline reminders for pending work, karigar settlements, daily recap, and backups.'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @notificationsHeading.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Reminders'**
  String get notificationsHeading;

  /// No description provided for @notificationsStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationsStatusTitle;

  /// No description provided for @notificationsPermGranted.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get notificationsPermGranted;

  /// No description provided for @notificationsPermNeeded.
  ///
  /// In en, this message translates to:
  /// **'Permission Needed'**
  String get notificationsPermNeeded;

  /// No description provided for @notificationsPermBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked in Settings'**
  String get notificationsPermBlocked;

  /// No description provided for @notificationsPermUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Android Only'**
  String get notificationsPermUnsupported;

  /// No description provided for @notificationsStatusGrantedDesc.
  ///
  /// In en, this message translates to:
  /// **'Local offline reminders are active on this device. No internet or cloud push is used.'**
  String get notificationsStatusGrantedDesc;

  /// No description provided for @notificationsStatusNeededDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so StitchFlow can remind you locally about pending returns, settlements, and backups.'**
  String get notificationsStatusNeededDesc;

  /// No description provided for @notificationsStatusBlockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off in Android Settings. Open Phone Settings -> Apps -> StitchFlow -> Notifications to re-enable.'**
  String get notificationsStatusBlockedDesc;

  /// No description provided for @notificationsAllowAction.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get notificationsAllowAction;

  /// No description provided for @notificationsSendTestAction.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get notificationsSendTestAction;

  /// No description provided for @notificationsTestTitle.
  ///
  /// In en, this message translates to:
  /// **'StitchFlow Reminder Check'**
  String get notificationsTestTitle;

  /// No description provided for @notificationsTestBody.
  ///
  /// In en, this message translates to:
  /// **'Local workshop notifications are working properly.'**
  String get notificationsTestBody;

  /// No description provided for @notificationsTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent.'**
  String get notificationsTestSent;

  /// No description provided for @notificationsMasterToggle.
  ///
  /// In en, this message translates to:
  /// **'Enable Local Reminders'**
  String get notificationsMasterToggle;

  /// No description provided for @notificationsMasterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Master switch for all scheduled offline reminders.'**
  String get notificationsMasterSubtitle;

  /// No description provided for @notificationsPendingWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Work Reminder'**
  String get notificationsPendingWorkTitle;

  /// No description provided for @notificationsPendingWorkDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminds you daily if open karigar issues stay pending beyond your chosen age.'**
  String get notificationsPendingWorkDesc;

  /// No description provided for @notificationsPendingDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Alert when pending at least'**
  String get notificationsPendingDaysLabel;

  /// No description provided for @notificationsSettlementTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker Settlement Reminder'**
  String get notificationsSettlementTitle;

  /// No description provided for @notificationsSettlementDesc.
  ///
  /// In en, this message translates to:
  /// **'Weekly Saturday reminder when karigars have outstanding payable balances.'**
  String get notificationsSettlementDesc;

  /// No description provided for @notificationsMinAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum payable balance'**
  String get notificationsMinAmountLabel;

  /// No description provided for @notificationsDailySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Workshop Summary'**
  String get notificationsDailySummaryTitle;

  /// No description provided for @notificationsDailySummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Evening reminder to review today\'s issued, returned, and labour recap.'**
  String get notificationsDailySummaryDesc;

  /// No description provided for @notificationsSkipQuietDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Skip if no activity today'**
  String get notificationsSkipQuietDaysLabel;

  /// No description provided for @notificationsBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Backup Reminder'**
  String get notificationsBackupTitle;

  /// No description provided for @notificationsBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminds you periodically to save a fresh StitchFlow .zip backup.'**
  String get notificationsBackupDesc;

  /// No description provided for @notificationsBackupIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Remind every'**
  String get notificationsBackupIntervalLabel;

  /// No description provided for @notificationsAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Important Local Business Alerts'**
  String get notificationsAlertsTitle;

  /// No description provided for @notificationsAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Local alerts when damaged stock crosses 20 pcs or an issue is 14+ days overdue (max 1 per 24h).'**
  String get notificationsAlertsDesc;

  /// No description provided for @notificationsTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get notificationsTimeLabel;

  /// No description provided for @notificationsPrivacyOemTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Privacy & Battery Note'**
  String get notificationsPrivacyOemTitle;

  /// No description provided for @notificationsPrivacyOemBody.
  ///
  /// In en, this message translates to:
  /// **'• 100% offline: reminders run locally on your Android phone without Firebase or internet.\n• Lock-screen privacy: when App PIN is enabled, notifications hide exact Rupee amounts and worker names.\n• Android battery note: on OPPO (ColorOS), Xiaomi, Vivo, or Samsung phones, allow StitchFlow background notifications in Phone Settings if reminders arrive late after a reboot.'**
  String get notificationsPrivacyOemBody;

  /// No description provided for @validationWhitespaceOnly.
  ///
  /// In en, this message translates to:
  /// **'This field cannot contain only spaces.'**
  String get validationWhitespaceOnly;

  /// No description provided for @validationMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} characters allowed.'**
  String validationMaxLength(int max);

  /// No description provided for @validationTextTooLong.
  ///
  /// In en, this message translates to:
  /// **'Entered text exceeds the allowed length.'**
  String get validationTextTooLong;

  /// No description provided for @validationMobileRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter mobile number.'**
  String get validationMobileRequired;

  /// No description provided for @validationMobileInvalidIndian.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number.'**
  String get validationMobileInvalidIndian;

  /// No description provided for @validationMobileInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Mobile number contains invalid characters.'**
  String get validationMobileInvalidChars;

  /// No description provided for @validationMobileInvalidInternational.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid international mobile number with country code.'**
  String get validationMobileInvalidInternational;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationEmailInvalid;

  /// No description provided for @validationInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get validationInvalidNumber;

  /// No description provided for @validationInvalidInteger.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid whole number.'**
  String get validationInvalidInteger;

  /// No description provided for @validationInvalidDecimal.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid decimal number.'**
  String get validationInvalidDecimal;

  /// No description provided for @validationTooManyDecimals.
  ///
  /// In en, this message translates to:
  /// **'Enter up to {maxDecimals} decimal places.'**
  String validationTooManyDecimals(int maxDecimals);

  /// No description provided for @validationNegativeNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Value cannot be negative.'**
  String get validationNegativeNotAllowed;

  /// No description provided for @validationPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number greater than 0.'**
  String get validationPositiveNumber;

  /// No description provided for @validationValueTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Entered value exceeds the maximum allowed limit.'**
  String get validationValueTooLarge;

  /// No description provided for @validationNonNegativeInt.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number 0 or greater.'**
  String get validationNonNegativeInt;

  /// No description provided for @validationQuantityExceedsMax.
  ///
  /// In en, this message translates to:
  /// **'Quantity cannot exceed {max}.'**
  String validationQuantityExceedsMax(int max);

  /// No description provided for @validationPositiveAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than 0.'**
  String get validationPositiveAmount;

  /// No description provided for @validationInvalidPercentage.
  ///
  /// In en, this message translates to:
  /// **'Enter a percentage between 0 and 100.'**
  String get validationInvalidPercentage;

  /// No description provided for @validationInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Select a valid date.'**
  String get validationInvalidDate;

  /// No description provided for @validationDateRangeOrder.
  ///
  /// In en, this message translates to:
  /// **'End date cannot be earlier than start date.'**
  String get validationDateRangeOrder;

  /// No description provided for @validationDuplicateValue.
  ///
  /// In en, this message translates to:
  /// **'This value already exists.'**
  String get validationDuplicateValue;

  /// No description provided for @validationInvalidHexColor.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid hex colour code (e.g. #172B4D).'**
  String get validationInvalidHexColor;

  /// No description provided for @validationInvalidPin.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 4- or 6-digit numeric PIN.'**
  String get validationInvalidPin;

  /// No description provided for @validationRecoveryKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your 8-character Recovery Key.'**
  String get validationRecoveryKeyRequired;

  /// No description provided for @validationQuantityBelowCommittedStock.
  ///
  /// In en, this message translates to:
  /// **'Initial quantity cannot be less than stock already issued, damaged, or settled.'**
  String get validationQuantityBelowCommittedStock;

  /// No description provided for @validationWorkerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Selected worker was not found.'**
  String get validationWorkerNotFound;

  /// No description provided for @validationWorkerNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Selected worker is not actively assigned to this work stage.'**
  String get validationWorkerNotAssigned;

  /// No description provided for @validationRecordNotFound.
  ///
  /// In en, this message translates to:
  /// **'Referenced record was not found or is no longer active.'**
  String get validationRecordNotFound;

  /// No description provided for @validationOverrideReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason is required when overriding the rate.'**
  String get validationOverrideReasonRequired;

  /// No description provided for @validationParentIssueInactive.
  ///
  /// In en, this message translates to:
  /// **'Original stock issue is no longer active.'**
  String get validationParentIssueInactive;

  /// No description provided for @validationAlreadyReversed.
  ///
  /// In en, this message translates to:
  /// **'This entry has already been reversed.'**
  String get validationAlreadyReversed;

  /// No description provided for @validationCannotReverseReversal.
  ///
  /// In en, this message translates to:
  /// **'A reversal entry cannot itself be reversed.'**
  String get validationCannotReverseReversal;

  /// No description provided for @validationMinLength.
  ///
  /// In en, this message translates to:
  /// **'Must be at least {min} characters.'**
  String validationMinLength(int min);

  /// No description provided for @validationExceedsDispatched.
  ///
  /// In en, this message translates to:
  /// **'Received quantity cannot exceed dispatched quantity.'**
  String get validationExceedsDispatched;

  /// No description provided for @validationExceedsHeld.
  ///
  /// In en, this message translates to:
  /// **'Transfer quantity cannot exceed quantity currently held by the worker.'**
  String get validationExceedsHeld;

  /// No description provided for @validationUnaccountedRemaining.
  ///
  /// In en, this message translates to:
  /// **'Work Stage cannot be completed while pending quantity remains unaccounted.'**
  String get validationUnaccountedRemaining;

  /// No description provided for @validationOverpaymentNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Payment amount cannot exceed the remaining payable balance.'**
  String get validationOverpaymentNotAllowed;

  /// No description provided for @msgTitleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get msgTitleSuccess;

  /// No description provided for @msgTitleError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get msgTitleError;

  /// No description provided for @msgTitleWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get msgTitleWarning;

  /// No description provided for @msgTitleInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get msgTitleInfo;

  /// No description provided for @msgTitleLoading.
  ///
  /// In en, this message translates to:
  /// **'Working...'**
  String get msgTitleLoading;

  /// No description provided for @navPressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get navPressBackAgainToExit;

  /// No description provided for @navProductionHistory.
  ///
  /// In en, this message translates to:
  /// **'Production History'**
  String get navProductionHistory;

  /// No description provided for @navInspectionQueue.
  ///
  /// In en, this message translates to:
  /// **'QC Inspection Queue'**
  String get navInspectionQueue;

  /// No description provided for @navWorkerHistory.
  ///
  /// In en, this message translates to:
  /// **'Worker Production'**
  String get navWorkerHistory;

  /// No description provided for @navProcessHistory.
  ///
  /// In en, this message translates to:
  /// **'Work Stage History'**
  String get navProcessHistory;

  /// No description provided for @prodHistoryDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Production History'**
  String get prodHistoryDashboardTitle;

  /// No description provided for @prodHistoryDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanent lot, worker, work stage & financial ledger tracking'**
  String get prodHistoryDashboardSubtitle;

  /// No description provided for @prodHistorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search lot, worker, work stage, design, colour...'**
  String get prodHistorySearchHint;

  /// No description provided for @prodHistoryOnlyPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Only'**
  String get prodHistoryOnlyPending;

  /// No description provided for @prodHistoryAllEntries.
  ///
  /// In en, this message translates to:
  /// **'All Entries'**
  String get prodHistoryAllEntries;

  /// No description provided for @prodHistoryTotalAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get prodHistoryTotalAssigned;

  /// No description provided for @prodHistoryTotalAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get prodHistoryTotalAccepted;

  /// No description provided for @prodHistoryTotalRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get prodHistoryTotalRejected;

  /// No description provided for @prodHistoryPendingInspection.
  ///
  /// In en, this message translates to:
  /// **'Pending Inspection'**
  String get prodHistoryPendingInspection;

  /// No description provided for @prodHistoryOutstandingWork.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get prodHistoryOutstandingWork;

  /// No description provided for @prodHistoryTotalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get prodHistoryTotalEarned;

  /// No description provided for @prodHistoryTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get prodHistoryTotalPaid;

  /// No description provided for @prodHistoryOutstandingPayable.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Payable'**
  String get prodHistoryOutstandingPayable;

  /// No description provided for @prodHistoryLotHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Lot History'**
  String get prodHistoryLotHistoryTitle;

  /// No description provided for @prodHistoryLotTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Lot Timeline'**
  String get prodHistoryLotTimelineTitle;

  /// No description provided for @prodHistoryViewLotHistory.
  ///
  /// In en, this message translates to:
  /// **'Lot History'**
  String get prodHistoryViewLotHistory;

  /// No description provided for @prodHistoryViewTimeline.
  ///
  /// In en, this message translates to:
  /// **'Lot Timeline'**
  String get prodHistoryViewTimeline;

  /// No description provided for @prodHistoryWorkerHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker Production History'**
  String get prodHistoryWorkerHistoryTitle;

  /// No description provided for @prodHistoryWorkerLotHistory.
  ///
  /// In en, this message translates to:
  /// **'Worker Lot History'**
  String get prodHistoryWorkerLotHistory;

  /// No description provided for @prodHistoryWorkerProcessHistory.
  ///
  /// In en, this message translates to:
  /// **'Stage-Wise History'**
  String get prodHistoryWorkerProcessHistory;

  /// No description provided for @prodHistoryIncludeInactive.
  ///
  /// In en, this message translates to:
  /// **'Show Inactive'**
  String get prodHistoryIncludeInactive;

  /// No description provided for @prodHistoryProcessHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Stage-Wise History'**
  String get prodHistoryProcessHistoryTitle;

  /// No description provided for @prodHistoryProcessDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Stage Production Details'**
  String get prodHistoryProcessDetailsTitle;

  /// No description provided for @prodHistoryTabLotWise.
  ///
  /// In en, this message translates to:
  /// **'Lot-Wise'**
  String get prodHistoryTabLotWise;

  /// No description provided for @prodHistoryTabWorkerWise.
  ///
  /// In en, this message translates to:
  /// **'Worker-Wise'**
  String get prodHistoryTabWorkerWise;

  /// No description provided for @prodHistoryTabDateWise.
  ///
  /// In en, this message translates to:
  /// **'Date-Wise'**
  String get prodHistoryTabDateWise;

  /// No description provided for @prodHistoryTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Work'**
  String get prodHistoryTabPending;

  /// No description provided for @prodHistoryInspectionQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Returns & QC Inspection'**
  String get prodHistoryInspectionQueueTitle;

  /// No description provided for @prodHistoryTabPendingInspection.
  ///
  /// In en, this message translates to:
  /// **'Pending QC'**
  String get prodHistoryTabPendingInspection;

  /// No description provided for @prodHistoryTabRejections.
  ///
  /// In en, this message translates to:
  /// **'Rejections & Repairs'**
  String get prodHistoryTabRejections;

  /// No description provided for @prodHistoryApproveAction.
  ///
  /// In en, this message translates to:
  /// **'Inspect & Approve'**
  String get prodHistoryApproveAction;

  /// No description provided for @prodHistoryRecordRepairAction.
  ///
  /// In en, this message translates to:
  /// **'Log Repair'**
  String get prodHistoryRecordRepairAction;

  /// No description provided for @prodHistoryReinspectAction.
  ///
  /// In en, this message translates to:
  /// **'Re-Inspect & Approve'**
  String get prodHistoryReinspectAction;

  /// No description provided for @prodHistoryRepairSourceOriginal.
  ///
  /// In en, this message translates to:
  /// **'Repaired by Original Worker (Credits Historical Rate)'**
  String get prodHistoryRepairSourceOriginal;

  /// No description provided for @prodHistoryRepairSourceInHouse.
  ///
  /// In en, this message translates to:
  /// **'Factory / In-House Repair (No Worker Earning)'**
  String get prodHistoryRepairSourceInHouse;

  /// No description provided for @prodHistoryReturnModePending.
  ///
  /// In en, this message translates to:
  /// **'Log as Pending Inspection (₹0 until QC approves)'**
  String get prodHistoryReturnModePending;

  /// No description provided for @prodHistoryReturnModeImmediate.
  ///
  /// In en, this message translates to:
  /// **'Return & Inspect Immediately (Generates Accepted Earnings)'**
  String get prodHistoryReturnModeImmediate;

  /// No description provided for @prodHistoryTxDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get prodHistoryTxDetailTitle;

  /// No description provided for @prodHistoryOpenLot.
  ///
  /// In en, this message translates to:
  /// **'Open Lot'**
  String get prodHistoryOpenLot;

  /// No description provided for @prodHistoryOpenWorker.
  ///
  /// In en, this message translates to:
  /// **'Open Worker'**
  String get prodHistoryOpenWorker;

  /// No description provided for @prodHistoryOpenProcess.
  ///
  /// In en, this message translates to:
  /// **'Open Work Stage'**
  String get prodHistoryOpenProcess;

  /// No description provided for @prodHistoryLockedRateSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Locked Rate Snapshot'**
  String get prodHistoryLockedRateSnapshot;

  /// No description provided for @prodHistoryAuditTrail.
  ///
  /// In en, this message translates to:
  /// **'Audit Trail'**
  String get prodHistoryAuditTrail;

  /// No description provided for @prodHistoryRelatedRecords.
  ///
  /// In en, this message translates to:
  /// **'Linked Transactions'**
  String get prodHistoryRelatedRecords;

  /// No description provided for @prodHistoryInitialAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Initial Work Stage Assignments (Optional)'**
  String get prodHistoryInitialAssignmentsTitle;

  /// No description provided for @prodHistoryInitialAssignmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optionally assign work stages, workers, quantities & locked rates while creating the lot.'**
  String get prodHistoryInitialAssignmentsSubtitle;

  /// No description provided for @prodHistoryAddAssignmentAction.
  ///
  /// In en, this message translates to:
  /// **'Add Assignment'**
  String get prodHistoryAddAssignmentAction;

  /// No description provided for @prodHistoryApprovalAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorize Approval'**
  String get prodHistoryApprovalAuthTitle;

  /// No description provided for @prodHistoryApprovalAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify PIN or biometrics to approve accepted quantities and credit worker earnings.'**
  String get prodHistoryApprovalAuthSubtitle;

  /// No description provided for @securityRequireApprovalAuthLabel.
  ///
  /// In en, this message translates to:
  /// **'Require PIN for Return Approvals'**
  String get securityRequireApprovalAuthLabel;

  /// No description provided for @securityRequireApprovalAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prompt for PIN/biometrics when approving returned or repaired quantities.'**
  String get securityRequireApprovalAuthSubtitle;

  /// No description provided for @settingsFinalPaymentRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Finalized Earnings Rule (Active)'**
  String get settingsFinalPaymentRuleTitle;

  /// No description provided for @settingsFinalPaymentRuleBody.
  ///
  /// In en, this message translates to:
  /// **'Worker earnings are calculated strictly as Accepted Quantity × Historical Assigned Rate. Legacy GIVEN_QTY and Damaged-in-Labour settings are retired for all new transactions while historical records remain preserved.'**
  String get settingsFinalPaymentRuleBody;

  /// No description provided for @validationExceedsPendingInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspected quantity exceeds remaining pending inspection quantity.'**
  String get validationExceedsPendingInspection;

  /// No description provided for @validationExceedsReturnedQty.
  ///
  /// In en, this message translates to:
  /// **'Accepted + Rejected cannot exceed returned quantity.'**
  String get validationExceedsReturnedQty;

  /// No description provided for @validationExceedsRejectedQty.
  ///
  /// In en, this message translates to:
  /// **'Quantity cannot exceed open rejected quantity.'**
  String get validationExceedsRejectedQty;

  /// No description provided for @validationExceedsRepairedQty.
  ///
  /// In en, this message translates to:
  /// **'Re-inspected quantity cannot exceed pending repaired quantity.'**
  String get validationExceedsRepairedQty;

  /// No description provided for @validationLotUnreconciled.
  ///
  /// In en, this message translates to:
  /// **'Cannot mark lot completed while pieces are still with workers or pending QC inspection.'**
  String get validationLotUnreconciled;

  /// No description provided for @navDesignsColours.
  ///
  /// In en, this message translates to:
  /// **'Designs & Colours'**
  String get navDesignsColours;

  /// No description provided for @designsColoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search designs, manage saved colours & view historical lot prices'**
  String get designsColoursSubtitle;

  /// No description provided for @designsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Designs'**
  String get designsTabLabel;

  /// No description provided for @coloursTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Colour Catalog'**
  String get coloursTabLabel;

  /// No description provided for @colourHexLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex Code (e.g. #DC2626)'**
  String get colourHexLabel;

  /// No description provided for @colourSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Colour saved to catalog.'**
  String get colourSavedSuccess;

  /// No description provided for @coloursEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Saved Colours Yet'**
  String get coloursEmptyTitle;

  /// No description provided for @coloursEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add reusable workshop colours with swatches for faster lot creation.'**
  String get coloursEmptySubtitle;

  /// No description provided for @historicalPricePreservedNote.
  ///
  /// In en, this message translates to:
  /// **'Historical lot prices stay locked to each lot and are never overwritten.'**
  String get historicalPricePreservedNote;

  /// Action label on a success message that reverses the last change.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get uxUndo;

  /// Button that reveals more rows in a long list section.
  ///
  /// In en, this message translates to:
  /// **'Show {count} more'**
  String uxShowMore(int count);

  /// Button that collapses an expanded list section.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get uxShowLess;

  /// Title of the dialog shown when leaving a form with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get uxUnsavedTitle;

  /// Body of the unsaved-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'You have changes that are not saved. If you leave now they will be lost.'**
  String get uxUnsavedMessage;

  /// Confirm button that leaves the form and drops unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get uxUnsavedDiscard;

  /// Cancel button that stays on the form.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get uxUnsavedKeepEditing;

  /// Tooltip on the global search button.
  ///
  /// In en, this message translates to:
  /// **'Search (Ctrl+K)'**
  String get uxSearchTooltip;

  /// Hint in the global search box.
  ///
  /// In en, this message translates to:
  /// **'Search lots, workers, work stages…'**
  String get uxSearchHint;

  /// Section title for lot results.
  ///
  /// In en, this message translates to:
  /// **'Lots'**
  String get uxSearchLots;

  /// Section title for worker results.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get uxSearchWorkers;

  /// Section title for work stage results.
  ///
  /// In en, this message translates to:
  /// **'Work Stages'**
  String get uxSearchProcesses;

  /// Shown when global search finds nothing.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String uxSearchNoResults(String query);

  /// Title of the quick actions group.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get uxQuickActions;

  /// Quick action: create a lot.
  ///
  /// In en, this message translates to:
  /// **'New lot'**
  String get uxActionNewLot;

  /// Quick action: issue stock.
  ///
  /// In en, this message translates to:
  /// **'Issue stock to worker'**
  String get uxActionIssueStock;

  /// Quick action: receive returned work.
  ///
  /// In en, this message translates to:
  /// **'Receive work back'**
  String get uxActionReceiveWork;

  /// Quick action: record a worker payment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get uxActionRecordPayment;

  /// Quick action: add a worker.
  ///
  /// In en, this message translates to:
  /// **'Add worker'**
  String get uxActionAddWorker;

  /// Quick action: open the inspection queue.
  ///
  /// In en, this message translates to:
  /// **'Inspection queue'**
  String get uxActionInspections;

  /// Rows-per-page option in paged tables.
  ///
  /// In en, this message translates to:
  /// **'{count} / page'**
  String uxPerPage(int count);

  /// Button that opens the filter panel on phones.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get uxFilters;

  /// Filter button label when some filters are set.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count})'**
  String uxFiltersActive(int count);

  /// Expandable group of secondary screen links on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'More screens'**
  String get uxMoreScreens;

  /// No description provided for @authSignInHeading.
  ///
  /// In en, this message translates to:
  /// **'Sign In to Cloud Sync'**
  String get authSignInHeading;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google or your mobile number to sync your workshop data across devices. Works 100% offline anytime.'**
  String get authSignInSubtitle;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone Number'**
  String get authContinueWithPhone;

  /// No description provided for @authContinueOffline.
  ///
  /// In en, this message translates to:
  /// **'Continue Offline (Local Only)'**
  String get authContinueOffline;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+91 98765 43210'**
  String get authPhoneHint;

  /// No description provided for @authSendOtpAction.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get authSendOtpAction;

  /// No description provided for @authOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-Digit OTP Code'**
  String get authOtpLabel;

  /// No description provided for @authOtpHint.
  ///
  /// In en, this message translates to:
  /// **'123456'**
  String get authOtpHint;

  /// No description provided for @authOtpSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to {phone}'**
  String authOtpSentMessage(String phone);

  /// No description provided for @authVerifyOtpAction.
  ///
  /// In en, this message translates to:
  /// **'Verify & Sign In'**
  String get authVerifyOtpAction;

  /// No description provided for @authChangePhoneAction.
  ///
  /// In en, this message translates to:
  /// **'Change Number'**
  String get authChangePhoneAction;

  /// No description provided for @authInvalidPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number or E.164 number.'**
  String get authInvalidPhoneError;

  /// No description provided for @authCloudNotConfiguredBanner.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync keys are not configured in this build. You can continue using StitchFlow 100% offline.'**
  String get authCloudNotConfiguredBanner;

  /// No description provided for @authAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & Cloud Sync'**
  String get authAccountTitle;

  /// No description provided for @authOfflineModeBadge.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get authOfflineModeBadge;

  /// No description provided for @authSignedInBadge.
  ///
  /// In en, this message translates to:
  /// **'Signed In'**
  String get authSignedInBadge;

  /// No description provided for @authSignInPromptCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google or Phone OTP to back up and sync across devices'**
  String get authSignInPromptCardSubtitle;

  /// No description provided for @authLinkedIdentitiesHeading.
  ///
  /// In en, this message translates to:
  /// **'Linked Login Methods'**
  String get authLinkedIdentitiesHeading;

  /// No description provided for @authGoogleProvider.
  ///
  /// In en, this message translates to:
  /// **'Google Account'**
  String get authGoogleProvider;

  /// No description provided for @authPhoneProvider.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhoneProvider;

  /// No description provided for @authLinkedStatus.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get authLinkedStatus;

  /// No description provided for @authNotLinkedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get authNotLinkedStatus;

  /// No description provided for @authLinkAction.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get authLinkAction;

  /// No description provided for @authLinkedDevicesHeading.
  ///
  /// In en, this message translates to:
  /// **'Synced Devices'**
  String get authLinkedDevicesHeading;

  /// No description provided for @authCurrentDeviceBadge.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get authCurrentDeviceBadge;

  /// No description provided for @authNoDevicesYet.
  ///
  /// In en, this message translates to:
  /// **'No cloud devices registered yet.'**
  String get authNoDevicesYet;

  /// No description provided for @authSignOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get authSignOutAction;

  /// No description provided for @authSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Cloud Sync?'**
  String get authSignOutConfirmTitle;

  /// No description provided for @authSignOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your local workshop data stays safely on this device, and cloud sync will pause until you sign in again.'**
  String get authSignOutConfirmBody;

  /// No description provided for @authSignOutUnsyncedWarning.
  ///
  /// In en, this message translates to:
  /// **'You have {count} unsynced local changes. Sync before signing out so nothing is left behind.'**
  String authSignOutUnsyncedWarning(int count);

  /// No description provided for @authSyncAndSignOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sync & Sign Out'**
  String get authSyncAndSignOutAction;

  /// No description provided for @authSignOutAnywayAction.
  ///
  /// In en, this message translates to:
  /// **'Sign Out Anyway'**
  String get authSignOutAnywayAction;

  /// No description provided for @syncCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync Center'**
  String get syncCenterTitle;

  /// No description provided for @syncCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline-first bidirectional sync with Supabase'**
  String get syncCenterSubtitle;

  /// No description provided for @syncStatusLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Local Only'**
  String get syncStatusLocalOnly;

  /// No description provided for @syncStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncStatusOffline;

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get syncStatusNeedsAttention;

  /// No description provided for @syncNowAction.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNowAction;

  /// No description provided for @syncRetryFailedAction.
  ///
  /// In en, this message translates to:
  /// **'Retry Failed'**
  String get syncRetryFailedAction;

  /// No description provided for @syncLastSyncedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last synced'**
  String get syncLastSyncedLabel;

  /// No description provided for @syncNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncNeverSynced;

  /// No description provided for @syncPendingRowsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending data changes'**
  String get syncPendingRowsLabel;

  /// No description provided for @syncPendingMediaLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending photo uploads/downloads'**
  String get syncPendingMediaLabel;

  /// No description provided for @syncFailedItemsHeading.
  ///
  /// In en, this message translates to:
  /// **'Items Needing Retry'**
  String get syncFailedItemsHeading;

  /// No description provided for @syncMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Found in Both Places'**
  String get syncMergeTitle;

  /// No description provided for @syncMergeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This device has {localCount} local records and your cloud account has {cloudCount} records. How would you like to proceed?'**
  String syncMergeSubtitle(int localCount, int cloudCount);

  /// No description provided for @syncMergeBothAction.
  ///
  /// In en, this message translates to:
  /// **'Merge Local + Cloud (Recommended)'**
  String get syncMergeBothAction;

  /// No description provided for @syncMergeBothDesc.
  ///
  /// In en, this message translates to:
  /// **'Combines all ledgers safely and keeps the newest edits for lots, workers, and work stages.'**
  String get syncMergeBothDesc;

  /// No description provided for @syncKeepCloudAction.
  ///
  /// In en, this message translates to:
  /// **'Keep Cloud Only'**
  String get syncKeepCloudAction;

  /// No description provided for @syncKeepCloudDesc.
  ///
  /// In en, this message translates to:
  /// **'Replaces this device\'s local records with your cloud account data.'**
  String get syncKeepCloudDesc;

  /// No description provided for @syncKeepLocalAction.
  ///
  /// In en, this message translates to:
  /// **'Keep Local & Push to Cloud'**
  String get syncKeepLocalAction;

  /// No description provided for @syncKeepLocalDesc.
  ///
  /// In en, this message translates to:
  /// **'Uploads all local records from this device to your cloud account.'**
  String get syncKeepLocalDesc;

  /// No description provided for @securityCloudRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Or Reset PIN via Cloud Account'**
  String get securityCloudRecoveryTitle;

  /// No description provided for @securityCloudRecoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-verify your signed-in Google account to reset your local App Lock PIN without losing data.'**
  String get securityCloudRecoverySubtitle;

  /// No description provided for @securityVerifyWithGoogleAction.
  ///
  /// In en, this message translates to:
  /// **'Verify with Google'**
  String get securityVerifyWithGoogleAction;

  /// No description provided for @securityCloudReauthFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud account verification did not match the signed-in owner.'**
  String get securityCloudReauthFailed;

  /// No description provided for @stockPendingQcLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending QC'**
  String get stockPendingQcLabel;

  /// No description provided for @settingsDataHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Health & Diagnostics'**
  String get settingsDataHealthTitle;

  /// No description provided for @settingsDataHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify SQLite integrity, stock equations, ledger parity & sync queue'**
  String get settingsDataHealthSubtitle;

  /// No description provided for @dataHealthHeading.
  ///
  /// In en, this message translates to:
  /// **'Data Health Center'**
  String get dataHealthHeading;

  /// No description provided for @dataHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Non-destructive integrity & reconciliation checks on your local StitchFlow database.'**
  String get dataHealthSubtitle;

  /// No description provided for @dataHealthRunCheckAction.
  ///
  /// In en, this message translates to:
  /// **'Run Health Check'**
  String get dataHealthRunCheckAction;

  /// No description provided for @dataHealthShareReportAction.
  ///
  /// In en, this message translates to:
  /// **'Share Diagnostic Report'**
  String get dataHealthShareReportAction;

  /// No description provided for @dataHealthStatusHealthy.
  ///
  /// In en, this message translates to:
  /// **'All Checks Healthy'**
  String get dataHealthStatusHealthy;

  /// No description provided for @dataHealthStatusWarning.
  ///
  /// In en, this message translates to:
  /// **'Minor Attention Needed'**
  String get dataHealthStatusWarning;

  /// No description provided for @dataHealthStatusCritical.
  ///
  /// In en, this message translates to:
  /// **'Integrity Issues Found'**
  String get dataHealthStatusCritical;

  /// No description provided for @dataHealthCheckedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Checked'**
  String get dataHealthCheckedAtLabel;

  /// No description provided for @dataHealthDbSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Database Size'**
  String get dataHealthDbSizeLabel;

  /// No description provided for @dataHealthSqliteIntegrityLabel.
  ///
  /// In en, this message translates to:
  /// **'SQLite Integrity'**
  String get dataHealthSqliteIntegrityLabel;

  /// No description provided for @dataHealthSqliteOk.
  ///
  /// In en, this message translates to:
  /// **'Verified OK'**
  String get dataHealthSqliteOk;

  /// No description provided for @dataHealthSqliteFailed.
  ///
  /// In en, this message translates to:
  /// **'Integrity Error'**
  String get dataHealthSqliteFailed;

  /// No description provided for @dataHealthForeignKeysLabel.
  ///
  /// In en, this message translates to:
  /// **'Foreign Key Integrity'**
  String get dataHealthForeignKeysLabel;

  /// No description provided for @dataHealthZeroViolations.
  ///
  /// In en, this message translates to:
  /// **'0 Violations'**
  String get dataHealthZeroViolations;

  /// No description provided for @dataHealthViolationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Violations'**
  String dataHealthViolationsCount(int count);

  /// No description provided for @dataHealthStockReconciliationLabel.
  ///
  /// In en, this message translates to:
  /// **'Golden Stock Equation'**
  String get dataHealthStockReconciliationLabel;

  /// No description provided for @dataHealthStockAllReconciled.
  ///
  /// In en, this message translates to:
  /// **'All {count} colours reconciled'**
  String dataHealthStockAllReconciled(int count);

  /// No description provided for @dataHealthStockIssuesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} mismatches found'**
  String dataHealthStockIssuesCount(int count);

  /// No description provided for @dataHealthLedgerParityLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker Ledger Parity'**
  String get dataHealthLedgerParityLabel;

  /// No description provided for @dataHealthLedgerParityOk.
  ///
  /// In en, this message translates to:
  /// **'0 Parity Issues'**
  String get dataHealthLedgerParityOk;

  /// No description provided for @dataHealthSyncQueueLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync Outbox & Media Queue'**
  String get dataHealthSyncQueueLabel;

  /// No description provided for @dataHealthSyncQueueSummary.
  ///
  /// In en, this message translates to:
  /// **'{pending} pending • {failed} failed'**
  String dataHealthSyncQueueSummary(int pending, int failed);

  /// No description provided for @dataHealthMediaParityLabel.
  ///
  /// In en, this message translates to:
  /// **'Private Media Parity'**
  String get dataHealthMediaParityLabel;

  /// No description provided for @dataHealthMediaParitySummary.
  ///
  /// In en, this message translates to:
  /// **'{orphans} orphan • {missing} missing'**
  String dataHealthMediaParitySummary(int orphans, int missing);

  /// No description provided for @dataHealthMaintenanceHeading.
  ///
  /// In en, this message translates to:
  /// **'Safe Audited Maintenance'**
  String get dataHealthMaintenanceHeading;

  /// No description provided for @dataHealthWalCheckpointAction.
  ///
  /// In en, this message translates to:
  /// **'Run WAL Checkpoint'**
  String get dataHealthWalCheckpointAction;

  /// No description provided for @dataHealthWalCheckpointDesc.
  ///
  /// In en, this message translates to:
  /// **'Flushes SQLite write-ahead log cleanly into the main database file.'**
  String get dataHealthWalCheckpointDesc;

  /// No description provided for @dataHealthWalCheckpointSuccess.
  ///
  /// In en, this message translates to:
  /// **'WAL checkpoint completed and logged.'**
  String get dataHealthWalCheckpointSuccess;

  /// No description provided for @dataHealthCleanOrphansAction.
  ///
  /// In en, this message translates to:
  /// **'Clean Orphan Media Files'**
  String get dataHealthCleanOrphansAction;

  /// No description provided for @dataHealthCleanOrphansDesc.
  ///
  /// In en, this message translates to:
  /// **'Removes unreferenced local photo files without touching active attachments.'**
  String get dataHealthCleanOrphansDesc;

  /// No description provided for @dataHealthCleanOrphansSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cleaned {count} orphan media file(s).'**
  String dataHealthCleanOrphansSuccess(int count);

  /// No description provided for @dataHealthRetrySyncAction.
  ///
  /// In en, this message translates to:
  /// **'Reset Failed Sync Entries'**
  String get dataHealthRetrySyncAction;

  /// No description provided for @dataHealthRetrySyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Re-queues failed sync outbox & media entries for immediate retry.'**
  String get dataHealthRetrySyncDesc;

  /// No description provided for @dataHealthRetrySyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Re-queued {count} failed sync entry(ies).'**
  String dataHealthRetrySyncSuccess(int count);

  /// No description provided for @routingTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Stage Routing'**
  String get routingTitle;

  /// No description provided for @routingRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get routingRefreshTooltip;

  /// No description provided for @routingLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load Job Routing'**
  String get routingLoadErrorTitle;

  /// No description provided for @routingAddProcessAction.
  ///
  /// In en, this message translates to:
  /// **'Add Work Stage'**
  String get routingAddProcessAction;

  /// No description provided for @routingReassignFromFactoryAction.
  ///
  /// In en, this message translates to:
  /// **'Reassign from Factory'**
  String get routingReassignFromFactoryAction;

  /// No description provided for @routingAddOperationTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Work Stage to Lot'**
  String get routingAddOperationTitle;

  /// No description provided for @routingVariantLabel.
  ///
  /// In en, this message translates to:
  /// **'Variant (Design / Colour)'**
  String get routingVariantLabel;

  /// No description provided for @routingOperationLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Stage'**
  String get routingOperationLabel;

  /// No description provided for @routingAssignWorkerLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign Worker / Department'**
  String get routingAssignWorkerLabel;

  /// No description provided for @routingPricingUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Pricing Unit'**
  String get routingPricingUnitLabel;

  /// No description provided for @routingRateOverrideReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for Changing Default Rate (Required)'**
  String get routingRateOverrideReasonLabel;

  /// No description provided for @routingDispatchImmediatelyTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispatch immediately from Factory'**
  String get routingDispatchImmediatelyTitle;

  /// No description provided for @routingDispatchImmediatelySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off to save as Pending and dispatch later'**
  String get routingDispatchImmediatelySubtitle;

  /// No description provided for @routingNotesOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get routingNotesOptionalLabel;

  /// No description provided for @routingConfirmReassignmentAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reassignment'**
  String get routingConfirmReassignmentAction;

  /// No description provided for @routingAddDispatchAction.
  ///
  /// In en, this message translates to:
  /// **'Add & Dispatch Work Stage'**
  String get routingAddDispatchAction;

  /// No description provided for @routingSavePendingAction.
  ///
  /// In en, this message translates to:
  /// **'Save Pending Work Stage'**
  String get routingSavePendingAction;

  /// No description provided for @routingAddColourFirstError.
  ///
  /// In en, this message translates to:
  /// **'Add at least one Colour or Design variant to this Lot first.'**
  String get routingAddColourFirstError;

  /// No description provided for @routingAddProcessWorkerFirstError.
  ///
  /// In en, this message translates to:
  /// **'Please create at least one active Work Stage and Worker first.'**
  String get routingAddProcessWorkerFirstError;

  /// No description provided for @routingInvalidQuantityError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive whole quantity.'**
  String get routingInvalidQuantityError;

  /// No description provided for @routingInvalidRateError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid non-negative rate (max 2 decimals).'**
  String get routingInvalidRateError;

  /// No description provided for @routingOperationAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation added successfully.'**
  String get routingOperationAddedSuccess;

  /// No description provided for @routingDirectTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Worker-to-Worker Transfer'**
  String get routingDirectTransferTitle;

  /// No description provided for @routingNextOperationLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Work Stage'**
  String get routingNextOperationLabel;

  /// No description provided for @routingDestinationWorkerLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination Worker / Department'**
  String get routingDestinationWorkerLabel;

  /// No description provided for @routingMarkReceivedImmediatelyTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark received immediately'**
  String get routingMarkReceivedImmediatelyTitle;

  /// No description provided for @routingTransferNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer Notes (Optional)'**
  String get routingTransferNotesLabel;

  /// No description provided for @routingConfirmDirectTransferAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Direct Transfer'**
  String get routingConfirmDirectTransferAction;

  /// No description provided for @routingInvalidTransferQtyError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive transfer quantity.'**
  String get routingInvalidTransferQtyError;

  /// No description provided for @routingInvalidDestRateError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid destination rate (max 2 decimals).'**
  String get routingInvalidDestRateError;

  /// No description provided for @routingReturnToFactoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Return to Factory'**
  String get routingReturnToFactoryTitle;

  /// No description provided for @routingGoodReturnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Good Quantity Returned to Factory'**
  String get routingGoodReturnedLabel;

  /// No description provided for @routingDamagedOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Damaged Quantity (Optional)'**
  String get routingDamagedOptionalLabel;

  /// No description provided for @routingVerificationNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification Notes (Optional)'**
  String get routingVerificationNotesLabel;

  /// No description provided for @routingConfirmFactoryReturnAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Factory Return'**
  String get routingConfirmFactoryReturnAction;

  /// No description provided for @routingAddChargeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Extra Charge / Deduction'**
  String get routingAddChargeTitle;

  /// No description provided for @routingChargeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get routingChargeTypeLabel;

  /// No description provided for @routingChargeDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (e.g. Urgent work, Special cutting)'**
  String get routingChargeDescLabel;

  /// No description provided for @routingInvalidAmountError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive amount (max 2 decimals).'**
  String get routingInvalidAmountError;

  /// No description provided for @routingConfirmReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Material Receipt'**
  String get routingConfirmReceiptTitle;

  /// No description provided for @routingConfirmReceiptAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Receipt'**
  String get routingConfirmReceiptAction;

  /// No description provided for @routingInvalidReceivedQtyError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive received quantity.'**
  String get routingInvalidReceivedQtyError;

  /// No description provided for @routingCancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason'**
  String get routingCancelReasonLabel;

  /// No description provided for @routingKeepAction.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get routingKeepAction;

  /// No description provided for @routingCancelProcessAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Work Stage'**
  String get routingCancelProcessAction;

  /// No description provided for @routingFactoryReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Factory Ready'**
  String get routingFactoryReadyLabel;

  /// No description provided for @routingWithWorkersLabel.
  ///
  /// In en, this message translates to:
  /// **'With Workers'**
  String get routingWithWorkersLabel;

  /// No description provided for @routingTotalProductionCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Production Cost'**
  String get routingTotalProductionCostLabel;

  /// No description provided for @routingOutstandingPayableLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Payable'**
  String get routingOutstandingPayableLabel;

  /// No description provided for @routingWorkerPayableSummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'Worker Payable Summary'**
  String get routingWorkerPayableSummaryHeading;

  /// No description provided for @routingCurrentGoodsLocationHeading.
  ///
  /// In en, this message translates to:
  /// **'Current Goods Location'**
  String get routingCurrentGoodsLocationHeading;

  /// No description provided for @routingNoOperationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Operations Added Yet'**
  String get routingNoOperationsTitle;

  /// No description provided for @routingNoOperationsForColourTitle.
  ///
  /// In en, this message translates to:
  /// **'No Operations for Selected Colour'**
  String get routingNoOperationsForColourTitle;

  /// No description provided for @routingNoOperationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Cutting, Stitching, Checking, Finishing, Ironing, or Packing at variant level with custom worker rates.'**
  String get routingNoOperationsSubtitle;

  /// No description provided for @routingNoHandoversSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dispatches, direct transfers, returns, and reassignments will appear here chronologically.'**
  String get routingNoHandoversSubtitle;

  /// No description provided for @routingUnassignedWorker.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get routingUnassignedWorker;

  /// No description provided for @routingDirectTransferAction.
  ///
  /// In en, this message translates to:
  /// **'Direct Transfer'**
  String get routingDirectTransferAction;

  /// No description provided for @routingReturnToFactoryAction.
  ///
  /// In en, this message translates to:
  /// **'Return to Factory'**
  String get routingReturnToFactoryAction;

  /// No description provided for @routingPayAction.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get routingPayAction;

  /// No description provided for @routingMarkCompletedAction.
  ///
  /// In en, this message translates to:
  /// **'Mark Completed'**
  String get routingMarkCompletedAction;

  /// No description provided for @routingCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get routingCancelAction;

  /// No description provided for @routingErrJobNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job / Lot not found.'**
  String get routingErrJobNotFound;

  /// No description provided for @routingErrNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get routingErrNotReady;

  /// No description provided for @routingErrExceedsFactoryStock.
  ///
  /// In en, this message translates to:
  /// **'Quantity exceeds available in-house factory stock.'**
  String get routingErrExceedsFactoryStock;

  /// No description provided for @routingErrExceedsDispatched.
  ///
  /// In en, this message translates to:
  /// **'Received quantity cannot exceed dispatched quantity.'**
  String get routingErrExceedsDispatched;

  /// No description provided for @routingErrExceedsWorkerStock.
  ///
  /// In en, this message translates to:
  /// **'Transfer quantity exceeds stock currently held by this worker.'**
  String get routingErrExceedsWorkerStock;

  /// No description provided for @routingErrExceedsReturnable.
  ///
  /// In en, this message translates to:
  /// **'Return quantity exceeds outstanding worker quantity.'**
  String get routingErrExceedsReturnable;

  /// No description provided for @routingErrPendingRemaining.
  ///
  /// In en, this message translates to:
  /// **'Cannot complete work stage while pending quantity remains unaccounted.'**
  String get routingErrPendingRemaining;

  /// No description provided for @routingErrHeldPiecesCancel.
  ///
  /// In en, this message translates to:
  /// **'Return or transfer all held pieces before cancelling this work stage.'**
  String get routingErrHeldPiecesCancel;

  /// No description provided for @routingErrSameWorkerProcess.
  ///
  /// In en, this message translates to:
  /// **'Select a different destination worker or operation for direct transfer.'**
  String get routingErrSameWorkerProcess;

  /// No description provided for @routingErrRateOverrideReason.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason when changing the agreed rate from the default.'**
  String get routingErrRateOverrideReason;

  /// No description provided for @routingErrPaymentExceedsPayable.
  ///
  /// In en, this message translates to:
  /// **'Payment amount cannot exceed remaining outstanding payable.'**
  String get routingErrPaymentExceedsPayable;

  /// No description provided for @routingErrDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a charge description.'**
  String get routingErrDescriptionRequired;

  /// No description provided for @routingErrReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason.'**
  String get routingErrReasonRequired;

  /// No description provided for @routingErrProcessRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a work stage.'**
  String get routingErrProcessRequired;

  /// No description provided for @routingErrWorkerRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a worker.'**
  String get routingErrWorkerRequired;

  /// No description provided for @routingErrSkuRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a design & colour.'**
  String get routingErrSkuRequired;

  /// No description provided for @routingErrAlreadyClosed.
  ///
  /// In en, this message translates to:
  /// **'This operation is already closed.'**
  String get routingErrAlreadyClosed;

  /// No description provided for @slipShareSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Karigar Slip'**
  String get slipShareSheetTitle;

  /// No description provided for @slipShareChallanAction.
  ///
  /// In en, this message translates to:
  /// **'Share Issue Challan'**
  String get slipShareChallanAction;

  /// No description provided for @slipShareReturnAction.
  ///
  /// In en, this message translates to:
  /// **'Share Return / QC Slip'**
  String get slipShareReturnAction;

  /// No description provided for @slipShareKhataAction.
  ///
  /// In en, this message translates to:
  /// **'Share Khata Statement'**
  String get slipShareKhataAction;

  /// No description provided for @slipShareImageAction.
  ///
  /// In en, this message translates to:
  /// **'Share Image (PNG)'**
  String get slipShareImageAction;

  /// No description provided for @slipShareTextAction.
  ///
  /// In en, this message translates to:
  /// **'Share Text (WhatsApp)'**
  String get slipShareTextAction;

  /// No description provided for @slipCopyTextAction.
  ///
  /// In en, this message translates to:
  /// **'Copy Text'**
  String get slipCopyTextAction;

  /// No description provided for @slipPrintPdfAction.
  ///
  /// In en, this message translates to:
  /// **'Print / Save PDF'**
  String get slipPrintPdfAction;

  /// No description provided for @slipLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Slip Language'**
  String get slipLanguageLabel;

  /// No description provided for @slipCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Slip text copied to clipboard.'**
  String get slipCopiedMessage;

  /// No description provided for @slipGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Slip ready to share.'**
  String get slipGeneratedSuccess;

  /// No description provided for @draftRestoredBanner.
  ///
  /// In en, this message translates to:
  /// **'Unfinished draft restored.'**
  String get draftRestoredBanner;

  /// No description provided for @draftClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear Draft'**
  String get draftClearAction;

  /// No description provided for @setupChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Workshop Setup Checklist'**
  String get setupChecklistTitle;

  /// No description provided for @setupChecklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete these 4 quick steps to start tracking production.'**
  String get setupChecklistSubtitle;

  /// No description provided for @setupChecklistDismissAction.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get setupChecklistDismissAction;

  /// No description provided for @setupStepProfile.
  ///
  /// In en, this message translates to:
  /// **'Customize Business Profile'**
  String get setupStepProfile;

  /// No description provided for @setupStepProcesses.
  ///
  /// In en, this message translates to:
  /// **'Create Work Stages'**
  String get setupStepProcesses;

  /// No description provided for @setupStepWorkers.
  ///
  /// In en, this message translates to:
  /// **'Add Workers & Rates'**
  String get setupStepWorkers;

  /// No description provided for @setupStepFirstLot.
  ///
  /// In en, this message translates to:
  /// **'Create Your First Lot'**
  String get setupStepFirstLot;

  /// No description provided for @densitySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Layout Density'**
  String get densitySectionTitle;

  /// No description provided for @densityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable (Default)'**
  String get densityComfortable;

  /// No description provided for @densityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact (More Rows on Screen)'**
  String get densityCompact;

  /// No description provided for @settingsTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Team & Role Access'**
  String get settingsTeamTitle;

  /// No description provided for @settingsTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite supervisors, QC inspectors & accountants with role permissions'**
  String get settingsTeamSubtitle;

  /// No description provided for @teamHeading.
  ///
  /// In en, this message translates to:
  /// **'Team Management'**
  String get teamHeading;

  /// No description provided for @teamMembersSection.
  ///
  /// In en, this message translates to:
  /// **'Workspace Members'**
  String get teamMembersSection;

  /// No description provided for @teamInvitesSection.
  ///
  /// In en, this message translates to:
  /// **'Invite Codes'**
  String get teamInvitesSection;

  /// No description provided for @teamCreateInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Create Invite Code'**
  String get teamCreateInviteAction;

  /// No description provided for @teamJoinWorkspaceAction.
  ///
  /// In en, this message translates to:
  /// **'Join a Workshop via Code'**
  String get teamJoinWorkspaceAction;

  /// No description provided for @teamInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'8-Character Invite Code'**
  String get teamInviteCodeLabel;

  /// No description provided for @teamInviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. SF7K-9M2P'**
  String get teamInviteCodeHint;

  /// No description provided for @teamInvitePhoneOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Restrict to Phone (Optional)'**
  String get teamInvitePhoneOptionalLabel;

  /// No description provided for @teamInviteEmailOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Restrict to Email (Optional)'**
  String get teamInviteEmailOptionalLabel;

  /// No description provided for @teamShareInviteWhatsAppAction.
  ///
  /// In en, this message translates to:
  /// **'Share Code on WhatsApp'**
  String get teamShareInviteWhatsAppAction;

  /// No description provided for @teamRevokeAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get teamRevokeAction;

  /// No description provided for @teamRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get teamRoleOwner;

  /// No description provided for @teamRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager / Supervisor'**
  String get teamRoleManager;

  /// No description provided for @teamRoleQcInspector.
  ///
  /// In en, this message translates to:
  /// **'QC Inspector'**
  String get teamRoleQcInspector;

  /// No description provided for @teamRoleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get teamRoleAccountant;

  /// No description provided for @teamSignInRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Cloud Sync to invite team members or join another workshop.'**
  String get teamSignInRequiredSubtitle;

  /// No description provided for @teamNoInvitesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active invite codes yet.'**
  String get teamNoInvitesEmpty;

  /// No description provided for @teamJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined workshop successfully.'**
  String get teamJoinSuccess;

  /// No description provided for @teamInviteCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invite code created and ready to share.'**
  String get teamInviteCreatedSuccess;

  /// No description provided for @syncConflictsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflict Inspector'**
  String get syncConflictsTitle;

  /// No description provided for @syncConflictsOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Review Conflicts'**
  String get syncConflictsOpenAction;

  /// No description provided for @syncConflictsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Sync Conflicts'**
  String get syncConflictsEmptyTitle;

  /// No description provided for @syncConflictsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All devices and team edits have merged cleanly.'**
  String get syncConflictsEmptySubtitle;

  /// No description provided for @syncConflictLocalLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Superseded Edit'**
  String get syncConflictLocalLabel;

  /// No description provided for @syncConflictCloudLabel.
  ///
  /// In en, this message translates to:
  /// **'Applied Cloud Version'**
  String get syncConflictCloudLabel;

  /// No description provided for @syncConflictKeepCloudAction.
  ///
  /// In en, this message translates to:
  /// **'Keep Cloud'**
  String get syncConflictKeepCloudAction;

  /// No description provided for @syncConflictRestoreLocalAction.
  ///
  /// In en, this message translates to:
  /// **'Restore My Edit'**
  String get syncConflictRestoreLocalAction;

  /// No description provided for @syncConflictStatusUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Needs Review'**
  String get syncConflictStatusUnresolved;

  /// No description provided for @syncConflictStatusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Kept Cloud'**
  String get syncConflictStatusAcknowledged;

  /// No description provided for @syncConflictStatusRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get syncConflictStatusRestored;

  /// No description provided for @syncConflictRestoredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Superseded edit restored as a new audited update.'**
  String get syncConflictRestoredSuccess;

  /// No description provided for @syncConflictAcknowledgedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Conflict marked as resolved.'**
  String get syncConflictAcknowledgedSuccess;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive Guide'**
  String get guideTitle;

  /// No description provided for @guideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Screen Guide & Training'**
  String get guideTooltip;

  /// No description provided for @guideWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Business Manager'**
  String get guideWelcomeTitle;

  /// No description provided for @guideWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn how your entire garment workshop works step by step — right inside the app, with voice guidance and zero videos.'**
  String get guideWelcomeSubtitle;

  /// No description provided for @guideStartFullTraining.
  ///
  /// In en, this message translates to:
  /// **'Start Complete Training'**
  String get guideStartFullTraining;

  /// No description provided for @guideResumeTraining.
  ///
  /// In en, this message translates to:
  /// **'Resume Training'**
  String get guideResumeTraining;

  /// No description provided for @guideRestartTraining.
  ///
  /// In en, this message translates to:
  /// **'Restart Full Training'**
  String get guideRestartTraining;

  /// No description provided for @guideTourThisScreen.
  ///
  /// In en, this message translates to:
  /// **'Explain This Screen'**
  String get guideTourThisScreen;

  /// No description provided for @guideOpenUserGuide.
  ///
  /// In en, this message translates to:
  /// **'Open Complete User Guide'**
  String get guideOpenUserGuide;

  /// No description provided for @guideSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get guideSkipForNow;

  /// No description provided for @guideVoiceOn.
  ///
  /// In en, this message translates to:
  /// **'Voice ON'**
  String get guideVoiceOn;

  /// No description provided for @guideVoiceOff.
  ///
  /// In en, this message translates to:
  /// **'Voice OFF'**
  String get guideVoiceOff;

  /// No description provided for @guideVoiceReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get guideVoiceReplay;

  /// No description provided for @guideVoiceListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get guideVoiceListen;

  /// No description provided for @guideVoiceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get guideVoiceStop;

  /// No description provided for @guideSpeedSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get guideSpeedSlow;

  /// No description provided for @guideSpeedNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get guideSpeedNormal;

  /// No description provided for @guideSpeedFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get guideSpeedFast;

  /// No description provided for @guideVoicePackMissingHint.
  ///
  /// In en, this message translates to:
  /// **'Gujarati voice pack is not installed on this device. Visual guidance continues normally.'**
  String get guideVoicePackMissingHint;

  /// No description provided for @guideStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String guideStepCounter(int current, int total);

  /// No description provided for @guideActionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get guideActionBack;

  /// No description provided for @guideActionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guideActionNext;

  /// No description provided for @guideActionFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get guideActionFinish;

  /// No description provided for @guideActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get guideActionSkip;

  /// No description provided for @guideMinimizeCoach.
  ///
  /// In en, this message translates to:
  /// **'Try Now'**
  String get guideMinimizeCoach;

  /// No description provided for @guideExpandSpotlight.
  ///
  /// In en, this message translates to:
  /// **'Spotlight'**
  String get guideExpandSpotlight;

  /// No description provided for @guideFirstVisitHint.
  ///
  /// In en, this message translates to:
  /// **'First time on this screen? Tap to see what every button does.'**
  String get guideFirstVisitHint;

  /// No description provided for @guideFirstVisitAction.
  ///
  /// In en, this message translates to:
  /// **'Show Guide'**
  String get guideFirstVisitAction;

  /// No description provided for @guideNewScreenHintsLabel.
  ///
  /// In en, this message translates to:
  /// **'First-visit tips on new screens'**
  String get guideNewScreenHintsLabel;

  /// No description provided for @guideTrainingTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Interactive Training'**
  String get guideTrainingTabLabel;

  /// No description provided for @guideTopicsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Complete Guide (19)'**
  String get guideTopicsTabLabel;

  /// No description provided for @guideProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} chapters completed'**
  String guideProgressSummary(int completed, int total);

  /// No description provided for @guideShowMeLive.
  ///
  /// In en, this message translates to:
  /// **'Show Me Live'**
  String get guideShowMeLive;

  /// No description provided for @guideShowMeOnScreen.
  ///
  /// In en, this message translates to:
  /// **'Show Me on Screen'**
  String get guideShowMeOnScreen;

  /// No description provided for @guideChapterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get guideChapterCompleted;

  /// No description provided for @guideNextTopicHeading.
  ///
  /// In en, this message translates to:
  /// **'What To Do Next'**
  String get guideNextTopicHeading;

  /// No description provided for @guideResetProgressAction.
  ///
  /// In en, this message translates to:
  /// **'Reset Training Progress'**
  String get guideResetProgressAction;

  /// No description provided for @guideResetProgressDone.
  ///
  /// In en, this message translates to:
  /// **'Training progress reset. You can start fresh anytime.'**
  String get guideResetProgressDone;

  /// No description provided for @lotDesignPriceHelper.
  ///
  /// In en, this message translates to:
  /// **'Design price: {price}'**
  String lotDesignPriceHelper(String price);

  /// No description provided for @lotStageDefaultRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Stage default rate: {price}'**
  String lotStageDefaultRateHelper(String price);

  /// No description provided for @accountingPayFullAction.
  ///
  /// In en, this message translates to:
  /// **'Pay full {amount}'**
  String accountingPayFullAction(String amount);

  /// No description provided for @accountingUndoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not undo the payment. Open the worker ledger to reverse it.'**
  String get accountingUndoFailed;

  /// No description provided for @lotNeedVariantStageWorker.
  ///
  /// In en, this message translates to:
  /// **'Add at least one colour variant, active work stage, and active worker first.'**
  String get lotNeedVariantStageWorker;

  /// No description provided for @lotDesignColourVariantLabel.
  ///
  /// In en, this message translates to:
  /// **'Design / Colour Variant'**
  String get lotDesignColourVariantLabel;

  /// No description provided for @lotQtyPcsLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty (pcs)'**
  String get lotQtyPcsLabel;

  /// No description provided for @lotLockedRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked Rate (₹/pc)'**
  String get lotLockedRateLabel;

  /// No description provided for @lotEnterPositiveQty.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive quantity.'**
  String get lotEnterPositiveQty;

  /// No description provided for @lotEnterValidRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid rate.'**
  String get lotEnterValidRate;

  /// No description provided for @lotDesignAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Design \"{a}\" is already added to this lot.'**
  String lotDesignAlreadyAdded(Object a);

  /// No description provided for @lotEnterDesignName.
  ///
  /// In en, this message translates to:
  /// **'Enter a design name.'**
  String get lotEnterDesignName;

  /// No description provided for @lotDesignNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Design name is too long.'**
  String get lotDesignNameTooLong;

  /// No description provided for @lotEnterValidDefaultPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid non-negative default price.'**
  String get lotEnterValidDefaultPrice;

  /// No description provided for @lotSelectColoursForDesign.
  ///
  /// In en, this message translates to:
  /// **'Select Colours — {a}'**
  String lotSelectColoursForDesign(Object a);

  /// No description provided for @lotSelectColoursColourOnly.
  ///
  /// In en, this message translates to:
  /// **'Select Colours (Colour-Only Lot)'**
  String get lotSelectColoursColourOnly;

  /// No description provided for @lotEnterPositiveQtyFor.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive quantity for {a}.'**
  String lotEnterPositiveQtyFor(Object a);

  /// No description provided for @lotEnterPositiveQtyForVariant.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive quantity for {a} — {b}.'**
  String lotEnterPositiveQtyForVariant(Object a, Object b);

  /// No description provided for @lotEnterValidPriceForVariant.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid non-negative unit price for {a} — {b}.'**
  String lotEnterValidPriceForVariant(Object a, Object b);

  /// No description provided for @lotEnterValidPriceFor.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid non-negative unit price for {a}.'**
  String lotEnterValidPriceFor(Object a);

  /// No description provided for @lotQtyExceedsMaxFor.
  ///
  /// In en, this message translates to:
  /// **'Quantity for {a} exceeds the maximum limit.'**
  String lotQtyExceedsMaxFor(Object a);

  /// No description provided for @lotCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Lot {a} created successfully.'**
  String lotCreatedSuccess(Object a);

  /// No description provided for @lotSummaryLive.
  ///
  /// In en, this message translates to:
  /// **'Lot Summary (Live)'**
  String get lotSummaryLive;

  /// No description provided for @lotColoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get lotColoursLabel;

  /// No description provided for @lotTotalQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Qty'**
  String get lotTotalQtyLabel;

  /// No description provided for @lotPiecesValue.
  ///
  /// In en, this message translates to:
  /// **'{a} pcs'**
  String lotPiecesValue(Object a);

  /// No description provided for @lotSkuValueLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU Value'**
  String get lotSkuValueLabel;

  /// No description provided for @lotSectionInfo.
  ///
  /// In en, this message translates to:
  /// **'1. Lot Information'**
  String get lotSectionInfo;

  /// No description provided for @lotSectionDesigns.
  ///
  /// In en, this message translates to:
  /// **'2. Designs, Colours & SKU Pricing'**
  String get lotSectionDesigns;

  /// No description provided for @lotSectionDesignsHelp.
  ///
  /// In en, this message translates to:
  /// **'Unit prices here are SKU reference prices (separate from worker labour rates). You can add designs, colours, quantities, and prices in one workflow.'**
  String get lotSectionDesignsHelp;

  /// No description provided for @lotModeWithDesigns.
  ///
  /// In en, this message translates to:
  /// **'With Design(s)'**
  String get lotModeWithDesigns;

  /// No description provided for @lotModeColourOnly.
  ///
  /// In en, this message translates to:
  /// **'Colour-Only (No Design)'**
  String get lotModeColourOnly;

  /// No description provided for @lotSelectExistingDesign.
  ///
  /// In en, this message translates to:
  /// **'Select Existing Design'**
  String get lotSelectExistingDesign;

  /// No description provided for @lotAddNewDesign.
  ///
  /// In en, this message translates to:
  /// **'Add New Design'**
  String get lotAddNewDesign;

  /// No description provided for @lotNewDesignInline.
  ///
  /// In en, this message translates to:
  /// **'New Design (Inline)'**
  String get lotNewDesignInline;

  /// No description provided for @lotDefaultUnitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Unit Price (₹ / pc, optional)'**
  String get lotDefaultUnitPriceLabel;

  /// No description provided for @lotAddDesignToLot.
  ///
  /// In en, this message translates to:
  /// **'Add Design to Lot'**
  String get lotAddDesignToLot;

  /// No description provided for @lotNoDesignsYet.
  ///
  /// In en, this message translates to:
  /// **'No designs added yet. Select an existing design or tap \"+ Add New Design\" above (or save an empty lot and add designs later).'**
  String get lotNoDesignsYet;

  /// No description provided for @lotColourVariantsCount.
  ///
  /// In en, this message translates to:
  /// **'Colour Variants ({a})'**
  String lotColourVariantsCount(Object a);

  /// No description provided for @lotAddColours.
  ///
  /// In en, this message translates to:
  /// **'Add Colours'**
  String get lotAddColours;

  /// No description provided for @lotAddColoursHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Colours\" to pick colours from the palette or create custom colours with quantity & price.'**
  String get lotAddColoursHelp;

  /// No description provided for @lotDefaultPriceValue.
  ///
  /// In en, this message translates to:
  /// **'Default: {a}'**
  String lotDefaultPriceValue(Object a);

  /// No description provided for @lotRemoveDesign.
  ///
  /// In en, this message translates to:
  /// **'Remove design'**
  String get lotRemoveDesign;

  /// No description provided for @lotRemoveColour.
  ///
  /// In en, this message translates to:
  /// **'Remove colour'**
  String get lotRemoveColour;

  /// No description provided for @lotUnitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Price (₹)'**
  String get lotUnitPriceLabel;

  /// No description provided for @lotColourDetailsFor.
  ///
  /// In en, this message translates to:
  /// **'{a} Details'**
  String lotColourDetailsFor(Object a);

  /// No description provided for @lotColourDetails.
  ///
  /// In en, this message translates to:
  /// **'Colour Details'**
  String get lotColourDetails;

  /// No description provided for @lotColourDetailsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load Colour Details'**
  String get lotColourDetailsLoadError;

  /// No description provided for @lotColourNotFound.
  ///
  /// In en, this message translates to:
  /// **'Colour Variant Not Found'**
  String get lotColourNotFound;

  /// No description provided for @lotColourNotFoundHelp.
  ///
  /// In en, this message translates to:
  /// **'This colour variant may have been removed from the lot.'**
  String get lotColourNotFoundHelp;

  /// No description provided for @lotHashDesign.
  ///
  /// In en, this message translates to:
  /// **'Lot #{a}  •  Design: {b}'**
  String lotHashDesign(Object a, Object b);

  /// No description provided for @lotQtyPcsValue.
  ///
  /// In en, this message translates to:
  /// **'Lot Qty: {a} pcs'**
  String lotQtyPcsValue(Object a);

  /// No description provided for @lotTotalAssignedPcs.
  ///
  /// In en, this message translates to:
  /// **'Total Assigned: {a} pcs'**
  String lotTotalAssignedPcs(Object a);

  /// No description provided for @lotUnitValue.
  ///
  /// In en, this message translates to:
  /// **'Unit Value: {a}'**
  String lotUnitValue(Object a);

  /// No description provided for @lotDamagedPcs.
  ///
  /// In en, this message translates to:
  /// **'Damaged: {a} pcs'**
  String lotDamagedPcs(Object a);

  /// No description provided for @lotManageStagesFor.
  ///
  /// In en, this message translates to:
  /// **'Manage Work Stages for {a}'**
  String lotManageStagesFor(Object a);

  /// No description provided for @lotAvailableFactory.
  ///
  /// In en, this message translates to:
  /// **'Available (Factory)'**
  String get lotAvailableFactory;

  /// No description provided for @lotPendingWorkers.
  ///
  /// In en, this message translates to:
  /// **'Pending (Workers)'**
  String get lotPendingWorkers;

  /// No description provided for @lotCompletedHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Completed / Handed Over'**
  String get lotCompletedHandedOver;

  /// No description provided for @lotStageBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Stage-wise Breakdown'**
  String get lotStageBreakdown;

  /// No description provided for @lotStageSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {a} pcs • Completed: {b} pcs • Pending: {c} pcs'**
  String lotStageSummaryLine(Object a, Object b, Object c);

  /// No description provided for @lotWorkerDistribution.
  ///
  /// In en, this message translates to:
  /// **'Worker-wise Distribution & Pricing'**
  String get lotWorkerDistribution;

  /// No description provided for @lotNoWorkersAssignedFor.
  ///
  /// In en, this message translates to:
  /// **'No workers have been assigned to {a} yet.'**
  String lotNoWorkersAssignedFor(Object a);

  /// No description provided for @lotAssignedPendingLine.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {a} pcs • Pending: {b} pcs'**
  String lotAssignedPendingLine(Object a, Object b);

  /// No description provided for @lotRatePayableLine.
  ///
  /// In en, this message translates to:
  /// **'Rate: {a} / {b} • Payable: {c}'**
  String lotRatePayableLine(Object a, Object b, Object c);

  /// No description provided for @lotColourCostSummary.
  ///
  /// In en, this message translates to:
  /// **'Colour Cost Summary'**
  String get lotColourCostSummary;

  /// No description provided for @lotBaseStageCost.
  ///
  /// In en, this message translates to:
  /// **'Base Work Stage Cost'**
  String get lotBaseStageCost;

  /// No description provided for @lotAdditionalCharges.
  ///
  /// In en, this message translates to:
  /// **'Additional Charges'**
  String get lotAdditionalCharges;

  /// No description provided for @lotDeductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get lotDeductions;

  /// No description provided for @lotPaidToWorkers.
  ///
  /// In en, this message translates to:
  /// **'Paid to Workers'**
  String get lotPaidToWorkers;

  /// No description provided for @lotMovementHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'Movement History ({a})'**
  String lotMovementHistoryCount(Object a);

  /// No description provided for @lotMovementHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Dispatches, direct transfers, and returns for {a} will appear here.'**
  String lotMovementHistoryEmpty(Object a);

  /// No description provided for @lotReceivedOfLine.
  ///
  /// In en, this message translates to:
  /// **'Received: {a}/{b} • {c}'**
  String lotReceivedOfLine(Object a, Object b, Object c);

  /// No description provided for @lotStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get lotStatusNotStarted;

  /// No description provided for @lotStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get lotStatusInProgress;

  /// No description provided for @lotStatusPendingCount.
  ///
  /// In en, this message translates to:
  /// **'Pending ({a})'**
  String lotStatusPendingCount(Object a);

  /// No description provided for @lotInitialColoursCount.
  ///
  /// In en, this message translates to:
  /// **'Initial Colours ({a})'**
  String lotInitialColoursCount(Object a);

  /// No description provided for @lotSelectInitialColours.
  ///
  /// In en, this message translates to:
  /// **'Select Initial Colours'**
  String get lotSelectInitialColours;

  /// No description provided for @lotSelectColoursNoDesign.
  ///
  /// In en, this message translates to:
  /// **'Select Colours (No Design)'**
  String get lotSelectColoursNoDesign;

  /// No description provided for @lotRoutingHandovers.
  ///
  /// In en, this message translates to:
  /// **'Work Stage Routing & Handovers'**
  String get lotRoutingHandovers;

  /// No description provided for @lotAddColourNoDesign.
  ///
  /// In en, this message translates to:
  /// **'Add Colour (No Design)'**
  String get lotAddColourNoDesign;

  /// No description provided for @lotDesignValue.
  ///
  /// In en, this message translates to:
  /// **'Design: {a}'**
  String lotDesignValue(Object a);

  /// No description provided for @lotTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get lotTotalLabel;

  /// No description provided for @lotDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get lotDoneLabel;

  /// No description provided for @lotAddCustomColour.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Colour'**
  String get lotAddCustomColour;

  /// No description provided for @lotEditColour.
  ///
  /// In en, this message translates to:
  /// **'Edit Colour'**
  String get lotEditColour;

  /// No description provided for @lotHexCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'HEX Code (e.g. #DC2626)'**
  String get lotHexCodeLabel;

  /// No description provided for @lotSaveColour.
  ///
  /// In en, this message translates to:
  /// **'Save Colour'**
  String get lotSaveColour;

  /// No description provided for @lotSearchColourHint.
  ///
  /// In en, this message translates to:
  /// **'Search colour name or HEX'**
  String get lotSearchColourHint;

  /// No description provided for @lotCustomColour.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get lotCustomColour;

  /// No description provided for @lotRecentlyUsed.
  ///
  /// In en, this message translates to:
  /// **'Recently Used'**
  String get lotRecentlyUsed;

  /// No description provided for @lotColourPaletteHelp.
  ///
  /// In en, this message translates to:
  /// **'Colour Palette (Tap to select, long-press to edit)'**
  String get lotColourPaletteHelp;

  /// No description provided for @lotSelectedColoursCount.
  ///
  /// In en, this message translates to:
  /// **'Selected Colours ({a})'**
  String lotSelectedColoursCount(Object a);

  /// No description provided for @lotSelectColoursAbove.
  ///
  /// In en, this message translates to:
  /// **'Select Colours Above'**
  String get lotSelectColoursAbove;

  /// No description provided for @lotAddColoursSummary.
  ///
  /// In en, this message translates to:
  /// **'Add {a} Colour(s) • {b} pcs'**
  String lotAddColoursSummary(Object a, Object b);

  /// No description provided for @lotInitialQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial Qty'**
  String get lotInitialQtyLabel;

  /// No description provided for @lotDesignsColoursBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Designs & Colours Breakdown'**
  String get lotDesignsColoursBreakdown;

  /// No description provided for @lotInHouseValue.
  ///
  /// In en, this message translates to:
  /// **'In-House: {a}'**
  String lotInHouseValue(Object a);

  /// No description provided for @lotWithWorkersValue.
  ///
  /// In en, this message translates to:
  /// **'With Workers: {a}'**
  String lotWithWorkersValue(Object a);

  /// No description provided for @lotPendingQcValue.
  ///
  /// In en, this message translates to:
  /// **'Pending QC: {a}'**
  String lotPendingQcValue(Object a);

  /// No description provided for @lotDamagedValue.
  ///
  /// In en, this message translates to:
  /// **'Damaged: {a}'**
  String lotDamagedValue(Object a);

  /// No description provided for @lotStageAssignmentsCount.
  ///
  /// In en, this message translates to:
  /// **'Work Stage Assignments & Worker Ledger ({a})'**
  String lotStageAssignmentsCount(Object a);

  /// No description provided for @lotNoStageAssignments.
  ///
  /// In en, this message translates to:
  /// **'No work stage assignments recorded for this lot yet.'**
  String get lotNoStageAssignments;

  /// No description provided for @lotRejectionRecordsCount.
  ///
  /// In en, this message translates to:
  /// **'Rejection & Repair Records ({a})'**
  String lotRejectionRecordsCount(Object a);

  /// No description provided for @lotRejectedLine.
  ///
  /// In en, this message translates to:
  /// **'Rejected: {a} • Re-Approved: {b} • Open: {c}'**
  String lotRejectedLine(Object a, Object b, Object c);

  /// No description provided for @lotReasonValue.
  ///
  /// In en, this message translates to:
  /// **'Reason: {a}'**
  String lotReasonValue(Object a);

  /// No description provided for @lotAssignedValue.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {a}'**
  String lotAssignedValue(Object a);

  /// No description provided for @lotReturnedValue.
  ///
  /// In en, this message translates to:
  /// **'Returned: {a}'**
  String lotReturnedValue(Object a);

  /// No description provided for @lotAcceptedValue.
  ///
  /// In en, this message translates to:
  /// **'Accepted: {a}'**
  String lotAcceptedValue(Object a);

  /// No description provided for @lotOutstandingValue.
  ///
  /// In en, this message translates to:
  /// **'Outstanding: {a}'**
  String lotOutstandingValue(Object a);

  /// No description provided for @lotRejectedValue.
  ///
  /// In en, this message translates to:
  /// **'Rejected: {a}'**
  String lotRejectedValue(Object a);

  /// No description provided for @lotRateEarnedLine.
  ///
  /// In en, this message translates to:
  /// **'Rate: {a}/pc • Earned: {b}'**
  String lotRateEarnedLine(Object a, Object b);

  /// No description provided for @lotCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get lotCostLabel;

  /// No description provided for @lotLotsValue.
  ///
  /// In en, this message translates to:
  /// **'Lots: {a}'**
  String lotLotsValue(Object a);

  /// No description provided for @lotWorkersValue.
  ///
  /// In en, this message translates to:
  /// **'Workers: {a}'**
  String lotWorkersValue(Object a);

  /// No description provided for @lotCostPaidOutstandingLine.
  ///
  /// In en, this message translates to:
  /// **'Cost: {a} • Paid (est): {b} • Outstanding (est): {c}'**
  String lotCostPaidOutstandingLine(Object a, Object b, Object c);

  /// No description provided for @stockStageDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Stage Default'**
  String get stockStageDefaultBadge;

  /// No description provided for @stockInheritedFrom.
  ///
  /// In en, this message translates to:
  /// **'Inherited from {a} ({b})'**
  String stockInheritedFrom(Object a, Object b);

  /// No description provided for @selectSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get selectSearchHint;

  /// No description provided for @selectNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get selectNoResults;

  /// No description provided for @selectLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load items. Try again.'**
  String get selectLoadError;

  /// No description provided for @selectSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectSelectAll;

  /// No description provided for @selectClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get selectClearAll;

  /// No description provided for @selectSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectSelectedCount(int count);

  /// No description provided for @selectMaxReached.
  ///
  /// In en, this message translates to:
  /// **'You can select up to {max}'**
  String selectMaxReached(int max);

  /// No description provided for @tableQtyHeader.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get tableQtyHeader;

  /// No description provided for @tableHistoricalPriceHeader.
  ///
  /// In en, this message translates to:
  /// **'Historical Price'**
  String get tableHistoricalPriceHeader;

  /// No description provided for @tableHexHeader.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get tableHexHeader;

  /// No description provided for @tableLotUsesHeader.
  ///
  /// In en, this message translates to:
  /// **'Lot Uses'**
  String get tableLotUsesHeader;

  /// No description provided for @processDefaultRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Labour Rate (₹)'**
  String get processDefaultRateLabel;

  /// No description provided for @processDefaultRateShort.
  ///
  /// In en, this message translates to:
  /// **'Default Rate'**
  String get processDefaultRateShort;

  /// No description provided for @inspectionStillDefectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Still Defective / Rejected Again'**
  String get inspectionStillDefectiveLabel;

  /// No description provided for @inspectionQueueEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Pending QC Inspections'**
  String get inspectionQueueEmptyTitle;

  /// No description provided for @inspectionQueueEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All returned pieces have been inspected and reconciled.'**
  String get inspectionQueueEmptySubtitle;

  /// No description provided for @lotOpenValue.
  ///
  /// In en, this message translates to:
  /// **'Open: {a}'**
  String lotOpenValue(Object a);

  /// No description provided for @lotReapprovedValue.
  ///
  /// In en, this message translates to:
  /// **'Re-Approved: {a}'**
  String lotReapprovedValue(Object a);

  /// No description provided for @lotEarnedValue.
  ///
  /// In en, this message translates to:
  /// **'Earned: {a}'**
  String lotEarnedValue(Object a);

  /// No description provided for @lotPendingEstimateValue.
  ///
  /// In en, this message translates to:
  /// **'Pending Est: {a}'**
  String lotPendingEstimateValue(Object a);

  /// No description provided for @backupMovementsValue.
  ///
  /// In en, this message translates to:
  /// **'Movements: {a}'**
  String backupMovementsValue(Object a);

  /// No description provided for @backupPhotosValue.
  ///
  /// In en, this message translates to:
  /// **'Photos: {a}'**
  String backupPhotosValue(Object a);

  /// No description provided for @txnDesignColourLabel.
  ///
  /// In en, this message translates to:
  /// **'Design / Colour'**
  String get txnDesignColourLabel;

  /// No description provided for @txnAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get txnAmountLabel;

  /// No description provided for @txnReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get txnReferenceLabel;

  /// No description provided for @txnReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get txnReasonLabel;

  /// No description provided for @workerRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker Rate'**
  String get workerRateLabel;

  /// No description provided for @workerCustomRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Worker Rate (₹ / pc, optional)'**
  String get workerCustomRateLabel;

  /// No description provided for @assignmentsHistoryPreservedNote.
  ///
  /// In en, this message translates to:
  /// **'Historical labour transactions & rates remain preserved.'**
  String get assignmentsHistoryPreservedNote;

  /// No description provided for @assignmentsReactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get assignmentsReactivateAction;

  /// No description provided for @reportsNoDataLoaded.
  ///
  /// In en, this message translates to:
  /// **'No report data loaded.'**
  String get reportsNoDataLoaded;

  /// No description provided for @lotCompletedValue.
  ///
  /// In en, this message translates to:
  /// **'Completed: {a}'**
  String lotCompletedValue(Object a);

  /// No description provided for @assignmentsDeactivatedHeading.
  ///
  /// In en, this message translates to:
  /// **'Deactivated Assignments ({a})'**
  String assignmentsDeactivatedHeading(Object a);

  /// No description provided for @workerRateInheritHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to inherit {a}'**
  String workerRateInheritHint(Object a);

  /// No description provided for @designVariantsSummary.
  ///
  /// In en, this message translates to:
  /// **'{a} variants • {b} pcs • {c}'**
  String designVariantsSummary(Object a, Object b, Object c);

  /// No description provided for @assignmentsRemovedToast.
  ///
  /// In en, this message translates to:
  /// **'{a} removed from this worker'**
  String assignmentsRemovedToast(Object a);

  /// No description provided for @paginationLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get paginationLoadMore;

  /// No description provided for @paginationShowingAll.
  ///
  /// In en, this message translates to:
  /// **'Showing all {a}'**
  String paginationShowingAll(Object a);

  /// No description provided for @dashboardWeekTrendHeading.
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Production'**
  String get dashboardWeekTrendHeading;

  /// No description provided for @securityPinProgress.
  ///
  /// In en, this message translates to:
  /// **'{a} of {b} digits entered'**
  String securityPinProgress(int a, int b);

  /// No description provided for @navPartiesDispatch.
  ///
  /// In en, this message translates to:
  /// **'Parties & Dispatch'**
  String get navPartiesDispatch;

  /// No description provided for @partiesHeading.
  ///
  /// In en, this message translates to:
  /// **'Parties & Buyers'**
  String get partiesHeading;

  /// No description provided for @partiesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search party name, phone, or GSTIN'**
  String get partiesSearchHint;

  /// No description provided for @partiesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Parties Added Yet'**
  String get partiesEmptyTitle;

  /// No description provided for @partiesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add buyers or job-work clients to dispatch finished pieces and track receivables.'**
  String get partiesEmptySubtitle;

  /// No description provided for @partyAddAction.
  ///
  /// In en, this message translates to:
  /// **'New Party'**
  String get partyAddAction;

  /// No description provided for @partyEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Party'**
  String get partyEditAction;

  /// No description provided for @partyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Party / Buyer Name'**
  String get partyNameLabel;

  /// No description provided for @partyPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (optional)'**
  String get partyPhoneLabel;

  /// No description provided for @partyAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get partyAddressLabel;

  /// No description provided for @partyGstinLabel.
  ///
  /// In en, this message translates to:
  /// **'GSTIN (optional)'**
  String get partyGstinLabel;

  /// No description provided for @partyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Party Type'**
  String get partyTypeLabel;

  /// No description provided for @partyTypeBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get partyTypeBuyer;

  /// No description provided for @partyTypeJobClient.
  ///
  /// In en, this message translates to:
  /// **'Job-Work Client'**
  String get partyTypeJobClient;

  /// No description provided for @partyTypeBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get partyTypeBoth;

  /// No description provided for @partyOpeningBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening Receivable (₹, negative = advance)'**
  String get partyOpeningBalanceLabel;

  /// No description provided for @partyActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Party'**
  String get partyActiveLabel;

  /// No description provided for @partySavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Party saved successfully.'**
  String get partySavedSuccess;

  /// No description provided for @partyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get partyFilterAll;

  /// No description provided for @partyFilterDue.
  ///
  /// In en, this message translates to:
  /// **'Receivable Due'**
  String get partyFilterDue;

  /// No description provided for @partyFilterAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance Credit'**
  String get partyFilterAdvance;

  /// No description provided for @partyTotalReceivableLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Receivable'**
  String get partyTotalReceivableLabel;

  /// No description provided for @partyAdvanceCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Party Advance Credit'**
  String get partyAdvanceCreditLabel;

  /// No description provided for @partyDispatchedNetLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Dispatched'**
  String get partyDispatchedNetLabel;

  /// No description provided for @partyReturnsTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Buyer Returns'**
  String get partyReturnsTotalLabel;

  /// No description provided for @partyCollectedNetLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Collected'**
  String get partyCollectedNetLabel;

  /// No description provided for @partyAccountSettledLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Settled'**
  String get partyAccountSettledLabel;

  /// No description provided for @partyKhataHeading.
  ///
  /// In en, this message translates to:
  /// **'Party Khata'**
  String get partyKhataHeading;

  /// No description provided for @partyTabLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get partyTabLedger;

  /// No description provided for @partyTabChallans.
  ///
  /// In en, this message translates to:
  /// **'Challans'**
  String get partyTabChallans;

  /// No description provided for @partyTabReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get partyTabReturns;

  /// No description provided for @partyTabPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get partyTabPayments;

  /// No description provided for @partyShareKhataSlip.
  ///
  /// In en, this message translates to:
  /// **'Share Khata Slip'**
  String get partyShareKhataSlip;

  /// No description provided for @dispatchNewAction.
  ///
  /// In en, this message translates to:
  /// **'Dispatch to Party'**
  String get dispatchNewAction;

  /// No description provided for @dispatchHeading.
  ///
  /// In en, this message translates to:
  /// **'New Dispatch Challan'**
  String get dispatchHeading;

  /// No description provided for @dispatchDetailHeading.
  ///
  /// In en, this message translates to:
  /// **'Dispatch Challan'**
  String get dispatchDetailHeading;

  /// No description provided for @dispatchSelectPartyLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Party / Buyer'**
  String get dispatchSelectPartyLabel;

  /// No description provided for @dispatchChallanNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Challan Number'**
  String get dispatchChallanNumberLabel;

  /// No description provided for @dispatchAddItemAction.
  ///
  /// In en, this message translates to:
  /// **'Add Lot / Colour Item'**
  String get dispatchAddItemAction;

  /// No description provided for @dispatchSelectSkuLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Available Stock (Lot / Design / Colour)'**
  String get dispatchSelectSkuLabel;

  /// No description provided for @dispatchAvailableQtyBadge.
  ///
  /// In en, this message translates to:
  /// **'Available: {a} pcs'**
  String dispatchAvailableQtyBadge(Object a);

  /// No description provided for @dispatchRatePerPcLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate (₹ / pc)'**
  String get dispatchRatePerPcLabel;

  /// No description provided for @dispatchDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount (₹, optional)'**
  String get dispatchDiscountLabel;

  /// No description provided for @dispatchOtherChargesLabel.
  ///
  /// In en, this message translates to:
  /// **'Other Charges / Freight (₹, optional)'**
  String get dispatchOtherChargesLabel;

  /// No description provided for @dispatchGrossTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross Total'**
  String get dispatchGrossTotalLabel;

  /// No description provided for @dispatchNetTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Challan Total'**
  String get dispatchNetTotalLabel;

  /// No description provided for @dispatchSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save Dispatch'**
  String get dispatchSaveAction;

  /// No description provided for @dispatchSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dispatch challan {a} saved.'**
  String dispatchSavedSuccess(Object a);

  /// No description provided for @dispatchShareSlipAction.
  ///
  /// In en, this message translates to:
  /// **'Share Challan Slip'**
  String get dispatchShareSlipAction;

  /// No description provided for @dispatchReverseAction.
  ///
  /// In en, this message translates to:
  /// **'Reverse Challan'**
  String get dispatchReverseAction;

  /// No description provided for @dispatchReverseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse Dispatch Challan?'**
  String get dispatchReverseConfirmTitle;

  /// No description provided for @dispatchReverseConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This restores dispatched pieces back to in-house stock and cancels the party charge.'**
  String get dispatchReverseConfirmMessage;

  /// No description provided for @dispatchReversedBadge.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get dispatchReversedBadge;

  /// No description provided for @dispatchNoItemsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No good in-house stock is currently available to dispatch.'**
  String get dispatchNoItemsAvailable;

  /// No description provided for @dispatchDispatchedStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Dispatched'**
  String get dispatchDispatchedStockLabel;

  /// No description provided for @buyerReturnNewAction.
  ///
  /// In en, this message translates to:
  /// **'Buyer Return'**
  String get buyerReturnNewAction;

  /// No description provided for @buyerReturnHeading.
  ///
  /// In en, this message translates to:
  /// **'Record Buyer Return'**
  String get buyerReturnHeading;

  /// No description provided for @buyerReturnNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Return Note Number'**
  String get buyerReturnNumberLabel;

  /// No description provided for @buyerReturnConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Returned Condition'**
  String get buyerReturnConditionLabel;

  /// No description provided for @buyerReturnConditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good (Back to Available Stock)'**
  String get buyerReturnConditionGood;

  /// No description provided for @buyerReturnConditionDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged (Damaged Bucket)'**
  String get buyerReturnConditionDamaged;

  /// No description provided for @buyerReturnCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Return Credit'**
  String get buyerReturnCreditLabel;

  /// No description provided for @buyerReturnSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Buyer return {a} recorded.'**
  String buyerReturnSavedSuccess(Object a);

  /// No description provided for @buyerReturnReverseAction.
  ///
  /// In en, this message translates to:
  /// **'Reverse Return'**
  String get buyerReturnReverseAction;

  /// No description provided for @partyPaymentNewAction.
  ///
  /// In en, this message translates to:
  /// **'Record Receipt'**
  String get partyPaymentNewAction;

  /// No description provided for @partyPaymentHeading.
  ///
  /// In en, this message translates to:
  /// **'Record Party Payment'**
  String get partyPaymentHeading;

  /// No description provided for @partyPaymentTypeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt (Against Due)'**
  String get partyPaymentTypeReceipt;

  /// No description provided for @partyPaymentTypeAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance Received'**
  String get partyPaymentTypeAdvance;

  /// No description provided for @partyPaymentTypeRefund.
  ///
  /// In en, this message translates to:
  /// **'Advance Refund Paid'**
  String get partyPaymentTypeRefund;

  /// No description provided for @partyPaymentCollectFullAction.
  ///
  /// In en, this message translates to:
  /// **'Collect full {amount}'**
  String partyPaymentCollectFullAction(String amount);

  /// No description provided for @partyPaymentSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Party payment recorded.'**
  String get partyPaymentSavedSuccess;

  /// No description provided for @partyPaymentShareReceiptAction.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt Slip'**
  String get partyPaymentShareReceiptAction;

  /// No description provided for @lotPnlHeading.
  ///
  /// In en, this message translates to:
  /// **'Lot Profit & Loss'**
  String get lotPnlHeading;

  /// No description provided for @lotPnlNetRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Revenue'**
  String get lotPnlNetRevenueLabel;

  /// No description provided for @lotPnlWorkerLabourLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker Labour'**
  String get lotPnlWorkerLabourLabel;

  /// No description provided for @lotPnlDirectCostsLabel.
  ///
  /// In en, this message translates to:
  /// **'Direct Costs'**
  String get lotPnlDirectCostsLabel;

  /// No description provided for @lotPnlNetProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get lotPnlNetProfitLabel;

  /// No description provided for @lotPnlMarginLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get lotPnlMarginLabel;

  /// No description provided for @lotPnlUnsoldValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Unsold Good Stock Value'**
  String get lotPnlUnsoldValueLabel;

  /// No description provided for @lotDirectCostAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add Direct Cost'**
  String get lotDirectCostAddAction;

  /// No description provided for @lotDirectCostHeading.
  ///
  /// In en, this message translates to:
  /// **'Add Lot Direct Cost'**
  String get lotDirectCostHeading;

  /// No description provided for @lotDirectCostCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost Category'**
  String get lotDirectCostCategoryLabel;

  /// No description provided for @lotDirectCostCatFabric.
  ///
  /// In en, this message translates to:
  /// **'Fabric'**
  String get lotDirectCostCatFabric;

  /// No description provided for @lotDirectCostCatTrims.
  ///
  /// In en, this message translates to:
  /// **'Trims & Accessories'**
  String get lotDirectCostCatTrims;

  /// No description provided for @lotDirectCostCatTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get lotDirectCostCatTransport;

  /// No description provided for @lotDirectCostCatPacking.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get lotDirectCostCatPacking;

  /// No description provided for @lotDirectCostCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get lotDirectCostCatOther;

  /// No description provided for @lotDirectCostDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (e.g. Cotton Fabric 200m)'**
  String get lotDirectCostDescriptionLabel;

  /// No description provided for @lotDirectCostAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get lotDirectCostAmountLabel;

  /// No description provided for @lotDirectCostEmpty.
  ///
  /// In en, this message translates to:
  /// **'No extra direct costs added for this lot.'**
  String get lotDirectCostEmpty;

  /// No description provided for @lotDirectCostSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Lot direct cost added.'**
  String get lotDirectCostSavedSuccess;

  /// No description provided for @lotDirectCostReverseAction.
  ///
  /// In en, this message translates to:
  /// **'Reverse Cost'**
  String get lotDirectCostReverseAction;

  /// No description provided for @reportCategoryPartiesPnl.
  ///
  /// In en, this message translates to:
  /// **'Parties & Lot P&L'**
  String get reportCategoryPartiesPnl;

  /// No description provided for @partyInactiveOrMissingError.
  ///
  /// In en, this message translates to:
  /// **'Selected party is inactive or does not exist.'**
  String get partyInactiveOrMissingError;

  /// No description provided for @dispatchItemsRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item to dispatch.'**
  String get dispatchItemsRequiredError;

  /// No description provided for @buyerReturnItemsRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Add at least one returned item.'**
  String get buyerReturnItemsRequiredError;

  /// No description provided for @dispatchInsufficientStockError.
  ///
  /// In en, this message translates to:
  /// **'Dispatch quantity exceeds available in-house good stock.'**
  String get dispatchInsufficientStockError;

  /// No description provided for @dispatchDiscountExceedsGrossError.
  ///
  /// In en, this message translates to:
  /// **'Discount cannot exceed challan gross total.'**
  String get dispatchDiscountExceedsGrossError;

  /// No description provided for @dispatchReverseBlockedReturnError.
  ///
  /// In en, this message translates to:
  /// **'Reverse linked buyer returns before reversing this challan.'**
  String get dispatchReverseBlockedReturnError;

  /// No description provided for @buyerReturnExceedsDispatchedError.
  ///
  /// In en, this message translates to:
  /// **'Return quantity exceeds remaining dispatched quantity.'**
  String get buyerReturnExceedsDispatchedError;

  /// No description provided for @appearanceSurfaceStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Surface Style'**
  String get appearanceSurfaceStyleTitle;

  /// No description provided for @appearanceSurfaceModernGlass.
  ///
  /// In en, this message translates to:
  /// **'Modern Frosted Glass'**
  String get appearanceSurfaceModernGlass;

  /// No description provided for @appearanceSurfaceModernGlassDesc.
  ///
  /// In en, this message translates to:
  /// **'Translucent frosted chrome & focal cards with smooth 120Hz lists'**
  String get appearanceSurfaceModernGlassDesc;

  /// No description provided for @appearanceSurfaceLiquidAurora.
  ///
  /// In en, this message translates to:
  /// **'Liquid Aurora Glass'**
  String get appearanceSurfaceLiquidAurora;

  /// No description provided for @appearanceSurfaceLiquidAuroraDesc.
  ///
  /// In en, this message translates to:
  /// **'Subtle single-hue ambient wash & frosted crystal surfaces'**
  String get appearanceSurfaceLiquidAuroraDesc;

  /// No description provided for @appearanceSurfaceClassicSolid.
  ///
  /// In en, this message translates to:
  /// **'Classic Solid'**
  String get appearanceSurfaceClassicSolid;

  /// No description provided for @appearanceSurfaceClassicSolidDesc.
  ///
  /// In en, this message translates to:
  /// **'High-contrast opaque cards with soft elevation'**
  String get appearanceSurfaceClassicSolidDesc;

  /// No description provided for @appearanceColorPresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get appearanceColorPresetTitle;

  /// No description provided for @appearancePresetIndigoThread.
  ///
  /// In en, this message translates to:
  /// **'Indigo Thread'**
  String get appearancePresetIndigoThread;

  /// No description provided for @appearancePresetEmeraldMint.
  ///
  /// In en, this message translates to:
  /// **'Emerald Mint'**
  String get appearancePresetEmeraldMint;

  /// No description provided for @appearancePresetMidnightCyan.
  ///
  /// In en, this message translates to:
  /// **'Midnight Cyan'**
  String get appearancePresetMidnightCyan;

  /// No description provided for @appearancePresetRoyalSaffron.
  ///
  /// In en, this message translates to:
  /// **'Royal Saffron'**
  String get appearancePresetRoyalSaffron;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navAllModules.
  ///
  /// In en, this message translates to:
  /// **'All Modules'**
  String get navAllModules;

  /// No description provided for @navSectionOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navSectionOverview;

  /// No description provided for @navSectionProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get navSectionProduction;

  /// No description provided for @navSectionStockQc.
  ///
  /// In en, this message translates to:
  /// **'Stock & QC'**
  String get navSectionStockQc;

  /// No description provided for @navSectionFinanceParties.
  ///
  /// In en, this message translates to:
  /// **'Finance & Parties'**
  String get navSectionFinanceParties;

  /// No description provided for @navSectionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get navSectionSystem;

  /// No description provided for @navSidebarCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse to compact rail'**
  String get navSidebarCollapse;

  /// No description provided for @navSidebarExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get navSidebarExpand;

  /// No description provided for @navSidebarHide.
  ///
  /// In en, this message translates to:
  /// **'Hide sidebar'**
  String get navSidebarHide;

  /// No description provided for @navSidebarShow.
  ///
  /// In en, this message translates to:
  /// **'Show sidebar (Ctrl+B)'**
  String get navSidebarShow;
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
