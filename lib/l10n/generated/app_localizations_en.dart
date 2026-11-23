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

  @override
  String get navProcesses => 'Processes';

  @override
  String get navWorkers => 'Workers';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterInactive => 'Inactive';

  @override
  String get processesHeading => 'Production Processes';

  @override
  String get processesSearchHint => 'Search processes by name or description';

  @override
  String get processesEmptyTitle => 'No Processes Yet';

  @override
  String get processesEmptySubtitle =>
      'Create your own production processes in any order your workshop uses.';

  @override
  String get processCreateAction => 'New Process';

  @override
  String get processEditAction => 'Edit Process';

  @override
  String get processDetailsHeading => 'Process Details';

  @override
  String get processNameLabel => 'Process Name';

  @override
  String get processDescriptionLabel => 'Description (Optional)';

  @override
  String get processBillingOverrideLabel => 'Labour Billing Mode';

  @override
  String get processBillingInheritGlobal => 'Use Business Default';

  @override
  String get processIncludeDamagedLabel => 'Include damaged pieces in labour';

  @override
  String get processActivateAction => 'Activate Process';

  @override
  String get processDeactivateAction => 'Deactivate Process';

  @override
  String get processDeactivateConfirmTitle => 'Deactivate Process?';

  @override
  String get processDeactivateConfirmMessage =>
      'Historical records remain intact, but new assignments and issues will be blocked while inactive.';

  @override
  String get processDuplicateNameError =>
      'A process with this name already exists.';

  @override
  String get processAssignedWorkersHeading => 'Assigned Workers';

  @override
  String get processNoAssignedWorkers =>
      'No workers are currently assigned to this process.';

  @override
  String get processAuditHistoryHeading => 'Audit History';

  @override
  String get processNoAuditHistory => 'No audit entries recorded yet.';

  @override
  String get createdAtLabel => 'Created';

  @override
  String get updatedAtLabel => 'Last Updated';

  @override
  String get workersHeading => 'Workers';

  @override
  String get workersSearchHint => 'Search workers by name, phone, or address';

  @override
  String get workersEmptyTitle => 'No Workers Yet';

  @override
  String get workersEmptySubtitle =>
      'Add your workshop workers to assign processes and configure per-piece rates.';

  @override
  String get workerCreateAction => 'New Worker';

  @override
  String get workerEditAction => 'Edit Worker';

  @override
  String get workerDetailsHeading => 'Worker Profile';

  @override
  String get workerNameLabel => 'Worker Name';

  @override
  String get workerPhoneLabel => 'Phone Number (Optional)';

  @override
  String get workerAddressLabel => 'Address (Optional)';

  @override
  String get workerNotesLabel => 'Notes (Optional)';

  @override
  String get workerActivateAction => 'Activate Worker';

  @override
  String get workerDeactivateAction => 'Deactivate Worker';

  @override
  String get workerDeactivateConfirmTitle => 'Deactivate Worker?';

  @override
  String get workerDeactivateConfirmMessage =>
      'Historical records and rates are preserved. Inactive workers cannot receive new assignments.';

  @override
  String get workerContactHeading => 'Contact Details';

  @override
  String get workerNoContactInfo => 'No phone or address recorded.';

  @override
  String get workerAssignedProcessesHeading =>
      'Assigned Processes & Current Rates';

  @override
  String get workerNoAssignedProcesses => 'No processes assigned yet.';

  @override
  String get workerManageAssignmentsAction => 'Manage Assignments';

  @override
  String get workerViewRateHistoryAction => 'Rate History';

  @override
  String get workerAddRateAction => 'Add Rate';

  @override
  String get assignmentsHeading => 'Worker Process Assignments';

  @override
  String get assignmentsSubtitle =>
      'A worker can be assigned to multiple processes with no fixed sequence.';

  @override
  String get assignmentsAddLabel => 'Select Active Process';

  @override
  String get assignmentsAddAction => 'Assign Process';

  @override
  String get assignmentsRemoveAction => 'Remove';

  @override
  String get assignmentsRemoveConfirmTitle => 'Remove Assignment?';

  @override
  String get assignmentsRemoveConfirmMessage =>
      'This deactivates the assignment while preserving historical rate and work records.';

  @override
  String get assignmentsEmptyTitle => 'No Active Assignments';

  @override
  String get assignmentsEmptySubtitle =>
      'Assign one or more active processes to this worker.';

  @override
  String get assignmentsNoAvailableProcesses =>
      'All active processes are already assigned or no active processes exist.';

  @override
  String get assignmentsDuplicateError =>
      'This process is already assigned to the worker.';

  @override
  String get assignmentsInactiveWorkerError =>
      'Activate this worker before adding process assignments.';

  @override
  String get assignmentsInactiveProcessError =>
      'Only active processes can be assigned.';

  @override
  String get ratesHistoryHeading => 'Per-Piece Rate History';

  @override
  String get ratesFilterProcessLabel => 'Process';

  @override
  String get ratesCurrentRateLabel => 'Current Rate';

  @override
  String get ratesNoCurrentRate => 'No current rate';

  @override
  String get ratesPerPieceSuffix => '/ pc';

  @override
  String get ratesOngoingLabel => 'Ongoing';

  @override
  String get ratesEffectiveFromLabel => 'Effective From (IST)';

  @override
  String get ratesEffectiveToLabel => 'Effective To (IST, Optional)';

  @override
  String get ratesClearEffectiveTo => 'Clear End Date (Ongoing)';

  @override
  String get ratesAmountLabel => 'Rate per Piece (₹)';

  @override
  String get ratesNotesLabel => 'Reason / Notes (Optional)';

  @override
  String get ratesAddHeading => 'Add Historical Rate';

  @override
  String get ratesEditHeading => 'Edit Rate';

  @override
  String get ratesEmptyTitle => 'No Rates Configured';

  @override
  String get ratesEmptySubtitle =>
      'Add an effective-dated per-piece rate for this worker and process.';

  @override
  String get ratesSelectProcessHint => 'Select Process';

  @override
  String get ratesAutoCloseTitle => 'Close Previous Ongoing Rate?';

  @override
  String get ratesAutoCloseMessage =>
      'An ongoing rate exists for this process. Saving will close it on the previous day and start the new rate from your chosen date.';

  @override
  String get ratesOverlapError =>
      'This date range overlaps with an existing rate.';

  @override
  String get ratesMultipleOpenEndedError =>
      'Another ongoing rate already exists for this worker and process.';

  @override
  String get ratesToBeforeFromError =>
      'Effective To date cannot be earlier than Effective From date.';

  @override
  String get ratesLockedByHistoryError =>
      'This rate is already used in historical transactions and cannot be edited.';

  @override
  String get ratesHistoricalNotice =>
      'Historical rates are preserved. To change a rate, add a new effective-dated entry.';

  @override
  String get navStockMovements => 'Stock Movements';

  @override
  String get navAccounting => 'Labour & Payments';

  @override
  String get navReports => 'Reports';

  @override
  String get navBackupRestore => 'Backup & Restore';

  @override
  String get stockHeading => 'Stock Movements';

  @override
  String get stockIssueAction => 'Issue Stock';

  @override
  String get stockReturnAction => 'Receive Return';

  @override
  String get stockRepairAction => 'Repair Damaged';

  @override
  String get stockTabOpenIssues => 'Pending Issues';

  @override
  String get stockTabBalances => 'Live Stock';

  @override
  String get stockTabHistory => 'Timeline';

  @override
  String get stockTabWorkers => 'By Worker';

  @override
  String get stockTabProcesses => 'By Process';

  @override
  String get stockAvailableGoodLabel => 'Available Good';

  @override
  String get stockPendingWorkerLabel => 'Pending w/ Workers';

  @override
  String get stockDamagedBucketLabel => 'Damaged Stock';

  @override
  String get stockLostLabel => 'Lost';

  @override
  String get stockShortageLabel => 'Shortage';

  @override
  String get stockIssuedLabel => 'Issued';

  @override
  String get stockGoodReturnedLabel => 'Good Returned';

  @override
  String get stockRemainingPendingLabel => 'Remaining Pending';

  @override
  String get stockSelectLotLabel => 'Select Lot';

  @override
  String get stockSelectDesignLabel => 'Select Design';

  @override
  String get stockSelectColourLabel => 'Select Colour';

  @override
  String get stockSelectProcessLabel => 'Select Process';

  @override
  String get stockSelectWorkerLabel => 'Select Eligible Worker';

  @override
  String get stockIssueQuantityLabel => 'Issue Quantity (pcs)';

  @override
  String get stockTransactionDateTimeLabel => 'Transaction Date & Time (IST)';

  @override
  String get stockResolvedRateLabel => 'Locked Per-Piece Rate';

  @override
  String get stockRateMissingWarning =>
      'No effective historical rate exists for this worker and process on the chosen IST date.';

  @override
  String get stockRateConflictWarning =>
      'Conflicting overlapping rates exist on this date.';

  @override
  String get stockRateOverrideToggle => 'Manual Rate Override (Audited)';

  @override
  String get stockOverrideRateLabel => 'Override Rate (₹ / pc)';

  @override
  String get stockOverrideReasonLabel => 'Override Reason (Required)';

  @override
  String get stockNotesLabel => 'Notes (Optional)';

  @override
  String get stockIssueSuccess => 'Stock issued successfully.';

  @override
  String get stockNoEligibleWorkers =>
      'No active workers are assigned to this process.';

  @override
  String get stockInsufficientGoodError =>
      'Cannot issue more than available good stock.';

  @override
  String get stockInvalidQtyError => 'Enter a valid positive piece quantity.';

  @override
  String get stockSettlementHeading => 'Receive Return / Settlement';

  @override
  String get stockGoodReturnQtyLabel => 'Good Returned (pcs)';

  @override
  String get stockDamagedReturnQtyLabel => 'Damaged Returned (pcs)';

  @override
  String get stockLostQtyLabel => 'Lost (pcs)';

  @override
  String get stockShortageQtyLabel => 'Shortage / Missing (pcs)';

  @override
  String get stockSettlementReasonLabel =>
      'Reason (Required for Damaged / Lost / Shortage)';

  @override
  String get stockSettlementTotalExceedsError =>
      'Total settled quantity exceeds remaining pending quantity.';

  @override
  String get stockSettlementEmptyError =>
      'Enter at least one quantity greater than zero.';

  @override
  String get stockSettlementReasonRequiredError =>
      'Reason is required for damaged, lost, or shortage settlements.';

  @override
  String get stockSettlementSuccess => 'Return / settlement recorded.';

  @override
  String get stockInheritedRateNotice =>
      'Original locked issue rate and billing rule will be inherited automatically.';

  @override
  String get stockRepairHeading => 'Damaged-to-Good Repair Adjustment';

  @override
  String get stockRepairQuantityLabel => 'Repaired Quantity (pcs)';

  @override
  String get stockRepairReasonLabel => 'Repair Reason (Required)';

  @override
  String get stockRepairExceedsDamagedError =>
      'Quantity exceeds current damaged stock bucket.';

  @override
  String get stockRepairSuccess => 'Damaged stock adjusted back to good stock.';

  @override
  String get stockNoDamagedAvailable =>
      'No damaged stock is currently available for repair.';

  @override
  String get stockReverseAction => 'Reverse Entry';

  @override
  String get stockReverseConfirmTitle => 'Reverse Movement?';

  @override
  String get stockReverseReasonLabel => 'Reversal Reason (Required)';

  @override
  String get stockReverseSuccess => 'Movement reversed with full audit trail.';

  @override
  String get stockReverseBlockedDownstream =>
      'Cannot reverse: downstream stock movements depend on these pieces.';

  @override
  String get stockReverseBlockedChildren =>
      'Reverse child returns/settlements before reversing this issue.';

  @override
  String get stockReversedBadge => 'Reversed';

  @override
  String get stockEmptyIssuesTitle => 'No Pending Issues';

  @override
  String get stockEmptyIssuesSubtitle =>
      'All issued pieces have been settled, or no stock has been issued yet.';

  @override
  String get stockEmptyHistoryTitle => 'No Stock Movements Yet';

  @override
  String get stockEmptyHistorySubtitle =>
      'Issue stock to a worker and process to start tracking movements.';

  @override
  String get stockSearchHint =>
      'Search lot, design, colour, worker, process...';

  @override
  String get stockFilterAllTypes => 'All Types';

  @override
  String get stockTypeIssue => 'Issue';

  @override
  String get stockTypeReturnGood => 'Good Return';

  @override
  String get stockTypeReturnDamaged => 'Damaged Return';

  @override
  String get stockTypeLost => 'Lost';

  @override
  String get stockTypeShortage => 'Shortage';

  @override
  String get stockTypeRepair => 'Damaged -> Good';

  @override
  String get stockTypeReversal => 'Reversal';

  @override
  String get stockDetailsHeading => 'Issue & Return Details';

  @override
  String get accountingHeading => 'Labour & Worker Accounts';

  @override
  String get accountingTabWorkers => 'Worker Balances';

  @override
  String get accountingTabPayments => 'Payments';

  @override
  String get accountingTabLabour => 'Labour Entries';

  @override
  String get accountingEarnedLabourLabel => 'Earned Labour';

  @override
  String get accountingIssuedLabourInfoLabel => 'Issued Labour (Info)';

  @override
  String get accountingReceivedLabourInfoLabel => 'Received Labour (Info)';

  @override
  String get accountingRegularPaidLabel => 'Regular Payments';

  @override
  String get accountingAdvancePaidLabel => 'Advances Paid';

  @override
  String get accountingAdvanceRefundLabel => 'Advance Refunds';

  @override
  String get accountingAdjustmentsLabel => 'Adjustments';

  @override
  String get accountingOutstandingPayableLabel => 'Outstanding Payable';

  @override
  String get accountingAdvanceCreditLabel => 'Advance Credit';

  @override
  String get accountingNetBalanceLabel => 'Net Balance';

  @override
  String get accountingRecordPaymentAction => 'Record Payment / Advance';

  @override
  String get accountingAddAdjustmentAction => 'Add Adjustment';

  @override
  String get accountingOpenLedgerAction => 'Worker Ledger';

  @override
  String get accountingPaymentTypeLabel => 'Payment Type';

  @override
  String get accountingPaymentTypeRegular => 'Regular Payment';

  @override
  String get accountingPaymentTypeAdvance => 'Advance Payment';

  @override
  String get accountingPaymentTypeRefund => 'Advance Refund';

  @override
  String get accountingPaymentModeLabel => 'Payment Mode';

  @override
  String get accountingModeCash => 'Cash';

  @override
  String get accountingModeUpi => 'UPI';

  @override
  String get accountingModeBank => 'Bank Transfer';

  @override
  String get accountingModeCheque => 'Cheque';

  @override
  String get accountingModeOther => 'Other';

  @override
  String get accountingAmountLabel => 'Amount (₹)';

  @override
  String get accountingReferenceLabel => 'Reference / Receipt No. (Optional)';

  @override
  String get accountingPaymentSaved => 'Payment recorded successfully.';

  @override
  String get accountingAdjustmentTypeLabel => 'Adjustment Type';

  @override
  String get accountingAdjustmentCredit => 'Credit (+ Add to Payable)';

  @override
  String get accountingAdjustmentDebit => 'Debit (- Deduct from Payable)';

  @override
  String get accountingAdjustmentReasonLabel => 'Adjustment Reason (Required)';

  @override
  String get accountingAdjustmentSaved => 'Worker ledger adjustment recorded.';

  @override
  String get accountingReversePaymentTitle => 'Reverse Payment?';

  @override
  String get accountingReversePaymentSuccess => 'Payment reversed cleanly.';

  @override
  String get accountingReverseAdjustmentTitle => 'Reverse Adjustment?';

  @override
  String get accountingReverseAdjustmentSuccess =>
      'Adjustment reversed cleanly.';

  @override
  String get accountingLedgerHeading => 'Worker Ledger';

  @override
  String get accountingOpeningBalanceLabel => 'Opening Balance';

  @override
  String get accountingRunningBalanceLabel => 'Running Bal.';

  @override
  String get accountingFromDateLabel => 'From Date (IST)';

  @override
  String get accountingToDateLabel => 'To Date (IST)';

  @override
  String get accountingClearFilters => 'Clear Filters';

  @override
  String get accountingEmptyLedgerTitle => 'No Ledger Entries';

  @override
  String get accountingEmptyLedgerSubtitle =>
      'Earned labour, advances, payments, and adjustments will appear here.';

  @override
  String get accountingAdvanceNote =>
      'Advances are tracked separately and never counted as earned labour.';

  @override
  String get accountingPayableBadge => 'Payable';

  @override
  String get accountingInfoBadge => 'Info Only';

  @override
  String get backupHeading => 'Backup, Restore & Data Safety';

  @override
  String get backupSubtitle =>
      '100% offline local backup of your SQLite database and private lot photos.';

  @override
  String get backupCreateFullAction => 'Create Full Backup (.zip)';

  @override
  String get backupCreateFullDesc =>
      'Packages a WAL-consistent SQLite snapshot, all private lot photos, and an integrity manifest into a portable ZIP archive.';

  @override
  String get backupRestoreFullAction => 'Restore from Backup (.zip)';

  @override
  String get backupRestoreFullDesc =>
      'Validates archive integrity, checksums, and schema compatibility before atomically replacing local data with automatic rollback protection.';

  @override
  String get backupRawSqliteAction => 'Export Raw SQLite (.sqlite)';

  @override
  String get backupRawSqliteDesc =>
      'Creates a clean standalone .sqlite file for inspection in external SQLite viewers. Does not include photos.';

  @override
  String get backupShareLastAction => 'Share / Save File';

  @override
  String get backupLastCreatedLabel => 'Last Exported File';

  @override
  String get backupValidationPassed => 'Backup Archive Verified';

  @override
  String get backupValidationFailed => 'Backup Validation Failed';

  @override
  String get backupConfirmRestoreTitle => 'Overwrite Local Data?';

  @override
  String get backupConfirmRestoreMessage =>
      'Restoring this backup will replace your current local database and photos. A temporary rollback safety copy will be made automatically before swapping.';

  @override
  String get backupConfirmRestoreAction => 'Yes, Restore Now';

  @override
  String get backupRestoreSuccess =>
      'Backup restored and verified successfully.';

  @override
  String get backupExportSuccess => 'Backup created successfully.';

  @override
  String get backupProgressWorking => 'Processing securely...';

  @override
  String get backupLimitationsTitle => 'Offline Backup Notes';

  @override
  String get backupLimitationsBody =>
      '• Backups are unencrypted in V1 so you can inspect .sqlite files directly.\n• Keep backup ZIP files in a safe personal folder or external drive.\n• Restoring a Dev backup into Production StitchFlow is blocked for safety.';

  @override
  String get dashboardLiveOverview => 'Business Overview';

  @override
  String get dashboardStockHealth => 'Inventory & Production Health';

  @override
  String get dashboardFinanceHealth => 'Worker Accounting Summary';

  @override
  String get dashboardProcessPending => 'Process-Wise Pending Work';

  @override
  String get dashboardRecentActivity => 'Recent Audit Activity';

  @override
  String get dashboardNoProcessPending => 'No pending stock across processes.';

  @override
  String get dashboardNoRecentActivity => 'No activity logged yet.';

  @override
  String get dashboardTotalLotsLabel => 'Active Lots';

  @override
  String get dashboardTotalDesignsColoursLabel => 'Designs / Colours';

  @override
  String get reportsHeading => 'Business Reports';

  @override
  String get reportsTabStockSummary => 'Stock Summary';

  @override
  String get reportsTabLots => 'Lot-Wise';

  @override
  String get reportsTabColours => 'Design / Colour';

  @override
  String get reportsTabWorkers => 'Worker Stock';

  @override
  String get reportsTabProcesses => 'Process Stock';

  @override
  String get reportsTabPending => 'Pending Stock';

  @override
  String get reportsTabDamagedLost => 'Damaged & Lost';

  @override
  String get reportsTabLabour => 'Labour';

  @override
  String get reportsTabWorkerLedger => 'Worker Accounts';

  @override
  String get reportsTabPayments => 'Payments';

  @override
  String get reportsSearchHint =>
      'Filter reports by lot, design, colour, worker...';

  @override
  String get reportsEmptyTitle => 'No Matching Records';

  @override
  String get reportsEmptySubtitle =>
      'Adjust your date range or filters to view matching business data.';

  @override
  String get navSettings => 'Settings';

  @override
  String get navStockShort => 'Stock';

  @override
  String get actionDone => 'Done';

  @override
  String get lotLabelShort => 'Lot';

  @override
  String get refLabelShort => 'Ref';

  @override
  String get inventoryUpdatedNote =>
      'Shows recorded initial quantities across lots, designs, and colours. Open Stock Movements for live balances.';

  @override
  String get auditActionCreate => 'Created';

  @override
  String get auditActionUpdate => 'Updated';

  @override
  String get auditActionDelete => 'Removed';

  @override
  String get auditActionRateOverride => 'Rate Override';

  @override
  String get auditActionRestore => 'Restored';

  @override
  String get settingsHeading => 'Settings';

  @override
  String get settingsSubtitle =>
      'Manage appearance, business profile, stock rules, backups, and workshop guidance.';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsAppearanceSubtitle =>
      'Theme mode (System / Light / Dark) and app language (English / Gujarati).';

  @override
  String get settingsAppearancePreviewTitle => 'Live Preview';

  @override
  String get settingsAppearancePreviewBody =>
      'Verify text readability, Gujarati script clarity, and contrast before returning to daily work.';

  @override
  String get settingsBusinessTitle => 'Business Profile';

  @override
  String get settingsBusinessSubtitle =>
      'Workshop names in English & Gujarati, owner, phone, address, and default billing.';

  @override
  String get settingsStockLabourTitle => 'Stock & Labour Preferences';

  @override
  String get settingsStockLabourSubtitle =>
      'Global billing rule and per-process labour override overview.';

  @override
  String get settingsGlobalBillingSectionTitle =>
      'Global Default Labour Billing Mode';

  @override
  String get settingsGlobalBillingExplanationReceived =>
      'Workers earn labour when returned good pieces are recorded. Damaged pieces are excluded unless enabled on a specific process.';

  @override
  String get settingsGlobalBillingExplanationGiven =>
      'Workers earn labour immediately when stock is issued to them. Return entries stay informational to prevent double-counting.';

  @override
  String get settingsProcessOverridesTitle => 'Process-Level Rules';

  @override
  String get settingsProcessOverridesSubtitle =>
      'Each process inherits the global billing mode unless overridden. Tap any process to configure.';

  @override
  String get settingsProcessInheritsGlobal => 'Inherits Global Default';

  @override
  String get settingsProcessOverridesGlobal => 'Process Override';

  @override
  String get settingsDamagedIncludedShort => 'Damaged Included';

  @override
  String get settingsDamagedExcludedShort => 'Damaged Excluded';

  @override
  String get settingsNoProcessesYet => 'No production processes created yet.';

  @override
  String get settingsBackupTitle => 'Backup & Data Safety';

  @override
  String get settingsBackupSubtitle =>
      'Create full ZIP backups, restore safely, or export raw SQLite.';

  @override
  String get settingsHelpTitle => 'Help & Guidance';

  @override
  String get settingsHelpSubtitle =>
      'Step-by-step workshop instructions for every StitchFlow workflow.';

  @override
  String get settingsAboutTitle => 'About StitchFlow';

  @override
  String get settingsAboutSubtitle =>
      'Version, flavor, local data privacy, and open-source licenses.';

  @override
  String get helpSearchHint =>
      'Search help topics (e.g. issue, return, rate, backup)...';

  @override
  String get helpWhenToUseLabel => 'When to Use';

  @override
  String get helpStepsLabel => 'Step-by-Step Guide';

  @override
  String get helpExampleLabel => 'Practical Workshop Example';

  @override
  String get helpNoResults => 'No help topics match your search.';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get aboutBuildLabel => 'Build';

  @override
  String get aboutPrivacyTitle => '100% Offline & Private Local Data';

  @override
  String get aboutPrivacyBody =>
      'All lots, stock movements, worker rates, ledgers, and photos stay strictly on your device in local SQLite storage. StitchFlow never uploads your business records to external servers.';

  @override
  String get aboutDescriptionBody =>
      'StitchFlow is an offline-first garment workshop production, stock movement, and worker accounting application built for fast daily shop-floor operations.';

  @override
  String get aboutLicensesAction => 'Open-Source Licenses';

  @override
  String get stockStepSelectStock => 'Select Stock';

  @override
  String get stockStepSelectWork => 'Select Work';

  @override
  String get stockStepEnterQty => 'Quantity';

  @override
  String get stockStepConfirm => 'Confirm';

  @override
  String get stockSearchStockHint => 'Search by lot, design, or colour...';

  @override
  String get stockOnlyAvailableFilter => 'In Stock Only';

  @override
  String get stockOutOfStockBadge => 'Out of Stock';

  @override
  String get stockNoStockItemsTitle => 'No Stock Available';

  @override
  String get stockNoStockItemsSubtitle =>
      'Create a lot with designs and colours first, or receive returned stock to replenish in-house good stock.';

  @override
  String get stockSelectedLabel => 'Selected';

  @override
  String get stockChangeSelection => 'Change';

  @override
  String get stockActiveProcessesLabel => 'Active Process';

  @override
  String get stockEligibleWorkersLabel => 'Eligible Assigned Worker';

  @override
  String get stockNoActiveProcessesWarning =>
      'No active processes exist. Create a process before issuing stock.';

  @override
  String get stockBillingModePreviewLabel => 'Locked Billing Mode';

  @override
  String get stockExpectedLabourLabel => 'Estimated Labour';

  @override
  String get stockPayableOnIssueNote =>
      'Payable immediately on issue (Given Qty mode).';

  @override
  String get stockPayableOnReturnNote =>
      'Earned when good pieces are returned (Received Qty mode).';

  @override
  String get stockAdvancedOptionsTitle =>
      'Date/Time, Notes & Audited Rate Override';

  @override
  String get stockQuickAllAvailable => 'All Available';

  @override
  String get stockConfirmSummaryTitle => 'Confirm Stock Issue';

  @override
  String get stockConfirmIssueAction => 'Confirm & Issue Stock';

  @override
  String get stockIssueSuccessTitle => 'Stock Issued Successfully';

  @override
  String get stockIssueSuccessSubtitle =>
      'The issue and locked rate have been saved in the stock ledger.';

  @override
  String get stockUpdatedAvailableLabel => 'Updated Available Good Stock';

  @override
  String get stockIssueMoreAction => 'Issue More Stock';

  @override
  String get stockViewIssueDetailsAction => 'View Issue / Receive Return';

  @override
  String get stockReceiveReturnHeading => 'Receive Return';

  @override
  String get stockSelectPendingIssueTitle => 'Select Pending Issue';

  @override
  String get stockSelectPendingIssueSubtitle =>
      'Choose an open issue below to record returned good, damaged, lost, or shortage pieces.';

  @override
  String get stockFilterAllWorkers => 'All Workers';

  @override
  String get stockFilterAllProcesses => 'All Processes';

  @override
  String get stockPreviouslyReturnedLabel => 'Returned';

  @override
  String get stockFillAllRemaining => 'All Good';

  @override
  String get stockLiveRemainingAfterReturn => 'Remaining Pending After Save';

  @override
  String get stockOverReturnErrorLive =>
      'Total entered exceeds remaining pending quantity.';

  @override
  String get stockConsequencesTitle => 'What Will Happen on Save';

  @override
  String get stockConsequenceGood => 'Returning to in-house good stock';

  @override
  String get stockConsequenceDamaged => 'Moving into damaged inventory bucket';

  @override
  String get stockConsequenceLost => 'Recorded as permanently lost stock';

  @override
  String get stockConsequenceShortage => 'Recorded as shortage discrepancy';

  @override
  String get stockConsequencePending => 'Remaining pending with worker';

  @override
  String get stockConsequenceLabourEarned =>
      'Payable labour credited to worker';

  @override
  String get stockConsequenceLabourAlreadyGiven =>
      'Labour was already credited on Issue (Given Qty mode) — no duplicate labour added.';

  @override
  String get stockConsequenceLabourNone =>
      'No additional payable labour for this entry.';

  @override
  String get stockLostHelper =>
      'Pieces physically lost or misplaced (cannot be recovered).';

  @override
  String get stockShortageHelper =>
      'Count difference / short pieces reported during settlement.';

  @override
  String get stockConfirmSaveReturnAction => 'Confirm & Save Return';

  @override
  String get stockReturnSuccessTitle => 'Return Recorded Successfully';

  @override
  String get stockReturnFullySettledBadge => 'Fully Settled';

  @override
  String get stockReturnUpdatedPendingLabel => 'Updated Remaining Pending';

  @override
  String get stockIssueNextProcessAction =>
      'Issue Returned Stock to Next Process';

  @override
  String get stockReceiveAnotherReturnAction => 'Receive Another Return';

  @override
  String get stockTabPendingReturns => 'Pending Returns';

  @override
  String get stockTabMovementHistory => 'Movement History';

  @override
  String get stockTabSummary => 'Worker & Process';
}
