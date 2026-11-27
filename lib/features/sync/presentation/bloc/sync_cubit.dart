import 'dart:async';

import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:business_manager/features/sync/domain/repositories/cloud_sync_gateway.dart';
import 'package:business_manager/features/sync/domain/repositories/sync_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Root Sync Coordinator Cubit:
/// - Tracks online/offline connectivity (`connectivity_plus`)
/// - Watches local `sync_outbox` and `sync_media_queue` counts reactively
/// - Subscribes to Supabase Realtime wake-ups when signed in & online
/// - Auto-syncs on login, network reconnect, app resume, and local writes (2s debounce)
@lazySingleton
final class SyncCubit extends Cubit<SyncState> {
  SyncCubit(
    this._syncRepository,
    this._gateway,
    this._authCubit,
    this._logger,
  ) : super(const SyncState());

  final SyncRepository _syncRepository;
  final CloudSyncGateway _gateway;
  final AuthCubit _authCubit;
  final AppLogger _logger;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<int>? _outboxSub;
  StreamSubscription<int>? _mediaSub;
  Timer? _debounceTimer;
  String? _lastHandledUserId;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final session = await _syncRepository.getSessionState();
    emit(state.copyWith(lastSyncedAtUtcMillis: session.lastFullSyncAt));

    _outboxSub = _syncRepository.watchPendingOutboxCount().listen((count) {
      final wasHigher = count > state.pendingOutboxCount;
      emit(state.copyWith(pendingOutboxCount: count));
      if (wasHigher && _canAutoSync) {
        _scheduleDebouncedSync();
      }
    });

    _mediaSub = _syncRepository.watchPendingMediaCount().listen((count) {
      emit(state.copyWith(pendingMediaCount: count));
    });

    if (!isFlutterTestEnv) {
      final initialConn = await Connectivity().checkConnectivity();
      _handleConnectivityResults(initialConn, triggerSync: false);
      _connectivitySub = Connectivity().onConnectivityChanged.listen(
        (results) => _handleConnectivityResults(results, triggerSync: true),
      );
    }

    _authSub = _authCubit.stream.listen(_onAuthStateChanged);
    await _onAuthStateChanged(_authCubit.state);
  }

  bool get _canAutoSync =>
      _authCubit.state.isAuthenticated &&
      _syncRepository.isCloudConfigured &&
      state.isOnline &&
      state.phase != SyncPhase.awaitingMergeChoice;

  void _handleConnectivityResults(
    List<ConnectivityResult> results, {
    required bool triggerSync,
  }) {
    final online = results.any((r) => r != ConnectivityResult.none);
    final reconnected = !state.isOnline && online;
    emit(
      state.copyWith(
        isOnline: online,
        phase: !_authCubit.state.isAuthenticated
            ? SyncPhase.localOnly
            : (!online ? SyncPhase.offline : state.phase),
      ),
    );
    if (triggerSync && reconnected && _canAutoSync) {
      unawaited(syncNow());
    }
  }

  Future<void> _onAuthStateChanged(AuthState authState) async {
    if (!authState.isAuthenticated || authState.user == null) {
      _lastHandledUserId = null;
      await _gateway.unsubscribeFromSyncNotifications();
      emit(
        state.copyWith(
          phase: SyncPhase.localOnly,
          clearPendingMerge: true,
          clearError: true,
        ),
      );
      return;
    }

    final user = authState.user!;
    final isNewLogin = _lastHandledUserId != user.id;
    _lastHandledUserId = user.id;

    if (!state.isOnline) {
      emit(state.copyWith(phase: SyncPhase.offline));
      return;
    }

    if (!_syncRepository.isCloudConfigured) {
      emit(state.copyWith(phase: SyncPhase.localOnly));
      return;
    }

    final session = await _syncRepository.getSessionState();
    await _gateway.subscribeToSyncNotifications(
      businessId: user.businessId,
      currentDeviceId: session.deviceId,
      onRemoteChange: () {
        if (_canAutoSync) {
          _scheduleDebouncedSync(delay: const Duration(milliseconds: 500));
        }
      },
    );

    if (isNewLogin && session.lastFullSyncAt == null) {
      await _checkFirstLoginMerge(user);
    } else {
      await syncNow();
    }
  }

  Future<void> _checkFirstLoginMerge(AuthUser user) async {
    emit(state.copyWith(phase: SyncPhase.syncing, clearError: true));
    try {
      final summary = await _syncRepository.inspectFirstLoginMerge(user);
      if (summary.needsUserPrompt) {
        emit(
          state.copyWith(
            phase: SyncPhase.awaitingMergeChoice,
            pendingMergeSummary: summary,
          ),
        );
        return;
      }
      // Automatic seamless path: only local or only cloud has data.
      await _syncRepository.executeFirstLoginMerge(
        user,
        FirstLoginMergeChoice.mergeBoth,
      );
      await _refreshAfterSync();
    } catch (e) {
      _logger.warning('First-login merge inspection failed: $e');
      emit(
        state.copyWith(
          phase: SyncPhase.needsAttention,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> resolveFirstLoginMerge(FirstLoginMergeChoice choice) async {
    final user = _authCubit.state.user;
    if (user == null) return;
    emit(
      state.copyWith(
        phase: SyncPhase.syncing,
        clearPendingMerge: true,
        clearError: true,
      ),
    );
    try {
      final summary = await _syncRepository.executeFirstLoginMerge(
        user,
        choice,
      );
      await _refreshAfterSync(summary: summary);
    } catch (e) {
      emit(
        state.copyWith(
          phase: SyncPhase.needsAttention,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void onAppResumed() {
    if (_canAutoSync) {
      unawaited(syncNow());
    }
  }

  void _scheduleDebouncedSync({Duration delay = const Duration(seconds: 2)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      if (_canAutoSync && !_syncRepository.isSyncRunning) {
        unawaited(syncNow());
      }
    });
  }

  Future<void> syncNow() async {
    final user = _authCubit.state.user;
    if (user == null || !_syncRepository.isCloudConfigured) {
      emit(state.copyWith(phase: SyncPhase.localOnly));
      return;
    }
    if (!state.isOnline) {
      emit(state.copyWith(phase: SyncPhase.offline));
      return;
    }
    if (_syncRepository.isSyncRunning) return;

    emit(state.copyWith(phase: SyncPhase.syncing, clearError: true));
    try {
      final summary = await _syncRepository.runSyncCycle(user);
      await _refreshAfterSync(summary: summary);
    } catch (e) {
      _logger.warning('Sync cycle failed: $e');
      await _refreshFailedItems();
      emit(
        state.copyWith(
          phase: SyncPhase.needsAttention,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> retryFailed() async {
    await _syncRepository.resetFailedItems();
    await syncNow();
  }

  Future<void> _refreshAfterSync({SyncRunSummary? summary}) async {
    await _refreshFailedItems();
    final session = await _syncRepository.getSessionState();
    final hasFailures =
        state.failedItems.isNotEmpty || (summary?.failedCount ?? 0) > 0;
    emit(
      state.copyWith(
        phase: hasFailures ? SyncPhase.needsAttention : SyncPhase.synced,
        lastSyncedAtUtcMillis:
            summary?.completedAtUtcMillis ?? session.lastFullSyncAt,
        lastSummary: summary ?? state.lastSummary,
        clearError: !hasFailures,
      ),
    );
  }

  Future<void> _refreshFailedItems() async {
    final mapped = await _syncRepository.getFailedOutboxItems();
    emit(state.copyWith(failedItems: mapped));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _connectivitySub?.cancel();
    _authSub?.cancel();
    _outboxSub?.cancel();
    _mediaSub?.cancel();
    return super.close();
  }
}
