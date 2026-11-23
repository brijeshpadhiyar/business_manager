import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/di/app_session_controller.dart';
import 'package:business_manager/features/backup/domain/entities/backup_entities.dart';
import 'package:business_manager/features/backup/domain/services/backup_restore_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum BackupRestoreStatus {
  idle,
  working,
  exportSuccess,
  validationReady,
  restoreSuccess,
  error,
}

final class BackupRestoreState {
  const BackupRestoreState({
    this.status = BackupRestoreStatus.idle,
    this.progress,
    this.lastExport,
    this.pendingValidation,
    this.pendingZipPath,
    this.lastRestore,
    this.errorMessage,
  });

  final BackupRestoreStatus status;
  final BackupProgress? progress;
  final BackupExportResult? lastExport;
  final BackupValidationResult? pendingValidation;
  final String? pendingZipPath;
  final BackupRestoreResult? lastRestore;
  final String? errorMessage;

  BackupRestoreState copyWith({
    BackupRestoreStatus? status,
    BackupProgress? progress,
    BackupExportResult? lastExport,
    BackupValidationResult? pendingValidation,
    String? pendingZipPath,
    BackupRestoreResult? lastRestore,
    String? errorMessage,
    bool clearPendingValidation = false,
  }) {
    return BackupRestoreState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      lastExport: lastExport ?? this.lastExport,
      pendingValidation: clearPendingValidation
          ? null
          : (pendingValidation ?? this.pendingValidation),
      pendingZipPath: clearPendingValidation
          ? null
          : (pendingZipPath ?? this.pendingZipPath),
      lastRestore: lastRestore ?? this.lastRestore,
      errorMessage: errorMessage,
    );
  }
}

@injectable
final class BackupRestoreCubit extends Cubit<BackupRestoreState> {
  BackupRestoreCubit(this._service, this._config)
    : super(const BackupRestoreState());

  final BackupRestoreService _service;
  final AppConfig _config;

  Future<BackupExportResult?> createFullBackup({String? destinationDir}) async {
    emit(
      state.copyWith(
        status: BackupRestoreStatus.working,
        progress: const BackupProgress(stageCode: 'preparing', fraction: 0.05),
      ),
    );
    try {
      final result = await _service.createFullZipBackup(
        destinationDirectoryPath: destinationDir,
        onProgress: (p) {
          if (!isClosed) emit(state.copyWith(progress: p));
        },
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: BackupRestoreStatus.exportSuccess,
            lastExport: result,
          ),
        );
      }
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: BackupRestoreStatus.error,
            errorMessage: e.toString(),
          ),
        );
      }
      return null;
    }
  }

  Future<BackupExportResult?> exportRawSqlite({String? destinationDir}) async {
    emit(
      state.copyWith(
        status: BackupRestoreStatus.working,
        progress: const BackupProgress(
          stageCode: 'checkpointing',
          fraction: 0.1,
        ),
      ),
    );
    try {
      final result = await _service.exportRawSqlite(
        destinationDirectoryPath: destinationDir,
        onProgress: (p) {
          if (!isClosed) emit(state.copyWith(progress: p));
        },
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: BackupRestoreStatus.exportSuccess,
            lastExport: result,
          ),
        );
      }
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: BackupRestoreStatus.error,
            errorMessage: e.toString(),
          ),
        );
      }
      return null;
    }
  }

  Future<BackupValidationResult?> inspectBackupZip(String zipFilePath) async {
    emit(
      state.copyWith(
        status: BackupRestoreStatus.working,
        progress: const BackupProgress(stageCode: 'validating', fraction: 0.1),
      ),
    );
    try {
      final validation = await _service.validateBackupZip(
        zipFilePath,
        onProgress: (p) {
          if (!isClosed) emit(state.copyWith(progress: p));
        },
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: BackupRestoreStatus.validationReady,
            pendingValidation: validation,
            pendingZipPath: zipFilePath,
          ),
        );
      }
      return validation;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: BackupRestoreStatus.error,
            errorMessage: e.toString(),
          ),
        );
      }
      return null;
    }
  }

  Future<BackupRestoreResult?> executeConfirmedRestore(
    String zipFilePath,
  ) async {
    emit(
      state.copyWith(
        status: BackupRestoreStatus.working,
        progress: const BackupProgress(stageCode: 'validating', fraction: 0.1),
      ),
    );
    try {
      final result = await _service.restoreFromZip(
        zipFilePath,
        onProgress: (p) {
          if (!isClosed) emit(state.copyWith(progress: p));
        },
      );
      // Reload entire DI graph cleanly against the restored SQLite database
      // while preserving the active unlocked security session.
      await AppSessionController.instance.reloadSession(
        _config,
        preserveUnlockedSecuritySession: true,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: BackupRestoreStatus.restoreSuccess,
            lastRestore: result,
            clearPendingValidation: true,
          ),
        );
      }
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: BackupRestoreStatus.error,
            errorMessage: e.toString(),
          ),
        );
      }
      return null;
    }
  }
}
