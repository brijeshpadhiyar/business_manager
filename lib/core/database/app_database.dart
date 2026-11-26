import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/connection/database_connection.dart';
import 'package:business_manager/core/database/daos/attachment_audit_dao.dart';
import 'package:business_manager/core/database/daos/business_profile_dao.dart';
import 'package:business_manager/core/database/daos/colour_master_dao.dart';
import 'package:business_manager/core/database/daos/job_process_dao.dart';
import 'package:business_manager/core/database/daos/labour_entry_dao.dart';
import 'package:business_manager/core/database/daos/lot_dao.dart';
import 'package:business_manager/core/database/daos/payment_dao.dart';
import 'package:business_manager/core/database/daos/process_member_dao.dart';
import 'package:business_manager/core/database/daos/production_tracking_dao.dart';
import 'package:business_manager/core/database/daos/stock_movement_dao.dart';
import 'package:business_manager/core/database/daos/sync_dao.dart';
import 'package:business_manager/core/database/daos/worker_adjustment_dao.dart';
import 'package:business_manager/core/database/database_pragma_status.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:business_manager/core/database/tables/attachment_audit_tables.dart';
import 'package:business_manager/core/database/tables/business_profile_table.dart';
import 'package:business_manager/core/database/tables/colour_master_table.dart';
import 'package:business_manager/core/database/tables/job_process_tables.dart';
import 'package:business_manager/core/database/tables/ledger_tables.dart';
import 'package:business_manager/core/database/tables/lot_tables.dart';
import 'package:business_manager/core/database/tables/process_member_tables.dart';
import 'package:business_manager/core/database/tables/production_tracking_tables.dart';
import 'package:business_manager/core/database/tables/sync_tables.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Root offline-first Drift SQLite database (Schema v10: 27 tables, 12 DAOs).
@DriftDatabase(
  tables: [
    BusinessProfiles,
    Lots,
    LotDesigns,
    DesignColours,
    Processes,
    Members,
    MemberProcesses,
    MemberProcessRates,
    StockMovements,
    LabourEntries,
    Payments,
    WorkerLedgerAdjustments,
    JobProcesses,
    ProcessHandovers,
    ProcessAdditionalCharges,
    ProcessRateHistories,
    ColourMasters,
    Attachments,
    AuditLogs,
    ProductionReturns,
    ProductionInspections,
    RejectionRecords,
    RejectionRepairs,
    SyncSessionStates,
    SyncOutboxes,
    SyncCursors,
    SyncMediaQueues,
  ],
  daos: [
    BusinessProfileDao,
    LotDao,
    ProcessMemberDao,
    StockMovementDao,
    LabourEntryDao,
    PaymentDao,
    WorkerAdjustmentDao,
    JobProcessDao,
    ColourMasterDao,
    AttachmentAuditDao,
    ProductionTrackingDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(AppConfig config) : super(openPlatformDatabase(config));

  /// Explicit executor constructor for isolated temporary/in-memory tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => DatabaseMigrationManager.currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => DatabaseMigrationManager.handleOnCreate(m, this),
    onUpgrade: (m, from, to) =>
        DatabaseMigrationManager.handleOnUpgrade(m, this, from, to),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('PRAGMA journal_mode = WAL;');
      await customStatement('PRAGMA synchronous = FULL;');
      await customStatement('PRAGMA busy_timeout = 5000;');
    },
  );

  /// Queries SQLite directly to verify effective PRAGMA values after open.
  Future<DatabasePragmaStatus> verifyPragmas() async {
    final fkRow = await customSelect('PRAGMA foreign_keys;').getSingle();
    final walRow = await customSelect('PRAGMA journal_mode;').getSingle();
    final syncRow = await customSelect('PRAGMA synchronous;').getSingle();
    final timeoutRow = await customSelect('PRAGMA busy_timeout;').getSingle();

    return DatabasePragmaStatus(
      foreignKeysEnabled: fkRow.data.values.first == 1,
      journalMode: walRow.data.values.first.toString(),
      synchronousLevel: (syncRow.data.values.first as num).toInt(),
      busyTimeoutMs: (timeoutRow.data.values.first as num).toInt(),
    );
  }
}
