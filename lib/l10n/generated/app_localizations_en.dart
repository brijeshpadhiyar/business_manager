// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'StitchFlow';

  @override
  String get appTitleDev => 'StitchFlow Dev';

  @override
  String get appTagline => 'From Fabric to Finished.';

  @override
  String get foundationTitle => 'Project Foundation Ready';

  @override
  String get foundationSubtitle =>
      'Offline-first architecture, flavors, Material 3 design system, and bilingual localization are configured.';

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
  String get themeSectionTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionRetry => 'Retry';

  @override
  String get errorUnexpected =>
      'An unexpected error occurred. Please try again.';

  @override
  String get navOverview => 'Overview';

  @override
  String get navInputs => 'Inputs';

  @override
  String get navFeedback => 'Feedback';

  @override
  String get showcaseButtonsHeading => 'Buttons & Actions';

  @override
  String get showcasePrimaryAction => 'Primary Action';

  @override
  String get showcaseSecondaryAction => 'Secondary';

  @override
  String get showcaseOutlinedAction => 'Outlined';

  @override
  String get showcaseDestructiveAction => 'Delete';

  @override
  String get showcaseLoadingAction => 'Saving...';

  @override
  String get showcaseDisabledAction => 'Disabled';

  @override
  String get showcaseInputsHeading => 'Form Controls';

  @override
  String get showcaseSampleFieldLabel => 'Reference Name';

  @override
  String get showcaseSampleFieldHint => 'Enter a sample value';

  @override
  String get validationRequired => 'This field is required.';

  @override
  String get showcaseDropdownLabel => 'Sample Category';

  @override
  String get showcaseOptionOne => 'Option One';

  @override
  String get showcaseOptionTwo => 'Option Two';

  @override
  String get showcaseDatePickerLabel => 'Business Date (IST)';

  @override
  String get showcaseCheckboxLabel => 'Mark as verified';

  @override
  String get showcaseSwitchLabel => 'Enable compact preview';

  @override
  String get showcaseValidateButton => 'Validate Form';

  @override
  String get showcaseBadgesHeading => 'Status Badges';

  @override
  String get statusGood => 'Good Stock';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusDamaged => 'Damaged';

  @override
  String get statusAdvanceCredit => 'Advance Credit';

  @override
  String get showcaseOpenDialog => 'Open Dialog';

  @override
  String get showcaseOpenSheet => 'Open Adaptive Sheet';

  @override
  String get showcaseDialogTitle => 'Confirm Action';

  @override
  String get showcaseDialogMessage =>
      'This preview verifies consistent Material 3 spacing, typography, and bilingual wrapping.';

  @override
  String get showcaseLongTextHeading => 'Typography & Long Text Sample';

  @override
  String get showcaseLongTextSample =>
      'All design tokens, typography weights, and bilingual labels wrap cleanly across compact Android phones, tablets, and desktop layouts without clipping or overflow.';

  @override
  String get showcaseTableHeading => 'Responsive Data Table';

  @override
  String get showcaseColName => 'Item';

  @override
  String get showcaseColQty => 'Quantity';

  @override
  String get showcaseColAmount => 'Amount';

  @override
  String get showcaseEmptyTitle => 'No Records Yet';

  @override
  String get showcaseEmptySubtitle => 'Items will appear here once added.';

  @override
  String get showcaseErrorTitle => 'Unable to Load Preview';

  @override
  String get showcaseLoadingMessage => 'Loading preview...';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navLots => 'Lots';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navBusinessProfile => 'Business Profile';

  @override
  String get navDesignShowcase => 'Design System Showcase';

  @override
  String get dashboardWelcomeSubtitle =>
      'Offline-first Garment & Production Management';

  @override
  String get dashboardQuickActions => 'Quick Actions';

  @override
  String get dashboardPreferences => 'App Preferences';

  @override
  String get businessProfileHeading => 'Business Profile';

  @override
  String get businessProfileSubtitle =>
      'Configure your workshop details separately from the StitchFlow app name.';

  @override
  String get businessNameEnLabel => 'Business Name (English)';

  @override
  String get businessNameGuLabel => 'Business Name (Gujarati)';

  @override
  String get businessOwnerLabel => 'Owner / Operator Name';

  @override
  String get businessPhoneLabel => 'Contact Number';

  @override
  String get businessAddressLabel => 'Workshop Address';

  @override
  String get businessDefaultBillingLabel => 'Default Labour Billing Mode';

  @override
  String get billingModeReceivedQty => 'Pay on Received Quantity (Default)';

  @override
  String get billingModeGivenQty => 'Pay on Given Quantity';

  @override
  String get businessProfileSaved => 'Business profile saved.';

  @override
  String get lotsHeading => 'Lots';

  @override
  String get lotsSearchHint => 'Search by lot number, title, or notes';

  @override
  String get lotsFilterAll => 'All';

  @override
  String get lotsStatusActive => 'Active';

  @override
  String get lotsStatusCompleted => 'Completed';

  @override
  String get lotsStatusArchived => 'Archived';

  @override
  String get lotsEmptyTitle => 'No Lots Yet';

  @override
  String get lotsEmptySubtitle =>
      'Create your first lot to start tracking designs, colours, and initial quantities.';

  @override
  String get lotCreateAction => 'New Lot';

  @override
  String get lotEditAction => 'Edit Lot';

  @override
  String get lotArchiveAction => 'Archive Lot';

  @override
  String get lotArchiveConfirmTitle => 'Archive Lot?';

  @override
  String get lotArchiveConfirmMessage =>
      'This lot will be archived without deleting historical records.';

  @override
  String get lotNumberLabel => 'Lot Number';

  @override
  String get lotTitleLabel => 'Title (Optional)';

  @override
  String get lotNotesLabel => 'Notes (Optional)';

  @override
  String get lotDateLabel => 'Lot Date (IST)';

  @override
  String get lotStatusLabel => 'Status';

  @override
  String get lotDuplicateError =>
      'An active lot with this lot number already exists.';

  @override
  String get lotPhotosHeading => 'Lot Photos';

  @override
  String get lotPhotosEmpty => 'No photos attached yet.';

  @override
  String get lotAddPhotoCamera => 'Camera';

  @override
  String get lotAddPhotoGallery => 'Gallery';

  @override
  String get lotPhotoRemoveConfirm => 'Remove this photo from the lot?';

  @override
  String get lotPhotoMissing => 'Photo file is unavailable.';

  @override
  String get designsHeading => 'Designs & Colours';

  @override
  String get designsSearchHint => 'Filter designs or colours';

  @override
  String get designsEmptyTitle => 'No Designs Added';

  @override
  String get designsEmptySubtitle =>
      'Add a design to this lot, then add independent colour quantities and prices.';

  @override
  String get designAddAction => 'Add Design';

  @override
  String get designEditAction => 'Edit Design';

  @override
  String get designDeleteConfirmTitle => 'Remove Design?';

  @override
  String get designDeleteConfirmMessage =>
      'This design will be archived from active listings.';

  @override
  String get designNameLabel => 'Design Name / Code';

  @override
  String get designDuplicateError =>
      'A design with this name already exists in this lot.';

  @override
  String get colourAddAction => 'Add Colour';

  @override
  String get colourEditAction => 'Edit Colour';

  @override
  String get colourDeleteConfirmTitle => 'Remove Colour?';

  @override
  String get colourDeleteConfirmMessage =>
      'This colour entry will be archived from active listings.';

  @override
  String get colourNameLabel => 'Colour Name';

  @override
  String get colourInitialQtyLabel => 'Initial Quantity';

  @override
  String get colourUnitPriceLabel => 'Price per Piece (₹)';

  @override
  String get colourDuplicateError =>
      'This colour already exists in this design.';

  @override
  String get validationPositiveInt => 'Enter a whole number greater than 0.';

  @override
  String get validationValidPrice =>
      'Enter a valid non-negative price (e.g. 250 or 250.50).';

  @override
  String get inventoryHeading => 'Initial Inventory Overview';

  @override
  String get inventoryNote =>
      'Shows recorded Initial Quantities only. Stock movements and pending balances arrive in later milestones.';

  @override
  String get inventoryTotalLots => 'Active Lots';

  @override
  String get inventoryTotalDesigns => 'Designs';

  @override
  String get inventoryTotalCombinations => 'Design + Colour';

  @override
  String get inventoryTotalInitialQty => 'Total Initial Qty';

  @override
  String get inventoryTabLots => 'Lot-wise';

  @override
  String get inventoryTabDesigns => 'Design-wise';

  @override
  String get inventoryTabColours => 'Colour-wise';

  @override
  String get inventoryEmptyTitle => 'No Initial Inventory Yet';

  @override
  String get inventoryEmptySubtitle =>
      'Add lots, designs, and colours to see initial quantity totals here.';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Remove';

  @override
  String get actionClose => 'Close';

  @override
  String get piecesUnit => 'pcs';
}
