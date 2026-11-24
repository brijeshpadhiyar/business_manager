import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/platform/media_storage_factory.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/backup/data/services/backup_restore_service_factory.dart';
import 'package:business_manager/features/backup/domain/services/backup_restore_service.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  @LazySingleton(dispose: disposeAppDatabase)
  AppDatabase appDatabase(AppConfig config) => AppDatabase(config);

  @lazySingleton
  MediaStorageService mediaStorageService(
    AppConfig config,
    IdGenerator idGenerator,
  ) => createPlatformMediaStorageService(config, idGenerator);

  @lazySingleton
  BackupRestoreService backupRestoreService(
    AppDatabase db,
    AppConfig config,
    IdGenerator idGenerator,
  ) => createPlatformBackupRestoreService(db, config, idGenerator);
}

Future<void> disposeAppDatabase(AppDatabase db) => db.close();
