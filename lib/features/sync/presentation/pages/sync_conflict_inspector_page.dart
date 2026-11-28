import 'package:business_manager/core/validation/validation_localizer.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:business_manager/features/auth/presentation/widgets/permission_gate.dart';
import 'package:business_manager/features/sync/data/services/sync_conflict_service.dart';
import 'package:business_manager/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Settings → Cloud Sync → Conflict Inspector.
///
/// Surfaces non-blocking LWW sync conflicts with field-by-field diffs
/// (`Your Superseded Edit` vs `Applied Cloud Version`) and allows Owners &
/// Managers to acknowledge or perform a one-tap audited restore.
final class SyncConflictInspectorPage extends StatefulWidget {
  const SyncConflictInspectorPage({super.key});

  @override
  State<SyncConflictInspectorPage> createState() =>
      _SyncConflictInspectorPageState();
}

final class _SyncConflictInspectorPageState
    extends State<SyncConflictInspectorPage> {
  final SyncConflictService _service = getIt<SyncConflictService>();

  bool _loading = true;
  bool _busy = false;
  List<SyncConflictRecord> _conflicts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _service.loadConflicts();
    if (!mounted) return;
    setState(() {
      _conflicts = items;
      _loading = false;
    });
  }

  String? get _actorId => context.read<AuthCubit?>()?.state.user?.id;

  Future<void> _acknowledge(SyncConflictRecord record) async {
    setState(() => _busy = true);
    try {
      await _service.acknowledgeConflict(record, actor: _actorId);
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          context.l10n.syncConflictAcknowledgedSuccess,
        );
        context.read<SyncCubit?>()?.refreshConflictsCount();
      }
      await _load();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          ValidationLocalizer.describeError(context.l10n, e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(SyncConflictRecord record) async {
    setState(() => _busy = true);
    try {
      await _service.restoreSupersededVersion(record, actor: _actorId);
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          context.l10n.syncConflictRestoredSuccess,
        );
        context.read<SyncCubit?>()?.syncNow();
      }
      await _load();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          ValidationLocalizer.describeError(context.l10n, e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: l10n.syncConflictsTitle,
      constrainMaxWidth: false,
      padding: EdgeInsets.zero,
      actions: [
        AppIconButton(
          icon: AppIcons.refresh,
          tooltip: l10n.actionRetry,
          onPressed: _loading ? null : _load,
        ),
      ],
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizing.narrowContentWidth,
          ),
          child: _loading
              ? const Padding(
                  padding: AppSpacing.screenAll,
                  child: AppSkeletonList(itemCount: 3),
                )
              : _conflicts.isEmpty
              ? AppEmptyState(
                  icon: AppIcons.cloudDone,
                  title: l10n.syncConflictsEmptyTitle,
                  subtitle: l10n.syncConflictsEmptySubtitle,
                )
              : ListView.separated(
                  padding: AppSpacing.screenAll,
                  itemCount: _conflicts.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, idx) {
                    final record = _conflicts[idx];
                    final statusLabel = switch (record.status) {
                      SyncConflictStatus.unresolved =>
                        l10n.syncConflictStatusUnresolved,
                      SyncConflictStatus.acknowledged =>
                        l10n.syncConflictStatusAcknowledged,
                      SyncConflictStatus.restored =>
                        l10n.syncConflictStatusRestored,
                    };
                    final statusTone = switch (record.status) {
                      SyncConflictStatus.unresolved => AppStatusTone.pending,
                      SyncConflictStatus.acknowledged => AppStatusTone.neutral,
                      SyncConflictStatus.restored => AppStatusTone.good,
                    };

                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppActionRow(
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  '${record.tableName} • ${record.entityId}',
                                  fontWeight: FontWeight.w700,
                                ),
                                AppText(
                                  IstDateTimeHelper.formatIstDateTime(
                                    record.occurredAtUtcMillis,
                                    locale: localeCode,
                                  ),
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            actions: [
                              AppStatusBadge(
                                label: statusLabel,
                                tone: statusTone,
                              ),
                            ],
                          ),
                          const AppDivider(height: AppSpacing.lg),
                          for (final diff in record.fieldDiffs) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xsm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    diff.fieldName,
                                    variant: AppTextVariant.bodySmall,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  AppText(
                                    '${l10n.syncConflictLocalLabel}: ${diff.localValue}',
                                    variant: AppTextVariant.bodySmall,
                                    color: colorScheme.primary,
                                  ),
                                  AppText(
                                    '${l10n.syncConflictCloudLabel}: ${diff.cloudValue}',
                                    variant: AppTextVariant.bodySmall,
                                    color: colorScheme.secondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (record.isUnresolved) ...[
                            const SizedBox(height: AppSpacing.sm),
                            PermissionGate(
                              permission: AppPermission.restoreSyncConflicts,
                              child: Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  AppButton(
                                    label: l10n.syncConflictKeepCloudAction,
                                    icon: AppIcons.confirm,
                                    variant: AppButtonVariant.outlined,
                                    onPressed: _busy
                                        ? null
                                        : () => _acknowledge(record),
                                  ),
                                  AppButton(
                                    label: l10n.syncConflictRestoreLocalAction,
                                    icon: AppIcons.restore,
                                    isLoading: _busy,
                                    onPressed: _busy
                                        ? null
                                        : () => _restore(record),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
