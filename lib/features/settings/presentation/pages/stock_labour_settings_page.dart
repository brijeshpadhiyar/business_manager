import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/business_profile/domain/repositories/business_profile_repository.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Stock & Labour Preferences backed directly by the authoritative
/// `BusinessProfileRepository` and `ProcessRepository` (zero duplicate storage).
final class StockLabourSettingsPage extends StatefulWidget {
  const StockLabourSettingsPage({super.key});

  @override
  State<StockLabourSettingsPage> createState() =>
      _StockLabourSettingsPageState();
}

final class _StockLabourSettingsPageState
    extends State<StockLabourSettingsPage> {
  final _profileRepo = getIt<BusinessProfileRepository>();
  final _processRepo = getIt<ProcessRepository>();

  BusinessProfileEntity? _profile;
  List<ProcessEntity> _processes = const [];
  BillingMode _selectedBillingMode = BillingMode.receivedQty;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _profileRepo.getProfile(),
        _processRepo.getProcesses(),
      ]);
      if (!mounted) return;
      final profile = results[0] as BusinessProfileEntity;
      final processes = results[1] as List<ProcessEntity>;
      setState(() {
        _profile = profile;
        _selectedBillingMode = profile.defaultBillingMode;
        _processes = processes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _saveGlobalBillingMode(BillingMode mode) async {
    final profile = _profile;
    if (profile == null || _saving) return;
    setState(() {
      _selectedBillingMode = mode;
      _saving = true;
    });
    try {
      final updated = await _profileRepo.updateProfile(
        nameEn: profile.nameEn,
        nameGu: profile.nameGu,
        ownerName: profile.ownerName,
        phone: profile.phone,
        address: profile.address,
        defaultBillingMode: mode,
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _saving = false;
      });
      AppFeedback.showSuccess(context, context.l10n.businessProfileSaved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return AppScaffold(
        title: l10n.settingsStockLabourTitle,
        body: const AppSkeletonList(itemCount: 3),
      );
    }
    if (_error != null) {
      return AppScaffold(
        title: l10n.settingsStockLabourTitle,
        body: AppErrorView(
          title: l10n.errorUnexpected,
          message: _error,
          retryLabel: l10n.actionRetry,
          onRetry: _load,
        ),
      );
    }

    return AppScaffold(
      title: l10n.settingsStockLabourTitle,
      body: ListView(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeading(
                  l10n.settingsGlobalBillingSectionTitle,
                  level: AppHeadingLevel.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppRadio<BillingMode>(
                  groupValue: _selectedBillingMode,
                  enabled: !_saving,
                  onChanged: (mode) {
                    if (mode != null && mode != _selectedBillingMode) {
                      _saveGlobalBillingMode(mode);
                    }
                  },
                  options: [
                    AppRadioOption(
                      value: BillingMode.receivedQty,
                      label: l10n.billingModeReceivedQty,
                      subtitle: l10n.settingsGlobalBillingExplanationReceived,
                    ),
                    AppRadioOption(
                      value: BillingMode.givenQty,
                      label: l10n.billingModeGivenQty,
                      subtitle: l10n.settingsGlobalBillingExplanationGiven,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppHeading(
            l10n.settingsProcessOverridesTitle,
            level: AppHeadingLevel.h3,
            subtitle: l10n.settingsProcessOverridesSubtitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_processes.isEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    l10n.settingsNoProcessesYet,
                    variant: AppTextVariant.bodySmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: l10n.processCreateAction,
                    icon: Icons.add,
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      await context.push(RoutePaths.processCreate);
                      if (mounted) await _load();
                    },
                  ),
                ],
              ),
            )
          else
            for (final proc in _processes)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  onTap: () async {
                    await context.push(RoutePaths.processEdit(proc.id));
                    if (mounted) await _load();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              proc.name,
                              variant: AppTextVariant.bodyLarge,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppStatusBadge(
                            label: proc.isActive
                                ? l10n.statusActive
                                : l10n.statusInactive,
                            tone: proc.isActive
                                ? AppStatusTone.good
                                : AppStatusTone.neutral,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          AppStatusBadge(
                            label: proc.billingModeOverride == null
                                ? l10n.settingsProcessInheritsGlobal
                                : '${l10n.settingsProcessOverridesGlobal}: ${proc.billingModeOverride == ProcessBillingModeOverride.givenQty ? l10n.billingModeGivenQty : l10n.billingModeReceivedQty}',
                            tone: proc.billingModeOverride == null
                                ? AppStatusTone.neutral
                                : AppStatusTone.pending,
                          ),
                          AppStatusBadge(
                            label: proc.includeDamagedInLabour
                                ? l10n.settingsDamagedIncludedShort
                                : l10n.settingsDamagedExcludedShort,
                            tone: proc.includeDamagedInLabour
                                ? AppStatusTone.info
                                : AppStatusTone.neutral,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
