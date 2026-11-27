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
  String get environmentFlavorLabel => 'Flavor';

  @override
  String get environmentFlavorDev => 'Development';

  @override
  String get environmentFlavorProd => 'Production';

  @override
  String get environmentDatabaseLabel => 'Database File';

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
  String get validationRequired => 'This field is required.';

  @override
  String get statusGood => 'Good Stock';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusDamaged => 'Damaged';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navLots => 'Lots';

  @override
  String get navInventory => 'Inventory';

  @override
  String get dashboardQuickActions => 'Quick Actions';

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
  String get actionDelete => 'Remove';

  @override
  String get actionClose => 'Close';

  @override
  String get piecesUnit => 'pcs';

  @override
  String get navProcesses => 'Work Stages';

  @override
  String get navWorkStagesShort => 'Stages';

  @override
  String get processQuickCreateAction => 'New Work Stage';

  @override
  String get settingsManageWorkStagesAction => 'Manage Work Stages';

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
  String get processesHeading => 'Work Stages';

  @override
  String get processesSearchHint => 'Search work stages by name or description';

  @override
  String get processesEmptyTitle => 'No Work Stages Yet';

  @override
  String get processesEmptySubtitle =>
      'Create your own work stages in any order your workshop uses.';

  @override
  String get processCreateAction => 'New Work Stage';

  @override
  String get processEditAction => 'Edit Work Stage';

  @override
  String get processDetailsHeading => 'Work Stage Details';

  @override
  String get processNameLabel => 'Work Stage Name';

  @override
  String get processDescriptionLabel => 'Description (Optional)';

  @override
  String get processBillingOverrideLabel => 'Labour Billing Mode';

  @override
  String get processBillingInheritGlobal => 'Use Business Default';

  @override
  String get processIncludeDamagedLabel => 'Include damaged pieces in labour';

  @override
  String get processActivateAction => 'Activate Work Stage';

  @override
  String get processDeactivateAction => 'Deactivate Work Stage';

  @override
  String get processDeactivateConfirmTitle => 'Deactivate Work Stage?';

  @override
  String get processDeactivateConfirmMessage =>
      'Historical records remain intact, but new assignments and issues will be blocked while inactive.';

  @override
  String get processDuplicateNameError =>
      'A work stage with this name already exists.';

  @override
  String get processAssignedWorkersHeading => 'Assigned Workers';

  @override
  String get processNoAssignedWorkers =>
      'No workers are currently assigned to this work stage.';

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
      'Add your workshop workers to assign work stages and configure per-piece rates.';

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
      'Assigned Work Stages & Current Rates';

  @override
  String get workerNoAssignedProcesses => 'No work stages assigned yet.';

  @override
  String get workerManageAssignmentsAction => 'Manage Assignments';

  @override
  String get workerViewRateHistoryAction => 'Rate History';

  @override
  String get workerAddRateAction => 'Add Rate';

  @override
  String get assignmentsHeading => 'Worker Stage Assignments';

  @override
  String get assignmentsSubtitle =>
      'A worker can be assigned to multiple work stages with no fixed sequence.';

  @override
  String get assignmentsAddLabel => 'Select Active Work Stage';

  @override
  String get assignmentsAddAction => 'Assign Work Stage';

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
      'Assign one or more active work stages to this worker.';

  @override
  String get assignmentsNoAvailableProcesses =>
      'All active work stages are already assigned or no active work stages exist.';

  @override
  String get assignmentsDuplicateError =>
      'This work stage is already assigned to the worker.';

  @override
  String get assignmentsInactiveWorkerError =>
      'Activate this worker before adding work stage assignments.';

  @override
  String get assignmentsInactiveProcessError =>
      'Only active work stages can be assigned.';

  @override
  String get ratesHistoryHeading => 'Per-Piece Rate History';

  @override
  String get ratesFilterProcessLabel => 'Work Stage';

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
      'Add an effective-dated per-piece rate for this worker and work stage.';

  @override
  String get ratesSelectProcessHint => 'Select Work Stage';

  @override
  String get ratesAutoCloseTitle => 'Close Previous Ongoing Rate?';

  @override
  String get ratesAutoCloseMessage =>
      'An ongoing rate exists for this work stage. Saving will close it on the previous day and start the new rate from your chosen date.';

  @override
  String get ratesOverlapError =>
      'This date range overlaps with an existing rate.';

  @override
  String get ratesMultipleOpenEndedError =>
      'Another ongoing rate already exists for this worker and work stage.';

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
  String get stockTabBalances => 'Live Stock';

  @override
  String get stockTabWorkers => 'By Worker';

  @override
  String get stockTabProcesses => 'By Work Stage';

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
  String get stockSelectColourLabel => 'Select Colour';

  @override
  String get stockIssueQuantityLabel => 'Issue Quantity (pcs)';

  @override
  String get stockTransactionDateTimeLabel => 'Transaction Date & Time (IST)';

  @override
  String get stockResolvedRateLabel => 'Locked Per-Piece Rate';

  @override
  String get stockRateMissingWarning =>
      'No effective historical rate exists for this worker and work stage on the chosen IST date.';

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
  String get stockNoEligibleWorkers =>
      'No active workers are assigned to this work stage.';

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
      'Issue stock to a worker and work stage to start tracking movements.';

  @override
  String get stockSearchHint =>
      'Search lot, design, colour, worker, work stage...';

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
  String get accountingRegularPaidLabel => 'Regular Payments';

  @override
  String get accountingAdvancePaidLabel => 'Advances Paid';

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
  String get dashboardStockHealth => 'Inventory & Production Health';

  @override
  String get dashboardFinanceHealth => 'Worker Accounting Summary';

  @override
  String get dashboardProcessPending => 'Stage-Wise Pending Work';

  @override
  String get dashboardRecentActivity => 'Recent Audit Activity';

  @override
  String get dashboardNoProcessPending =>
      'No pending stock across work stages.';

  @override
  String get dashboardNoRecentActivity => 'No activity logged yet.';

  @override
  String get dashboardTotalLotsLabel => 'Active Lots';

  @override
  String get dashboardTotalDesignsColoursLabel => 'Designs / Colours';

  @override
  String get reportsHeading => 'Business Reports';

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
      'Global billing rule and per-stage labour override overview.';

  @override
  String get settingsGlobalBillingExplanationReceived =>
      'Workers earn labour when returned good pieces are recorded. Damaged pieces are excluded unless enabled on a specific work stage.';

  @override
  String get settingsGlobalBillingExplanationGiven =>
      'Workers earn labour immediately when stock is issued to them. Return entries stay informational to prevent double-counting.';

  @override
  String get settingsProcessOverridesTitle => 'Stage-Level Rules';

  @override
  String get settingsProcessOverridesSubtitle =>
      'Each work stage inherits the global billing mode unless overridden. Tap any work stage to configure.';

  @override
  String get settingsProcessInheritsGlobal => 'Inherits Global Default';

  @override
  String get settingsProcessOverridesGlobal => 'Work Stage Override';

  @override
  String get settingsDamagedIncludedShort => 'Damaged Included';

  @override
  String get settingsDamagedExcludedShort => 'Damaged Excluded';

  @override
  String get settingsNoProcessesYet => 'No work stages created yet.';

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
  String get stockChangeSelection => 'Change';

  @override
  String get stockActiveProcessesLabel => 'Active Work Stage';

  @override
  String get stockEligibleWorkersLabel => 'Eligible Assigned Worker';

  @override
  String get stockNoActiveProcessesWarning =>
      'No active work stages exist. Create a work stage before issuing stock.';

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
  String get stockFilterAllProcesses => 'All Work Stages';

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
      'Issue Returned Stock to Next Work Stage';

  @override
  String get stockReceiveAnotherReturnAction => 'Receive Another Return';

  @override
  String get stockTabPendingReturns => 'Pending Returns';

  @override
  String get stockTabMovementHistory => 'Movement History';

  @override
  String get stockTabSummary => 'Worker & Work Stage';

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
  String get dailySummaryProcessActivityHeading => 'Stage-Wise Activity';

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
  String get stockRecentWorkPairsLabel => 'Recent Work Stage & Worker';

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
  String get reportCategoryProcesses => 'Work Stage Performance';

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
  String get reportWorkerProcessBreakdown => 'Stage-Wise Productivity';

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
  String get reportInsightsBottlenecksTitle => 'Work Stage Bottlenecks';

  @override
  String get reportInsightsNoBottlenecks =>
      'All work stages are clear — no pending bottlenecks.';

  @override
  String get reportInsightsWorkerTrendsTitle => 'Top Worker Productivity';

  @override
  String get reportInsightsDefectReasonsTitle => 'Top Damaged / Lost Reasons';

  @override
  String get reportInsightsLabourShareTitle => 'Labour Cost by Work Stage';

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
      'All sheets: Daily, Workers, Work Stages, Inventory, Labour & Payments.';

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
      'Selected worker is not actively assigned to this work stage.';

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
      'Work Stage cannot be completed while pending quantity remains unaccounted.';

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
  String get navPressBackAgainToExit => 'Press back again to exit';

  @override
  String get navProductionHistory => 'Production History';

  @override
  String get navInspectionQueue => 'QC Inspection Queue';

  @override
  String get navWorkerHistory => 'Worker Production';

  @override
  String get navProcessHistory => 'Work Stage History';

  @override
  String get prodHistoryDashboardTitle => 'Production History';

  @override
  String get prodHistoryDashboardSubtitle =>
      'Permanent lot, worker, work stage & financial ledger tracking';

  @override
  String get prodHistorySearchHint =>
      'Search lot, worker, work stage, design, colour...';

  @override
  String get prodHistoryOnlyPending => 'Pending Only';

  @override
  String get prodHistoryAllEntries => 'All Entries';

  @override
  String get prodHistoryTotalAssigned => 'Assigned';

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
  String get prodHistoryWorkerProcessHistory => 'Stage-Wise History';

  @override
  String get prodHistoryIncludeInactive => 'Show Inactive';

  @override
  String get prodHistoryProcessHistoryTitle => 'Stage-Wise History';

  @override
  String get prodHistoryProcessDetailsTitle => 'Work Stage Production Details';

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
  String get prodHistoryOpenProcess => 'Open Work Stage';

  @override
  String get prodHistoryLockedRateSnapshot => 'Locked Rate Snapshot';

  @override
  String get prodHistoryAuditTrail => 'Audit Trail';

  @override
  String get prodHistoryRelatedRecords => 'Linked Transactions';

  @override
  String get prodHistoryInitialAssignmentsTitle =>
      '3. Initial Work Stage Assignments (Optional)';

  @override
  String get prodHistoryInitialAssignmentsSubtitle =>
      'Optionally assign work stages, workers, quantities & locked rates while creating the lot.';

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
  String get uxUndo => 'Undo';

  @override
  String uxShowMore(int count) {
    return 'Show $count more';
  }

  @override
  String get uxShowLess => 'Show less';

  @override
  String get uxUnsavedTitle => 'Discard changes?';

  @override
  String get uxUnsavedMessage =>
      'You have changes that are not saved. If you leave now they will be lost.';

  @override
  String get uxUnsavedDiscard => 'Discard';

  @override
  String get uxUnsavedKeepEditing => 'Keep editing';

  @override
  String get uxSearchTooltip => 'Search (Ctrl+K)';

  @override
  String get uxSearchHint => 'Search lots, workers, work stages…';

  @override
  String get uxSearchLots => 'Lots';

  @override
  String get uxSearchWorkers => 'Workers';

  @override
  String get uxSearchProcesses => 'Work Stages';

  @override
  String uxSearchNoResults(String query) {
    return 'No matches for \"$query\"';
  }

  @override
  String get uxQuickActions => 'Quick actions';

  @override
  String get uxActionNewLot => 'New lot';

  @override
  String get uxActionIssueStock => 'Issue stock to worker';

  @override
  String get uxActionReceiveWork => 'Receive work back';

  @override
  String get uxActionRecordPayment => 'Record payment';

  @override
  String get uxActionAddWorker => 'Add worker';

  @override
  String get uxActionInspections => 'Inspection queue';

  @override
  String uxPerPage(int count) {
    return '$count / page';
  }

  @override
  String get uxFilters => 'Filters';

  @override
  String uxFiltersActive(int count) {
    return 'Filters ($count)';
  }

  @override
  String get uxMoreScreens => 'More screens';

  @override
  String get authSignInHeading => 'Sign In to Cloud Sync';

  @override
  String get authSignInSubtitle =>
      'Sign in with Google or your mobile number to sync your workshop data across devices. Works 100% offline anytime.';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithPhone => 'Continue with Phone Number';

  @override
  String get authContinueOffline => 'Continue Offline (Local Only)';

  @override
  String get authPhoneLabel => 'Mobile Number';

  @override
  String get authPhoneHint => '+91 98765 43210';

  @override
  String get authSendOtpAction => 'Send OTP';

  @override
  String get authOtpLabel => '6-Digit OTP Code';

  @override
  String get authOtpHint => '123456';

  @override
  String authOtpSentMessage(String phone) {
    return 'Verification code sent to $phone';
  }

  @override
  String get authVerifyOtpAction => 'Verify & Sign In';

  @override
  String get authChangePhoneAction => 'Change Number';

  @override
  String get authInvalidPhoneError =>
      'Enter a valid 10-digit mobile number or E.164 number.';

  @override
  String get authCloudNotConfiguredBanner =>
      'Cloud sync keys are not configured in this build. You can continue using StitchFlow 100% offline.';

  @override
  String get authAccountTitle => 'Account & Cloud Sync';

  @override
  String get authOfflineModeBadge => 'Offline Mode';

  @override
  String get authSignedInBadge => 'Signed In';

  @override
  String get authSignInPromptCardSubtitle =>
      'Sign in with Google or Phone OTP to back up and sync across devices';

  @override
  String get authLinkedIdentitiesHeading => 'Linked Login Methods';

  @override
  String get authGoogleProvider => 'Google Account';

  @override
  String get authPhoneProvider => 'Phone Number';

  @override
  String get authLinkedStatus => 'Linked';

  @override
  String get authNotLinkedStatus => 'Not linked';

  @override
  String get authLinkAction => 'Link';

  @override
  String get authLinkedDevicesHeading => 'Synced Devices';

  @override
  String get authCurrentDeviceBadge => 'This device';

  @override
  String get authNoDevicesYet => 'No cloud devices registered yet.';

  @override
  String get authSignOutAction => 'Sign Out';

  @override
  String get authSignOutConfirmTitle => 'Sign out of Cloud Sync?';

  @override
  String get authSignOutConfirmBody =>
      'Your local workshop data stays safely on this device, and cloud sync will pause until you sign in again.';

  @override
  String authSignOutUnsyncedWarning(int count) {
    return 'You have $count unsynced local changes. Sync before signing out so nothing is left behind.';
  }

  @override
  String get authSyncAndSignOutAction => 'Sync & Sign Out';

  @override
  String get authSignOutAnywayAction => 'Sign Out Anyway';

  @override
  String get syncCenterTitle => 'Cloud Sync Center';

  @override
  String get syncCenterSubtitle =>
      'Offline-first bidirectional sync with Supabase';

  @override
  String get syncStatusLocalOnly => 'Local Only';

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusSyncing => 'Syncing…';

  @override
  String get syncStatusNeedsAttention => 'Needs Attention';

  @override
  String get syncNowAction => 'Sync Now';

  @override
  String get syncRetryFailedAction => 'Retry Failed';

  @override
  String get syncLastSyncedLabel => 'Last synced';

  @override
  String get syncNeverSynced => 'Not synced yet';

  @override
  String get syncPendingRowsLabel => 'Pending data changes';

  @override
  String get syncPendingMediaLabel => 'Pending photo uploads/downloads';

  @override
  String get syncFailedItemsHeading => 'Items Needing Retry';

  @override
  String get syncMergeTitle => 'Data Found in Both Places';

  @override
  String syncMergeSubtitle(int localCount, int cloudCount) {
    return 'This device has $localCount local records and your cloud account has $cloudCount records. How would you like to proceed?';
  }

  @override
  String get syncMergeBothAction => 'Merge Local + Cloud (Recommended)';

  @override
  String get syncMergeBothDesc =>
      'Combines all ledgers safely and keeps the newest edits for lots, workers, and work stages.';

  @override
  String get syncKeepCloudAction => 'Keep Cloud Only';

  @override
  String get syncKeepCloudDesc =>
      'Replaces this device\'s local records with your cloud account data.';

  @override
  String get syncKeepLocalAction => 'Keep Local & Push to Cloud';

  @override
  String get syncKeepLocalDesc =>
      'Uploads all local records from this device to your cloud account.';

  @override
  String get securityCloudRecoveryTitle => 'Or Reset PIN via Cloud Account';

  @override
  String get securityCloudRecoverySubtitle =>
      'Re-verify your signed-in Google account to reset your local App Lock PIN without losing data.';

  @override
  String get securityVerifyWithGoogleAction => 'Verify with Google';

  @override
  String get securityCloudReauthFailed =>
      'Cloud account verification did not match the signed-in owner.';

  @override
  String get stockPendingQcLabel => 'Pending QC';

  @override
  String get settingsDataHealthTitle => 'Data Health & Diagnostics';

  @override
  String get settingsDataHealthSubtitle =>
      'Verify SQLite integrity, stock equations, ledger parity & sync queue';

  @override
  String get dataHealthHeading => 'Data Health Center';

  @override
  String get dataHealthSubtitle =>
      'Non-destructive integrity & reconciliation checks on your local StitchFlow database.';

  @override
  String get dataHealthRunCheckAction => 'Run Health Check';

  @override
  String get dataHealthShareReportAction => 'Share Diagnostic Report';

  @override
  String get dataHealthStatusHealthy => 'All Checks Healthy';

  @override
  String get dataHealthStatusWarning => 'Minor Attention Needed';

  @override
  String get dataHealthStatusCritical => 'Integrity Issues Found';

  @override
  String get dataHealthCheckedAtLabel => 'Last Checked';

  @override
  String get dataHealthDbSizeLabel => 'Database Size';

  @override
  String get dataHealthSqliteIntegrityLabel => 'SQLite Integrity';

  @override
  String get dataHealthSqliteOk => 'Verified OK';

  @override
  String get dataHealthSqliteFailed => 'Integrity Error';

  @override
  String get dataHealthForeignKeysLabel => 'Foreign Key Integrity';

  @override
  String get dataHealthZeroViolations => '0 Violations';

  @override
  String dataHealthViolationsCount(int count) {
    return '$count Violations';
  }

  @override
  String get dataHealthStockReconciliationLabel => 'Golden Stock Equation';

  @override
  String dataHealthStockAllReconciled(int count) {
    return 'All $count colours reconciled';
  }

  @override
  String dataHealthStockIssuesCount(int count) {
    return '$count mismatches found';
  }

  @override
  String get dataHealthLedgerParityLabel => 'Worker Ledger Parity';

  @override
  String get dataHealthLedgerParityOk => '0 Parity Issues';

  @override
  String get dataHealthSyncQueueLabel => 'Sync Outbox & Media Queue';

  @override
  String dataHealthSyncQueueSummary(int pending, int failed) {
    return '$pending pending • $failed failed';
  }

  @override
  String get dataHealthMediaParityLabel => 'Private Media Parity';

  @override
  String dataHealthMediaParitySummary(int orphans, int missing) {
    return '$orphans orphan • $missing missing';
  }

  @override
  String get dataHealthMaintenanceHeading => 'Safe Audited Maintenance';

  @override
  String get dataHealthWalCheckpointAction => 'Run WAL Checkpoint';

  @override
  String get dataHealthWalCheckpointDesc =>
      'Flushes SQLite write-ahead log cleanly into the main database file.';

  @override
  String get dataHealthWalCheckpointSuccess =>
      'WAL checkpoint completed and logged.';

  @override
  String get dataHealthCleanOrphansAction => 'Clean Orphan Media Files';

  @override
  String get dataHealthCleanOrphansDesc =>
      'Removes unreferenced local photo files without touching active attachments.';

  @override
  String dataHealthCleanOrphansSuccess(int count) {
    return 'Cleaned $count orphan media file(s).';
  }

  @override
  String get dataHealthRetrySyncAction => 'Reset Failed Sync Entries';

  @override
  String get dataHealthRetrySyncDesc =>
      'Re-queues failed sync outbox & media entries for immediate retry.';

  @override
  String dataHealthRetrySyncSuccess(int count) {
    return 'Re-queued $count failed sync entry(ies).';
  }

  @override
  String get routingTitle => 'Work Stage Routing';

  @override
  String get routingRefreshTooltip => 'Refresh';

  @override
  String get routingLoadErrorTitle => 'Unable to load Job Routing';

  @override
  String get routingAddProcessAction => 'Add Work Stage';

  @override
  String get routingReassignFromFactoryAction => 'Reassign from Factory';

  @override
  String get routingAddOperationTitle => 'Add Work Stage to Lot';

  @override
  String get routingVariantLabel => 'Variant (Design / Colour)';

  @override
  String get routingOperationLabel => 'Work Stage';

  @override
  String get routingAssignWorkerLabel => 'Assign Worker / Department';

  @override
  String get routingPricingUnitLabel => 'Pricing Unit';

  @override
  String get routingRateOverrideReasonLabel =>
      'Reason for Changing Default Rate (Required)';

  @override
  String get routingDispatchImmediatelyTitle =>
      'Dispatch immediately from Factory';

  @override
  String get routingDispatchImmediatelySubtitle =>
      'Turn off to save as Pending and dispatch later';

  @override
  String get routingNotesOptionalLabel => 'Notes (Optional)';

  @override
  String get routingConfirmReassignmentAction => 'Confirm Reassignment';

  @override
  String get routingAddDispatchAction => 'Add & Dispatch Work Stage';

  @override
  String get routingSavePendingAction => 'Save Pending Work Stage';

  @override
  String get routingAddColourFirstError =>
      'Add at least one Colour or Design variant to this Lot first.';

  @override
  String get routingAddProcessWorkerFirstError =>
      'Please create at least one active Work Stage and Worker first.';

  @override
  String get routingInvalidQuantityError =>
      'Enter a valid positive whole quantity.';

  @override
  String get routingInvalidRateError =>
      'Enter a valid non-negative rate (max 2 decimals).';

  @override
  String get routingOperationAddedSuccess => 'Operation added successfully.';

  @override
  String get routingDirectTransferTitle => 'Direct Worker-to-Worker Transfer';

  @override
  String get routingNextOperationLabel => 'Next Work Stage';

  @override
  String get routingDestinationWorkerLabel => 'Destination Worker / Department';

  @override
  String get routingMarkReceivedImmediatelyTitle => 'Mark received immediately';

  @override
  String get routingTransferNotesLabel => 'Transfer Notes (Optional)';

  @override
  String get routingConfirmDirectTransferAction => 'Confirm Direct Transfer';

  @override
  String get routingInvalidTransferQtyError =>
      'Enter a valid positive transfer quantity.';

  @override
  String get routingInvalidDestRateError =>
      'Enter a valid destination rate (max 2 decimals).';

  @override
  String get routingReturnToFactoryTitle => 'Return to Factory';

  @override
  String get routingGoodReturnedLabel => 'Good Quantity Returned to Factory';

  @override
  String get routingDamagedOptionalLabel => 'Damaged Quantity (Optional)';

  @override
  String get routingVerificationNotesLabel => 'Verification Notes (Optional)';

  @override
  String get routingConfirmFactoryReturnAction => 'Confirm Factory Return';

  @override
  String get routingAddChargeTitle => 'Add Extra Charge / Deduction';

  @override
  String get routingChargeTypeLabel => 'Type';

  @override
  String get routingChargeDescLabel =>
      'Description (e.g. Urgent work, Special cutting)';

  @override
  String get routingInvalidAmountError =>
      'Enter a valid positive amount (max 2 decimals).';

  @override
  String get routingConfirmReceiptTitle => 'Confirm Material Receipt';

  @override
  String get routingConfirmReceiptAction => 'Confirm Receipt';

  @override
  String get routingInvalidReceivedQtyError =>
      'Enter a valid positive received quantity.';

  @override
  String get routingCancelReasonLabel => 'Cancellation Reason';

  @override
  String get routingKeepAction => 'Keep';

  @override
  String get routingCancelProcessAction => 'Cancel Work Stage';

  @override
  String get routingFactoryReadyLabel => 'Factory Ready';

  @override
  String get routingWithWorkersLabel => 'With Workers';

  @override
  String get routingTotalProductionCostLabel => 'Total Production Cost';

  @override
  String get routingOutstandingPayableLabel => 'Outstanding Payable';

  @override
  String get routingWorkerPayableSummaryHeading => 'Worker Payable Summary';

  @override
  String get routingCurrentGoodsLocationHeading => 'Current Goods Location';

  @override
  String get routingNoOperationsTitle => 'No Operations Added Yet';

  @override
  String get routingNoOperationsForColourTitle =>
      'No Operations for Selected Colour';

  @override
  String get routingNoOperationsSubtitle =>
      'Assign Cutting, Stitching, Checking, Finishing, Ironing, or Packing at variant level with custom worker rates.';

  @override
  String get routingNoHandoversSubtitle =>
      'Dispatches, direct transfers, returns, and reassignments will appear here chronologically.';

  @override
  String get routingUnassignedWorker => 'Unassigned';

  @override
  String get routingDirectTransferAction => 'Direct Transfer';

  @override
  String get routingReturnToFactoryAction => 'Return to Factory';

  @override
  String get routingPayAction => 'Pay';

  @override
  String get routingMarkCompletedAction => 'Mark Completed';

  @override
  String get routingCancelAction => 'Cancel';

  @override
  String get routingErrJobNotFound => 'Job / Lot not found.';

  @override
  String get routingErrNotReady => 'Not ready';

  @override
  String get routingErrExceedsFactoryStock =>
      'Quantity exceeds available in-house factory stock.';

  @override
  String get routingErrExceedsDispatched =>
      'Received quantity cannot exceed dispatched quantity.';

  @override
  String get routingErrExceedsWorkerStock =>
      'Transfer quantity exceeds stock currently held by this worker.';

  @override
  String get routingErrExceedsReturnable =>
      'Return quantity exceeds outstanding worker quantity.';

  @override
  String get routingErrPendingRemaining =>
      'Cannot complete work stage while pending quantity remains unaccounted.';

  @override
  String get routingErrHeldPiecesCancel =>
      'Return or transfer all held pieces before cancelling this work stage.';

  @override
  String get routingErrSameWorkerProcess =>
      'Select a different destination worker or operation for direct transfer.';

  @override
  String get routingErrRateOverrideReason =>
      'Please enter a reason when changing the agreed rate from the default.';

  @override
  String get routingErrPaymentExceedsPayable =>
      'Payment amount cannot exceed remaining outstanding payable.';

  @override
  String get routingErrDescriptionRequired =>
      'Please enter a charge description.';

  @override
  String get routingErrReasonRequired => 'Please enter a reason.';

  @override
  String get routingErrProcessRequired => 'Select a work stage.';

  @override
  String get routingErrWorkerRequired => 'Select a worker.';

  @override
  String get routingErrSkuRequired => 'Select a design & colour.';

  @override
  String get routingErrAlreadyClosed => 'This operation is already closed.';

  @override
  String get slipShareSheetTitle => 'Share Karigar Slip';

  @override
  String get slipShareChallanAction => 'Share Issue Challan';

  @override
  String get slipShareReturnAction => 'Share Return / QC Slip';

  @override
  String get slipShareKhataAction => 'Share Khata Statement';

  @override
  String get slipShareImageAction => 'Share Image (PNG)';

  @override
  String get slipShareTextAction => 'Share Text (WhatsApp)';

  @override
  String get slipCopyTextAction => 'Copy Text';

  @override
  String get slipPrintPdfAction => 'Print / Save PDF';

  @override
  String get slipLanguageLabel => 'Slip Language';

  @override
  String get slipCopiedMessage => 'Slip text copied to clipboard.';

  @override
  String get slipGeneratedSuccess => 'Slip ready to share.';

  @override
  String get draftRestoredBanner => 'Unfinished draft restored.';

  @override
  String get draftClearAction => 'Clear Draft';

  @override
  String get setupChecklistTitle => 'Workshop Setup Checklist';

  @override
  String get setupChecklistSubtitle =>
      'Complete these 4 quick steps to start tracking production.';

  @override
  String get setupChecklistDismissAction => 'Dismiss';

  @override
  String get setupStepProfile => 'Customize Business Profile';

  @override
  String get setupStepProcesses => 'Create Work Stages';

  @override
  String get setupStepWorkers => 'Add Workers & Rates';

  @override
  String get setupStepFirstLot => 'Create Your First Lot';

  @override
  String get densitySectionTitle => 'Layout Density';

  @override
  String get densityComfortable => 'Comfortable (Default)';

  @override
  String get densityCompact => 'Compact (More Rows on Screen)';

  @override
  String get settingsTeamTitle => 'Team & Role Access';

  @override
  String get settingsTeamSubtitle =>
      'Invite supervisors, QC inspectors & accountants with role permissions';

  @override
  String get teamHeading => 'Team Management';

  @override
  String get teamMembersSection => 'Workspace Members';

  @override
  String get teamInvitesSection => 'Invite Codes';

  @override
  String get teamCreateInviteAction => 'Create Invite Code';

  @override
  String get teamJoinWorkspaceAction => 'Join a Workshop via Code';

  @override
  String get teamInviteCodeLabel => '8-Character Invite Code';

  @override
  String get teamInviteCodeHint => 'e.g. SF7K-9M2P';

  @override
  String get teamInvitePhoneOptionalLabel => 'Restrict to Phone (Optional)';

  @override
  String get teamInviteEmailOptionalLabel => 'Restrict to Email (Optional)';

  @override
  String get teamShareInviteWhatsAppAction => 'Share Code on WhatsApp';

  @override
  String get teamRevokeAction => 'Revoke';

  @override
  String get teamRoleOwner => 'Owner';

  @override
  String get teamRoleManager => 'Manager / Supervisor';

  @override
  String get teamRoleQcInspector => 'QC Inspector';

  @override
  String get teamRoleAccountant => 'Accountant';

  @override
  String get teamSignInRequiredSubtitle =>
      'Sign in to Cloud Sync to invite team members or join another workshop.';

  @override
  String get teamNoInvitesEmpty => 'No active invite codes yet.';

  @override
  String get teamJoinSuccess => 'Joined workshop successfully.';

  @override
  String get teamInviteCreatedSuccess =>
      'Invite code created and ready to share.';

  @override
  String get syncConflictsTitle => 'Sync Conflict Inspector';

  @override
  String get syncConflictsOpenAction => 'Review Conflicts';

  @override
  String get syncConflictsEmptyTitle => 'No Sync Conflicts';

  @override
  String get syncConflictsEmptySubtitle =>
      'All devices and team edits have merged cleanly.';

  @override
  String get syncConflictLocalLabel => 'Your Superseded Edit';

  @override
  String get syncConflictCloudLabel => 'Applied Cloud Version';

  @override
  String get syncConflictKeepCloudAction => 'Keep Cloud';

  @override
  String get syncConflictRestoreLocalAction => 'Restore My Edit';

  @override
  String get syncConflictStatusUnresolved => 'Needs Review';

  @override
  String get syncConflictStatusAcknowledged => 'Kept Cloud';

  @override
  String get syncConflictStatusRestored => 'Restored';

  @override
  String get syncConflictRestoredSuccess =>
      'Superseded edit restored as a new audited update.';

  @override
  String get syncConflictAcknowledgedSuccess => 'Conflict marked as resolved.';

  @override
  String get guideTitle => 'Interactive Guide';

  @override
  String get guideTooltip => 'Screen Guide & Training';

  @override
  String get guideWelcomeTitle => 'Welcome to Business Manager';

  @override
  String get guideWelcomeSubtitle =>
      'Learn how your entire garment workshop works step by step — right inside the app, with voice guidance and zero videos.';

  @override
  String get guideStartFullTraining => 'Start Complete Training';

  @override
  String get guideResumeTraining => 'Resume Training';

  @override
  String get guideRestartTraining => 'Restart Full Training';

  @override
  String get guideTourThisScreen => 'Explain This Screen';

  @override
  String get guideOpenUserGuide => 'Open Complete User Guide';

  @override
  String get guideSkipForNow => 'Skip for now';

  @override
  String get guideVoiceOn => 'Voice ON';

  @override
  String get guideVoiceOff => 'Voice OFF';

  @override
  String get guideVoiceReplay => 'Replay';

  @override
  String get guideVoiceListen => 'Listen';

  @override
  String get guideVoiceStop => 'Stop';

  @override
  String get guideSpeedSlow => 'Slow';

  @override
  String get guideSpeedNormal => 'Normal';

  @override
  String get guideSpeedFast => 'Fast';

  @override
  String get guideVoicePackMissingHint =>
      'Gujarati voice pack is not installed on this device. Visual guidance continues normally.';

  @override
  String guideStepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get guideActionBack => 'Back';

  @override
  String get guideActionNext => 'Next';

  @override
  String get guideActionFinish => 'Finish';

  @override
  String get guideActionSkip => 'Skip';

  @override
  String get guideMinimizeCoach => 'Try Now';

  @override
  String get guideExpandSpotlight => 'Spotlight';

  @override
  String get guideFirstVisitHint =>
      'First time on this screen? Tap to see what every button does.';

  @override
  String get guideFirstVisitAction => 'Show Guide';

  @override
  String get guideNewScreenHintsLabel => 'First-visit tips on new screens';

  @override
  String get guideTrainingTabLabel => 'Interactive Training';

  @override
  String get guideTopicsTabLabel => 'Complete Guide (19)';

  @override
  String guideProgressSummary(int completed, int total) {
    return '$completed of $total chapters completed';
  }

  @override
  String get guideShowMeLive => 'Show Me Live';

  @override
  String get guideShowMeOnScreen => 'Show Me on Screen';

  @override
  String get guideChapterCompleted => 'Done';

  @override
  String get guideNextTopicHeading => 'What To Do Next';

  @override
  String get guideResetProgressAction => 'Reset Training Progress';

  @override
  String get guideResetProgressDone =>
      'Training progress reset. You can start fresh anytime.';

  @override
  String lotDesignPriceHelper(String price) {
    return 'Design price: $price';
  }

  @override
  String lotStageDefaultRateHelper(String price) {
    return 'Stage default rate: $price';
  }

  @override
  String accountingPayFullAction(String amount) {
    return 'Pay full $amount';
  }

  @override
  String get accountingUndoFailed =>
      'Could not undo the payment. Open the worker ledger to reverse it.';

  @override
  String get lotNeedVariantStageWorker =>
      'Add at least one colour variant, active work stage, and active worker first.';

  @override
  String get lotDesignColourVariantLabel => 'Design / Colour Variant';

  @override
  String get lotQtyPcsLabel => 'Qty (pcs)';

  @override
  String get lotLockedRateLabel => 'Locked Rate (₹/pc)';

  @override
  String get lotEnterPositiveQty => 'Enter a positive quantity.';

  @override
  String get lotEnterValidRate => 'Enter a valid rate.';

  @override
  String lotDesignAlreadyAdded(Object a) {
    return 'Design \"$a\" is already added to this lot.';
  }

  @override
  String get lotEnterDesignName => 'Enter a design name.';

  @override
  String get lotDesignNameTooLong => 'Design name is too long.';

  @override
  String get lotEnterValidDefaultPrice =>
      'Enter a valid non-negative default price.';

  @override
  String lotSelectColoursForDesign(Object a) {
    return 'Select Colours — $a';
  }

  @override
  String get lotSelectColoursColourOnly => 'Select Colours (Colour-Only Lot)';

  @override
  String lotEnterPositiveQtyFor(Object a) {
    return 'Enter a positive quantity for $a.';
  }

  @override
  String lotEnterPositiveQtyForVariant(Object a, Object b) {
    return 'Enter a positive quantity for $a — $b.';
  }

  @override
  String lotEnterValidPriceForVariant(Object a, Object b) {
    return 'Enter a valid non-negative unit price for $a — $b.';
  }

  @override
  String lotEnterValidPriceFor(Object a) {
    return 'Enter a valid non-negative unit price for $a.';
  }

  @override
  String lotQtyExceedsMaxFor(Object a) {
    return 'Quantity for $a exceeds the maximum limit.';
  }

  @override
  String lotCreatedSuccess(Object a) {
    return 'Lot $a created successfully.';
  }

  @override
  String get lotSummaryLive => 'Lot Summary (Live)';

  @override
  String get lotColoursLabel => 'Colours';

  @override
  String get lotTotalQtyLabel => 'Total Qty';

  @override
  String lotPiecesValue(Object a) {
    return '$a pcs';
  }

  @override
  String get lotSkuValueLabel => 'SKU Value';

  @override
  String get lotSectionInfo => '1. Lot Information';

  @override
  String get lotSectionDesigns => '2. Designs, Colours & SKU Pricing';

  @override
  String get lotSectionDesignsHelp =>
      'Unit prices here are SKU reference prices (separate from worker labour rates). You can add designs, colours, quantities, and prices in one workflow.';

  @override
  String get lotModeWithDesigns => 'With Design(s)';

  @override
  String get lotModeColourOnly => 'Colour-Only (No Design)';

  @override
  String get lotSelectExistingDesign => 'Select Existing Design';

  @override
  String get lotAddNewDesign => 'Add New Design';

  @override
  String get lotNewDesignInline => 'New Design (Inline)';

  @override
  String get lotDefaultUnitPriceLabel =>
      'Default Unit Price (₹ / pc, optional)';

  @override
  String get lotAddDesignToLot => 'Add Design to Lot';

  @override
  String get lotNoDesignsYet =>
      'No designs added yet. Select an existing design or tap \"+ Add New Design\" above (or save an empty lot and add designs later).';

  @override
  String lotColourVariantsCount(Object a) {
    return 'Colour Variants ($a)';
  }

  @override
  String get lotAddColours => 'Add Colours';

  @override
  String get lotAddColoursHelp =>
      'Tap \"Add Colours\" to pick colours from the palette or create custom colours with quantity & price.';

  @override
  String lotDefaultPriceValue(Object a) {
    return 'Default: $a';
  }

  @override
  String get lotRemoveDesign => 'Remove design';

  @override
  String get lotRemoveColour => 'Remove colour';

  @override
  String get lotUnitPriceLabel => 'Unit Price (₹)';

  @override
  String lotColourDetailsFor(Object a) {
    return '$a Details';
  }

  @override
  String get lotColourDetails => 'Colour Details';

  @override
  String get lotColourDetailsLoadError => 'Unable to load Colour Details';

  @override
  String get lotColourNotFound => 'Colour Variant Not Found';

  @override
  String get lotColourNotFoundHelp =>
      'This colour variant may have been removed from the lot.';

  @override
  String lotHashDesign(Object a, Object b) {
    return 'Lot #$a  •  Design: $b';
  }

  @override
  String lotQtyPcsValue(Object a) {
    return 'Lot Qty: $a pcs';
  }

  @override
  String lotTotalAssignedPcs(Object a) {
    return 'Total Assigned: $a pcs';
  }

  @override
  String lotUnitValue(Object a) {
    return 'Unit Value: $a';
  }

  @override
  String lotDamagedPcs(Object a) {
    return 'Damaged: $a pcs';
  }

  @override
  String lotManageStagesFor(Object a) {
    return 'Manage Work Stages for $a';
  }

  @override
  String get lotAvailableFactory => 'Available (Factory)';

  @override
  String get lotPendingWorkers => 'Pending (Workers)';

  @override
  String get lotCompletedHandedOver => 'Completed / Handed Over';

  @override
  String get lotStageBreakdown => 'Stage-wise Breakdown';

  @override
  String lotStageSummaryLine(Object a, Object b, Object c) {
    return 'Assigned: $a pcs • Completed: $b pcs • Pending: $c pcs';
  }

  @override
  String get lotWorkerDistribution => 'Worker-wise Distribution & Pricing';

  @override
  String lotNoWorkersAssignedFor(Object a) {
    return 'No workers have been assigned to $a yet.';
  }

  @override
  String lotAssignedPendingLine(Object a, Object b) {
    return 'Assigned: $a pcs • Pending: $b pcs';
  }

  @override
  String lotRatePayableLine(Object a, Object b, Object c) {
    return 'Rate: $a / $b • Payable: $c';
  }

  @override
  String get lotColourCostSummary => 'Colour Cost Summary';

  @override
  String get lotBaseStageCost => 'Base Work Stage Cost';

  @override
  String get lotAdditionalCharges => 'Additional Charges';

  @override
  String get lotDeductions => 'Deductions';

  @override
  String get lotPaidToWorkers => 'Paid to Workers';

  @override
  String lotMovementHistoryCount(Object a) {
    return 'Movement History ($a)';
  }

  @override
  String lotMovementHistoryEmpty(Object a) {
    return 'Dispatches, direct transfers, and returns for $a will appear here.';
  }

  @override
  String lotReceivedOfLine(Object a, Object b, Object c) {
    return 'Received: $a/$b • $c';
  }

  @override
  String get lotStatusNotStarted => 'Not Started';

  @override
  String get lotStatusInProgress => 'In Progress';

  @override
  String lotStatusPendingCount(Object a) {
    return 'Pending ($a)';
  }

  @override
  String lotInitialColoursCount(Object a) {
    return 'Initial Colours ($a)';
  }

  @override
  String get lotSelectInitialColours => 'Select Initial Colours';

  @override
  String get lotSelectColoursNoDesign => 'Select Colours (No Design)';

  @override
  String get lotRoutingHandovers => 'Work Stage Routing & Handovers';

  @override
  String get lotAddColourNoDesign => 'Add Colour (No Design)';

  @override
  String lotDesignValue(Object a) {
    return 'Design: $a';
  }

  @override
  String get lotTotalLabel => 'Total';

  @override
  String get lotDoneLabel => 'Done';

  @override
  String get lotAddCustomColour => 'Add Custom Colour';

  @override
  String get lotEditColour => 'Edit Colour';

  @override
  String get lotHexCodeLabel => 'HEX Code (e.g. #DC2626)';

  @override
  String get lotSaveColour => 'Save Colour';

  @override
  String get lotSearchColourHint => 'Search colour name or HEX';

  @override
  String get lotCustomColour => 'Custom';

  @override
  String get lotRecentlyUsed => 'Recently Used';

  @override
  String get lotColourPaletteHelp =>
      'Colour Palette (Tap to select, long-press to edit)';

  @override
  String lotSelectedColoursCount(Object a) {
    return 'Selected Colours ($a)';
  }

  @override
  String get lotSelectColoursAbove => 'Select Colours Above';

  @override
  String lotAddColoursSummary(Object a, Object b) {
    return 'Add $a Colour(s) • $b pcs';
  }

  @override
  String get lotInitialQtyLabel => 'Initial Qty';

  @override
  String get lotDesignsColoursBreakdown => 'Designs & Colours Breakdown';

  @override
  String lotInHouseValue(Object a) {
    return 'In-House: $a';
  }

  @override
  String lotWithWorkersValue(Object a) {
    return 'With Workers: $a';
  }

  @override
  String lotPendingQcValue(Object a) {
    return 'Pending QC: $a';
  }

  @override
  String lotDamagedValue(Object a) {
    return 'Damaged: $a';
  }

  @override
  String lotStageAssignmentsCount(Object a) {
    return 'Work Stage Assignments & Worker Ledger ($a)';
  }

  @override
  String get lotNoStageAssignments =>
      'No work stage assignments recorded for this lot yet.';

  @override
  String lotRejectionRecordsCount(Object a) {
    return 'Rejection & Repair Records ($a)';
  }

  @override
  String lotRejectedLine(Object a, Object b, Object c) {
    return 'Rejected: $a • Re-Approved: $b • Open: $c';
  }

  @override
  String lotReasonValue(Object a) {
    return 'Reason: $a';
  }

  @override
  String lotAssignedValue(Object a) {
    return 'Assigned: $a';
  }

  @override
  String lotReturnedValue(Object a) {
    return 'Returned: $a';
  }

  @override
  String lotAcceptedValue(Object a) {
    return 'Accepted: $a';
  }

  @override
  String lotOutstandingValue(Object a) {
    return 'Outstanding: $a';
  }

  @override
  String lotRejectedValue(Object a) {
    return 'Rejected: $a';
  }

  @override
  String lotRateEarnedLine(Object a, Object b) {
    return 'Rate: $a/pc • Earned: $b';
  }

  @override
  String get lotCostLabel => 'Cost';

  @override
  String lotLotsValue(Object a) {
    return 'Lots: $a';
  }

  @override
  String lotWorkersValue(Object a) {
    return 'Workers: $a';
  }

  @override
  String lotCostPaidOutstandingLine(Object a, Object b, Object c) {
    return 'Cost: $a • Paid (est): $b • Outstanding (est): $c';
  }

  @override
  String get stockStageDefaultBadge => 'Stage Default';

  @override
  String stockInheritedFrom(Object a, Object b) {
    return 'Inherited from $a ($b)';
  }

  @override
  String get selectSearchHint => 'Search…';

  @override
  String get selectNoResults => 'No matching items';

  @override
  String get selectLoadError => 'Could not load items. Try again.';

  @override
  String get selectSelectAll => 'Select all';

  @override
  String get selectClearAll => 'Clear';

  @override
  String selectSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String selectMaxReached(int max) {
    return 'You can select up to $max';
  }
}
