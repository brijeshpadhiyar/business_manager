import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/backup/data/services/web_backup_restore_service.dart';
import 'package:business_manager/features/backup/domain/services/backup_restore_service.dart';

BackupRestoreService createPlatformBackupRestoreService(
  AppDatabase db,
  AppConfig config,
  IdGenerator idGenerator,
) => WebBackupRestoreService(db, config, idGenerator);
