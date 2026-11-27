import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:business_manager/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Compact live Sync Status indicator displayed in the shell header / sidebar.
/// When [compact] is `true` (360dp mobile AppBar), renders an icon-only button
/// with tooltip so large text scaling never overflows the toolbar.
final class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final syncCubit = context.read<SyncCubit?>();
    if (syncCubit == null) return const SizedBox.shrink();

    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final (label, icon, tone) = switch (state.phase) {
          SyncPhase.localOnly => (
            l10n.syncStatusLocalOnly,
            AppIcons.cloudOff,
            AppStatusTone.neutral,
          ),
          SyncPhase.offline => (
            state.totalPendingCount > 0
                ? '${l10n.syncStatusOffline} (${state.totalPendingCount})'
                : l10n.syncStatusOffline,
            AppIcons.cloudOff,
            AppStatusTone.pending,
          ),
          SyncPhase.syncing => (
            l10n.syncStatusSyncing,
            AppIcons.cloudSync,
            AppStatusTone.info,
          ),
          SyncPhase.synced => (
            l10n.syncStatusSynced,
            AppIcons.cloudDone,
            AppStatusTone.good,
          ),
          SyncPhase.needsAttention => (
            l10n.syncStatusNeedsAttention,
            AppIcons.syncProblem,
            AppStatusTone.damaged,
          ),
          SyncPhase.awaitingMergeChoice => (
            l10n.syncMergeTitle,
            AppIcons.merge,
            AppStatusTone.pending,
          ),
        };

        void onTap() {
          if (state.phase == SyncPhase.localOnly) {
            context.push(RoutePaths.authLogin);
          } else {
            context.push(RoutePaths.settingsSync);
          }
        }

        if (compact) {
          return AppIconButton(icon: icon, tooltip: label, onPressed: onTap);
        }

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AppStatusBadge(label: label, tone: tone, icon: icon),
        );
      },
    );
  }
}
