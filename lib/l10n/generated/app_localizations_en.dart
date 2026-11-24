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
  String get designsSearchHint => 'Search design, colour, or lot number...';

  @override
  String get designsEmptyTitle => 'No Designs Recorded Yet';

  @override
  String get designsEmptySubtitle =>
      'Create a lot with designs and colours to see them tracked here across lots.';

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

  @override
  String get auditActionDeactivate => 'Deactivated';

  @override
  String get auditActionReactivate => 'Reactivated';

  @override
  String get auditActionBackupExport => 'Backup Created';

  @override
  String get auditActionBackupRestore => 'Backup Restored';

  @override
  String get auditEntityBackup => 'Backup & Restore';

  @override
  String get auditEntityAppSecurity => 'App Security';

  @override
  String get settingsSecurityTitle => 'App Lock & Security';

  @override
  String get settingsSecuritySubtitle =>
      'Local PIN, optional fingerprint unlock, auto-lock timeout, and recovery key.';

  @override
  String get securityBadgeEnabled => 'PIN Protected';

  @override
  String get securityBadgeOff => 'Off';

  @override
  String get securityStatusProtected => 'StitchFlow Is PIN Protected';

  @override
  String securityStatusProtectedDesc(int pinLength, String timeout) {
    return '$pinLength-digit PIN • Auto-lock: $timeout';
  }

  @override
  String get securityStatusOff => 'App Lock Is Off';

  @override
  String get securityStatusOffDesc =>
      'Add a local PIN to prevent casual unauthorized access on your phone.';

  @override
  String get securitySetupPinTitle => 'Set Up App PIN';

  @override
  String get securitySetupBenefitsBody =>
      'Keep workshop stock, rates, and karigar accounts private with a 4- or 6-digit offline PIN and optional fingerprint unlock.';

  @override
  String get securityEnablePinAction => 'Enable App PIN';

  @override
  String get securityLockNowAction => 'Lock Now';

  @override
  String get securityChangePinAction => 'Change PIN';

  @override
  String get securityDisablePinAction => 'Disable App PIN';

  @override
  String get securityDisablePinDesc =>
      'Remove the local PIN and open StitchFlow without unlocking.';

  @override
  String get securityDisablePinConfirmTitle => 'Disable App PIN?';

  @override
  String get securityDisablePinConfirmMessage =>
      'Anyone using this phone will be able to open StitchFlow without entering a PIN.';

  @override
  String get securityRegenerateRecoveryKeyAction => 'New Recovery Key';

  @override
  String get securityPinLength4Label => '4-Digit PIN (Fast)';

  @override
  String get securityPinLength6Label => '6-Digit PIN';

  @override
  String get securityCreatePinTitle => 'Create Your PIN';

  @override
  String get securityEnterNewPinTitle => 'Enter New PIN';

  @override
  String securityCreatePinSubtitle(int pinLength) {
    return 'Enter a $pinLength-digit numeric PIN.';
  }

  @override
  String get securityConfirmPinTitle => 'Confirm Your PIN';

  @override
  String get securityConfirmPinSubtitle => 'Re-enter the same PIN to confirm.';

  @override
  String get securityPinMismatchError => 'PINs do not match. Please try again.';

  @override
  String get securityStartOverAction => 'Start Over';

  @override
  String get securityRecoveryKeyTitle => 'Save Your Offline Recovery Key';

  @override
  String get securityNewRecoveryKeyTitle => 'Your New Recovery Key';

  @override
  String get securityRecoveryKeyWriteDownBody =>
      'Write this 8-character code on paper and keep it safely in your workshop diary. It is shown only once and is the only way to reset a forgotten PIN without losing data.';

  @override
  String get securityRecoveryKeyConfirmedCheckbox =>
      'I have written down this Recovery Key in a safe place.';

  @override
  String get securityActivateAppLockAction => 'Activate App Lock';

  @override
  String get securityPinEnabledSuccess => 'App PIN enabled successfully.';

  @override
  String get securityPinChangedSuccess => 'App PIN updated successfully.';

  @override
  String get securityPinDisabledSuccess => 'App PIN disabled.';

  @override
  String get securityUnlockOptionsTitle => 'Unlock & Privacy Options';

  @override
  String get securityEnableBiometricLabel => 'Fingerprint / Biometric Unlock';

  @override
  String get securityEnableBiometricSubtitle =>
      'Unlock StitchFlow quickly with your phone\'s fingerprint or biometric sensor. PIN always remains available.';

  @override
  String get securityBiometricNotEnrolledHint =>
      'No fingerprint or biometric is set up in Android Settings yet.';

  @override
  String get securityBiometricNoHardwareHint =>
      'This device does not support biometric hardware.';

  @override
  String get securityBiometricUnavailableHint =>
      'Biometric authentication is currently unavailable on this device.';

  @override
  String get securityScreenshotProtectionLabel =>
      'Block Screenshots & App Preview';

  @override
  String get securityScreenshotProtectionSubtitle =>
      'Hides workshop data in Android Recent Apps and blocks screenshots while enabled.';

  @override
  String get securityAutoLockTimeoutTitle => 'Auto-Lock Timeout';

  @override
  String get securityAutoLockTimeoutSubtitle =>
      'Automatically lock StitchFlow after switching apps or staying idle.';

  @override
  String get securityTimeoutImmediate => 'Immediate';

  @override
  String get securityTimeout30s => '30 sec';

  @override
  String get securityTimeout1m => '1 min';

  @override
  String get securityTimeout5m => '5 min';

  @override
  String get securityTimeout15m => '15 min';

  @override
  String get securityLockScreenTitle => 'StitchFlow Locked';

  @override
  String get securityLockScreenSubtitle =>
      'Enter your PIN to access workshop records.';

  @override
  String get securityWrongPinError => 'Incorrect PIN. Please try again.';

  @override
  String securityLockoutCountdown(String remaining) {
    return 'Too many attempts. Try again in $remaining.';
  }

  @override
  String get securityUseBiometricAction => 'Unlock with Biometrics';

  @override
  String get securityBiometricPromptReason =>
      'Unlock StitchFlow workshop records';

  @override
  String get securityBiometricLockoutFallback =>
      'Biometrics temporarily locked by device. Enter your PIN instead.';

  @override
  String get securityBiometricUnavailableFallback =>
      'Biometric unlock unavailable. Enter your PIN.';

  @override
  String get securityBiometricFailedFallback =>
      'Biometric check did not match. Enter your PIN.';

  @override
  String get securityForgotPinAction => 'Forgot PIN?';

  @override
  String get securityRecoveryHeading => 'PIN Recovery';

  @override
  String get securityRecoveryEnterKeyTitle => 'Enter Offline Recovery Key';

  @override
  String get securityRecoveryEnterKeySubtitle =>
      'Enter the 8-character Recovery Key you wrote down when setting up your PIN.';

  @override
  String get securityRecoveryKeyLabel => 'Recovery Key';

  @override
  String get securityVerifyRecoveryKeyAction => 'Verify Recovery Key';

  @override
  String get securityRecoveryKeyInvalidError =>
      'Invalid Recovery Key. Check your code and try again.';

  @override
  String get securityCompleteRecoveryAction => 'Save New PIN & Unlock';

  @override
  String get securityLostBothTitle => 'Lost Both PIN and Recovery Key?';

  @override
  String get securityLostBothBody =>
      'For your privacy, StitchFlow never silently bypasses App Lock. If you have a saved StitchFlow .zip backup, you can clear app data or reinstall and restore your backup.';

  @override
  String get securityVerifyCurrentPinTitle => 'Enter Current PIN';

  @override
  String get securityVerifyChangePinSubtitle =>
      'Confirm your current PIN before choosing a new PIN.';

  @override
  String get securityVerifyDisablePinSubtitle =>
      'Confirm your current PIN before disabling App Lock.';

  @override
  String get securityVerifyRecoveryRegenSubtitle =>
      'Confirm your current PIN to generate a new Recovery Key.';

  @override
  String get securityReauthRequiredTitle => 'Authentication Required';

  @override
  String get securityReauthRestoreSubtitle =>
      'Verify your PIN or fingerprint before restoring a backup.';

  @override
  String get securityReauthRawSqliteSubtitle =>
      'Verify your PIN or fingerprint before exporting the raw SQLite database.';

  @override
  String get securityPrivacyNoteTitle => 'How Local App Lock Works';

  @override
  String get securityPrivacyNoteBody =>
      '• Your PIN is stored only as a salted PBKDF2-HMAC-SHA256 hash inside Android Keystore secure storage — never in plain text, logs, SQLite, or backup ZIPs.\n• App Lock prevents casual unauthorized access on your phone; it does not encrypt the local SQLite database file on disk. Keep Android screen lock enabled and store exported backups safely.';

  @override
  String get dashboardTodayHeading => 'Today\'s Workshop';

  @override
  String get dashboardDailySummaryAction => 'Daily Summary';

  @override
  String get dashboardTodayIssuedLabel => 'Issued Today';

  @override
  String get dashboardTodayReturnedLabel => 'Returned Good Today';

  @override
  String get dashboardTodayLabourLabel => 'Labour Earned Today';

  @override
  String get dashboardTodayPaymentsLabel => 'Payments Today';

  @override
  String get dashboardTodayDamagedLostAlert => 'Damaged / Lost Today';

  @override
  String get dashboardImportantPendingHeading => 'Important Pending Work';

  @override
  String get dashboardViewAllPendingAction => 'View All';

  @override
  String get dailySummaryHeading => 'Daily Production Summary';

  @override
  String get dailySummaryPickDateLabel => 'Select Business Date (IST)';

  @override
  String get dailySummaryDamagedLostLabel => 'Damaged / Lost';

  @override
  String get dailySummaryNoActivityTitle => 'No Workshop Activity Recorded';

  @override
  String get dailySummaryNoActivitySubtitle =>
      'No stock issues, returns, or payments were recorded for this IST date.';

  @override
  String get dailySummaryProcessActivityHeading => 'Process-Wise Activity';

  @override
  String get dailySummaryWorkerActivityHeading => 'Worker-Wise Activity';

  @override
  String get dailySummaryLivePendingNote => 'Current Live Workshop Balances';

  @override
  String get reportPresetToday => 'Today';

  @override
  String get reportPresetYesterday => 'Yesterday';

  @override
  String pendingAgeDaysBadge(int days) {
    return '${days}d pending';
  }

  @override
  String get stockRecentStockSuggestionsLabel =>
      'Recently Used In-Stock Colours';

  @override
  String get stockRecentWorkPairsLabel => 'Recent Process & Worker';

  @override
  String get stockUnusualConfirmTitle => 'Please Confirm Unusual Issue';

  @override
  String stockUnusualFullStockWarning(int qty) {
    return 'You are issuing all $qty available pieces (100% of remaining stock).';
  }

  @override
  String get stockUnusualRateOverrideWarning =>
      'Manual rate override is enabled for this issue.';

  @override
  String stockUnusualBackdatedWarning(int days) {
    return 'Transaction date is backdated by $days days.';
  }

  @override
  String get stockSortOldestFirst => 'Oldest First';

  @override
  String get stockSortHighestPending => 'Highest Pending';

  @override
  String get stockSortNewestFirst => 'Newest First';

  @override
  String get stockShortcutHalf => 'Half';

  @override
  String get stockFillRemainingGood => 'Fill Remaining Good';

  @override
  String get workerWorkOverviewHeading => 'Live Work & Balance Overview';

  @override
  String get workerOpenIssuesCountLabel => 'open issues';

  @override
  String get workerOpenIssuesHeading => 'Open Pending Work';

  @override
  String get workerRecentPaymentsHeading => 'Recent Payments';

  @override
  String get reportPresetThisWeek => 'This Week';

  @override
  String get reportPresetThisMonth => 'This Month';

  @override
  String get reportPresetPreviousMonth => 'Prev. Month';

  @override
  String get reportPresetAllTime => 'All Time';

  @override
  String get reportPresetCustom => 'Custom';

  @override
  String get reportCategoryDaily => 'Daily Workshop';

  @override
  String get reportCategoryWorkers => 'Worker Performance';

  @override
  String get reportCategoryProcesses => 'Process Performance';

  @override
  String get reportCategoryInventory => 'Inventory';

  @override
  String get reportCategoryFinancial => 'Labour & Financial';

  @override
  String get reportCategoryInsights => 'Business Insights';

  @override
  String get reportFiltersButton => 'Filters';

  @override
  String get reportAllOption => 'All';

  @override
  String get reportIncludeReversedLabel => 'Include Reversed Movements';

  @override
  String get reportInvSubSummary => 'Stock Summary';

  @override
  String get reportInvSubLots => 'Lot-Wise';

  @override
  String get reportInvSubColours => 'Design & Colour';

  @override
  String get reportInvSubHistory => 'Movement History';

  @override
  String get reportFinSubLabour => 'Labour Earned';

  @override
  String get reportFinSubSummary => 'Worker Summary';

  @override
  String get reportFinSubPayments => 'Payments';

  @override
  String get reportRefStockValueLabel => 'Reference Stock Value';

  @override
  String get reportRefStockValueNote =>
      'Reference value from good stock × unit cost (not sales or profit).';

  @override
  String get reportLabourCostLabel => 'Labour Cost';

  @override
  String get reportCurrentStandingBadge => 'Current Balance';

  @override
  String get reportPeriodFlowBadge => 'Selected Period';

  @override
  String get reportAvgTurnaroundLabel => 'Avg. Completion Time';

  @override
  String reportTurnaroundSampleCount(int count) {
    return '$count settled issues';
  }

  @override
  String get reportDefectRateLabel => 'Defect / Loss Rate';

  @override
  String get reportWorkerProcessBreakdown => 'Process-Wise Productivity';

  @override
  String get reportProcessWorkerContribution => 'Worker Contributions';

  @override
  String get reportNotAvailable => 'N/A';

  @override
  String get reportInsightsTrendsTitle => 'Production Trends';

  @override
  String get reportInsightsWeeklyNote => 'Grouped by IST week';

  @override
  String get reportInsightsDailyNote => 'Grouped by IST day';

  @override
  String get reportInsightsComparisonTitle => 'Period-over-Period Comparison';

  @override
  String get reportInsightsNoPriorData => 'No prior data';

  @override
  String get reportInsightsBottlenecksTitle => 'Process Bottlenecks';

  @override
  String get reportInsightsNoBottlenecks =>
      'All processes are clear — no pending bottlenecks.';

  @override
  String get reportInsightsWorkerTrendsTitle => 'Top Worker Productivity';

  @override
  String get reportInsightsDefectReasonsTitle => 'Top Damaged / Lost Reasons';

  @override
  String get reportInsightsLabourShareTitle => 'Labour Cost by Process';

  @override
  String get reportExportAction => 'Export / Print';

  @override
  String get reportExportSheetTitle => 'Export & Print Report';

  @override
  String get reportExportPrintPdfTitle => 'Print / Save as PDF';

  @override
  String get reportExportPrintPdfSubtitle =>
      'Gujarati-accurate A4 layout via Android Print dialog.';

  @override
  String get reportExportExcelTitle => 'Export Excel (.xlsx)';

  @override
  String get reportExportExcelSubtitle =>
      'Share current report sheet to WhatsApp, Drive, or Files.';

  @override
  String get reportExportFullWorkbookTitle => 'Full Excel Workbook (.xlsx)';

  @override
  String get reportExportFullWorkbookSubtitle =>
      'All sheets: Daily, Workers, Processes, Inventory, Labour & Payments.';

  @override
  String get reportExportCsvTitle => 'Export CSV (UTF-8)';

  @override
  String get reportExportCsvSubtitle =>
      'Fast Gujarati-compatible CSV for Excel & large datasets.';

  @override
  String reportExportLargeNotice(int rows) {
    return 'This view has $rows rows. Excel or CSV export is recommended over multi-page PDF printing.';
  }

  @override
  String reportExportSuccess(String name) {
    return 'Report exported: $name';
  }

  @override
  String get reportExportPrintOpened => 'Android Print / PDF dialog opened.';

  @override
  String get settingsNotificationsTitle => 'Notifications & Reminders';

  @override
  String get settingsNotificationsSubtitle =>
      'Offline reminders for pending work, karigar settlements, daily recap, and backups.';

  @override
  String get notificationsHeading => 'Notifications & Reminders';

  @override
  String get notificationsStatusTitle => 'Notification Permission';

  @override
  String get notificationsPermGranted => 'Allowed';

  @override
  String get notificationsPermNeeded => 'Permission Needed';

  @override
  String get notificationsPermBlocked => 'Blocked in Settings';

  @override
  String get notificationsPermUnsupported => 'Android Only';

  @override
  String get notificationsStatusGrantedDesc =>
      'Local offline reminders are active on this device. No internet or cloud push is used.';

  @override
  String get notificationsStatusNeededDesc =>
      'Allow notifications so StitchFlow can remind you locally about pending returns, settlements, and backups.';

  @override
  String get notificationsStatusBlockedDesc =>
      'Notifications are turned off in Android Settings. Open Phone Settings -> Apps -> StitchFlow -> Notifications to re-enable.';

  @override
  String get notificationsAllowAction => 'Allow Notifications';

  @override
  String get notificationsSendTestAction => 'Send Test Notification';

  @override
  String get notificationsTestTitle => 'StitchFlow Reminder Check';

  @override
  String get notificationsTestBody =>
      'Local workshop notifications are working properly.';

  @override
  String get notificationsTestSent => 'Test notification sent.';

  @override
  String get notificationsMasterToggle => 'Enable Local Reminders';

  @override
  String get notificationsMasterSubtitle =>
      'Master switch for all scheduled offline reminders.';

  @override
  String get notificationsPendingWorkTitle => 'Pending Work Reminder';

  @override
  String get notificationsPendingWorkDesc =>
      'Reminds you daily if open karigar issues stay pending beyond your chosen age.';

  @override
  String get notificationsPendingDaysLabel => 'Alert when pending at least';

  @override
  String get notificationsSettlementTitle => 'Worker Settlement Reminder';

  @override
  String get notificationsSettlementDesc =>
      'Weekly Saturday reminder when karigars have outstanding payable balances.';

  @override
  String get notificationsMinAmountLabel => 'Minimum payable balance';

  @override
  String get notificationsDailySummaryTitle => 'Daily Workshop Summary';

  @override
  String get notificationsDailySummaryDesc =>
      'Evening reminder to review today\'s issued, returned, and labour recap.';

  @override
  String get notificationsSkipQuietDaysLabel => 'Skip if no activity today';

  @override
  String get notificationsBackupTitle => 'Offline Backup Reminder';

  @override
  String get notificationsBackupDesc =>
      'Reminds you periodically to save a fresh StitchFlow .zip backup.';

  @override
  String get notificationsBackupIntervalLabel => 'Remind every';

  @override
  String get notificationsAlertsTitle => 'Important Local Business Alerts';

  @override
  String get notificationsAlertsDesc =>
      'Local alerts when damaged stock crosses 20 pcs or an issue is 14+ days overdue (max 1 per 24h).';

  @override
  String get notificationsTimeLabel => 'Reminder time';

  @override
  String get notificationsPrivacyOemTitle => 'Offline Privacy & Battery Note';

  @override
  String get notificationsPrivacyOemBody =>
      '• 100% offline: reminders run locally on your Android phone without Firebase or internet.\n• Lock-screen privacy: when App PIN is enabled, notifications hide exact Rupee amounts and worker names.\n• Android battery note: on OPPO (ColorOS), Xiaomi, Vivo, or Samsung phones, allow StitchFlow background notifications in Phone Settings if reminders arrive late after a reboot.';

  @override
  String get validationWhitespaceOnly =>
      'This field cannot contain only spaces.';

  @override
  String validationMaxLength(int max) {
    return 'Maximum $max characters allowed.';
  }

  @override
  String get validationTextTooLong =>
      'Entered text exceeds the allowed length.';

  @override
  String get validationMobileRequired => 'Enter mobile number.';

  @override
  String get validationMobileInvalidIndian =>
      'Enter a valid 10-digit mobile number.';

  @override
  String get validationMobileInvalidChars =>
      'Mobile number contains invalid characters.';

  @override
  String get validationMobileInvalidInternational =>
      'Enter a valid international mobile number with country code.';

  @override
  String get validationEmailInvalid => 'Enter a valid email address.';

  @override
  String get validationInvalidNumber => 'Enter a valid number.';

  @override
  String get validationInvalidInteger => 'Enter a valid whole number.';

  @override
  String get validationInvalidDecimal => 'Enter a valid decimal number.';

  @override
  String validationTooManyDecimals(int maxDecimals) {
    return 'Enter up to $maxDecimals decimal places.';
  }

  @override
  String get validationNegativeNotAllowed => 'Value cannot be negative.';

  @override
  String get validationPositiveNumber => 'Enter a number greater than 0.';

  @override
  String get validationValueTooLarge =>
      'Entered value exceeds the maximum allowed limit.';

  @override
  String get validationNonNegativeInt => 'Enter a whole number 0 or greater.';

  @override
  String validationQuantityExceedsMax(int max) {
    return 'Quantity cannot exceed $max.';
  }

  @override
  String get validationPositiveAmount => 'Enter a valid amount greater than 0.';

  @override
  String get validationInvalidPercentage =>
      'Enter a percentage between 0 and 100.';

  @override
  String get validationInvalidDate => 'Select a valid date.';

  @override
  String get validationDateRangeOrder =>
      'End date cannot be earlier than start date.';

  @override
  String get validationDuplicateValue => 'This value already exists.';

  @override
  String get validationInvalidHexColor =>
      'Enter a valid hex colour code (e.g. #172B4D).';

  @override
  String get validationInvalidPin => 'Enter a valid 4- or 6-digit numeric PIN.';

  @override
  String get validationRecoveryKeyRequired =>
      'Enter your 8-character Recovery Key.';

  @override
  String get validationQuantityBelowCommittedStock =>
      'Initial quantity cannot be less than stock already issued, damaged, or settled.';

  @override
  String get validationWorkerNotFound => 'Selected worker was not found.';

  @override
  String get validationWorkerNotAssigned =>
      'Selected worker is not actively assigned to this process.';

  @override
  String get validationRecordNotFound =>
      'Referenced record was not found or is no longer active.';

  @override
  String get validationOverrideReasonRequired =>
      'Reason is required when overriding the rate.';

  @override
  String get validationParentIssueInactive =>
      'Original stock issue is no longer active.';

  @override
  String get validationAlreadyReversed =>
      'This entry has already been reversed.';

  @override
  String get validationCannotReverseReversal =>
      'A reversal entry cannot itself be reversed.';

  @override
  String validationMinLength(int min) {
    return 'Must be at least $min characters.';
  }

  @override
  String get validationExceedsDispatched =>
      'Received quantity cannot exceed dispatched quantity.';

  @override
  String get validationExceedsHeld =>
      'Transfer quantity cannot exceed quantity currently held by the worker.';

  @override
  String get validationUnaccountedRemaining =>
      'Process cannot be completed while pending quantity remains unaccounted.';

  @override
  String get validationOverpaymentNotAllowed =>
      'Payment amount cannot exceed the remaining payable balance.';

  @override
  String get msgTitleSuccess => 'Success';

  @override
  String get msgTitleError => 'Error';

  @override
  String get msgTitleWarning => 'Warning';

  @override
  String get msgTitleInfo => 'Information';

  @override
  String get msgTitleLoading => 'Working...';

  @override
  String get navProductionHistory => 'Production History';

  @override
  String get navInspectionQueue => 'QC Inspection Queue';

  @override
  String get navWorkerHistory => 'Worker Production';

  @override
  String get navProcessHistory => 'Process History';

  @override
  String get prodHistoryDashboardTitle => 'Production History';

  @override
  String get prodHistoryDashboardSubtitle =>
      'Permanent lot, worker, process & financial ledger tracking';

  @override
  String get prodHistorySearchHint =>
      'Search lot, worker, process, design, colour...';

  @override
  String get prodHistoryOnlyPending => 'Pending Only';

  @override
  String get prodHistoryAllEntries => 'All Entries';

  @override
  String get prodHistoryTotalAssigned => 'Assigned';

  @override
  String get prodHistoryTotalReturned => 'Returned';

  @override
  String get prodHistoryTotalAccepted => 'Accepted';

  @override
  String get prodHistoryTotalRejected => 'Rejected';

  @override
  String get prodHistoryPendingInspection => 'Pending Inspection';

  @override
  String get prodHistoryOutstandingWork => 'Outstanding';

  @override
  String get prodHistoryTotalEarned => 'Total Earned';

  @override
  String get prodHistoryTotalPaid => 'Total Paid';

  @override
  String get prodHistoryOutstandingPayable => 'Outstanding Payable';

  @override
  String get prodHistoryLotHistoryTitle => 'Complete Lot History';

  @override
  String get prodHistoryLotTimelineTitle => 'Lot Timeline';

  @override
  String get prodHistoryViewLotHistory => 'Lot History';

  @override
  String get prodHistoryViewTimeline => 'Lot Timeline';

  @override
  String get prodHistoryWorkerHistoryTitle => 'Worker Production History';

  @override
  String get prodHistoryWorkerLotHistory => 'Worker Lot History';

  @override
  String get prodHistoryWorkerProcessHistory => 'Process-Wise History';

  @override
  String get prodHistoryIncludeInactive => 'Show Inactive';

  @override
  String get prodHistoryProcessHistoryTitle => 'Process-Wise History';

  @override
  String get prodHistoryProcessDetailsTitle => 'Process Production Details';

  @override
  String get prodHistoryTabLotWise => 'Lot-Wise';

  @override
  String get prodHistoryTabWorkerWise => 'Worker-Wise';

  @override
  String get prodHistoryTabDateWise => 'Date-Wise';

  @override
  String get prodHistoryTabPending => 'Pending Work';

  @override
  String get prodHistoryInspectionQueueTitle => 'Returns & QC Inspection';

  @override
  String get prodHistoryTabPendingInspection => 'Pending QC';

  @override
  String get prodHistoryTabRejections => 'Rejections & Repairs';

  @override
  String get prodHistoryApproveAction => 'Inspect & Approve';

  @override
  String get prodHistoryRecordRepairAction => 'Log Repair';

  @override
  String get prodHistoryReinspectAction => 'Re-Inspect & Approve';

  @override
  String get prodHistoryRepairSourceOriginal =>
      'Repaired by Original Worker (Credits Historical Rate)';

  @override
  String get prodHistoryRepairSourceInHouse =>
      'Factory / In-House Repair (No Worker Earning)';

  @override
  String get prodHistoryReturnModePending =>
      'Log as Pending Inspection (₹0 until QC approves)';

  @override
  String get prodHistoryReturnModeImmediate =>
      'Return & Inspect Immediately (Generates Accepted Earnings)';

  @override
  String get prodHistoryTxDetailTitle => 'Transaction Details';

  @override
  String get prodHistoryOpenLot => 'Open Lot';

  @override
  String get prodHistoryOpenWorker => 'Open Worker';

  @override
  String get prodHistoryOpenProcess => 'Open Process';

  @override
  String get prodHistoryLockedRateSnapshot => 'Locked Rate Snapshot';

  @override
  String get prodHistoryAuditTrail => 'Audit Trail';

  @override
  String get prodHistoryRelatedRecords => 'Linked Transactions';

  @override
  String get prodHistoryInitialAssignmentsTitle =>
      '3. Initial Process Assignments (Optional)';

  @override
  String get prodHistoryInitialAssignmentsSubtitle =>
      'Optionally assign processes, workers, quantities & locked rates while creating the lot.';

  @override
  String get prodHistoryAddAssignmentAction => 'Add Assignment';

  @override
  String get prodHistoryApprovalAuthTitle => 'Authorize Approval';

  @override
  String get prodHistoryApprovalAuthSubtitle =>
      'Verify PIN or biometrics to approve accepted quantities and credit worker earnings.';

  @override
  String get securityRequireApprovalAuthLabel =>
      'Require PIN for Return Approvals';

  @override
  String get securityRequireApprovalAuthSubtitle =>
      'Prompt for PIN/biometrics when approving returned or repaired quantities.';

  @override
  String get settingsFinalPaymentRuleTitle =>
      'Finalized Earnings Rule (Active)';

  @override
  String get settingsFinalPaymentRuleBody =>
      'Worker earnings are calculated strictly as Accepted Quantity × Historical Assigned Rate. Legacy GIVEN_QTY and Damaged-in-Labour settings are retired for all new transactions while historical records remain preserved.';

  @override
  String get validationExceedsPendingInspection =>
      'Inspected quantity exceeds remaining pending inspection quantity.';

  @override
  String get validationExceedsReturnedQty =>
      'Accepted + Rejected cannot exceed returned quantity.';

  @override
  String get validationExceedsRejectedQty =>
      'Quantity cannot exceed open rejected quantity.';

  @override
  String get validationExceedsRepairedQty =>
      'Re-inspected quantity cannot exceed pending repaired quantity.';

  @override
  String get validationLotUnreconciled =>
      'Cannot mark lot completed while pieces are still with workers or pending QC inspection.';

  @override
  String get navDesignsColours => 'Designs & Colours';

  @override
  String get designsColoursSubtitle =>
      'Search designs, manage saved colours & view historical lot prices';

  @override
  String get designsTabLabel => 'Designs';

  @override
  String get coloursTabLabel => 'Colour Catalog';

  @override
  String get colourHexLabel => 'Hex Code (e.g. #DC2626)';

  @override
  String get colourSavedSuccess => 'Colour saved to catalog.';

  @override
  String get coloursEmptyTitle => 'No Saved Colours Yet';

  @override
  String get coloursEmptySubtitle =>
      'Add reusable workshop colours with swatches for faster lot creation.';

  @override
  String get historicalPricePreservedNote =>
      'Historical lot prices stay locked to each lot and are never overwritten.';

  @override
  String get webBackupExportAction => 'Download Web Backup (.json)';

  @override
  String get webBackupExportDesc =>
      'Downloads a verified offline snapshot of all local workshop records from this browser.';

  @override
  String get webBackupRestoreAction => 'Restore Web Backup (.json)';

  @override
  String get webBackupRestoreDesc =>
      'Validates checksum and schema before restoring all records into this browser\'s offline database.';

  @override
  String get webPrintFallbackNote =>
      'Opened browser print dialog (use Save as PDF to download).';
}
