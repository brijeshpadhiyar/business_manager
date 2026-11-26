import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:business_manager/features/auth/presentation/widgets/permission_gate.dart';
import 'package:business_manager/features/team/domain/entities/team_entities.dart';
import 'package:business_manager/features/team/domain/repositories/team_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Settings → Team & Role Access screen for managing workshop members,
/// WhatsApp-shareable invite codes, and joining another workshop via code.
final class TeamManagementPage extends StatefulWidget {
  const TeamManagementPage({super.key});

  @override
  State<TeamManagementPage> createState() => _TeamManagementPageState();
}

final class _TeamManagementPageState extends State<TeamManagementPage> {
  final TeamRepository _repo = getIt<TeamRepository>();

  bool _loading = true;
  bool _busy = false;
  List<TeamMemberInfo> _members = const [];
  List<BusinessInviteInfo> _invites = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  AuthUser? get _currentUser => context.read<AuthCubit?>()?.state.user;

  Future<void> _load() async {
    final user = _currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await _repo.loadMembers(user.businessId);
      final isOwner = RbacPolicy.can(
        user.role,
        AppPermission.manageTeamAndInvites,
      );
      final invites = isOwner
          ? await _repo.loadInvites(user.businessId)
          : const <BusinessInviteInfo>[];
      if (!mounted) return;
      setState(() {
        _members = members;
        _invites = invites;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _roleLabel(BuildContext context, BusinessRole role) {
    final l10n = context.l10n;
    return switch (role) {
      BusinessRole.owner => l10n.teamRoleOwner,
      BusinessRole.manager => l10n.teamRoleManager,
      BusinessRole.qcInspector => l10n.teamRoleQcInspector,
      BusinessRole.accountant => l10n.teamRoleAccountant,
    };
  }

  Future<void> _shareInviteCode(
    BuildContext context,
    BusinessInviteInfo invite,
  ) async {
    final roleName = _roleLabel(context, invite.role);
    final isGu = Localizations.localeOf(context).languageCode == 'gu';
    final message = isGu
        ? 'StitchFlow વર્કશોપમાં જોડાવા માટે આમંત્રણ કોડ: *${invite.code}*\nરોલ: $roleName\nએપમાં સાઇન ઇન કરીને Settings → Team & Role Access → Join via Code માં આ કોડ દાખલ કરો.'
        : 'StitchFlow Workshop Invite Code: *${invite.code}*\nRole: $roleName\nSign in to StitchFlow and enter this code in Settings → Team & Role Access → Join via Code.';
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);
    await SharePlus.instance.share(
      ShareParams(text: message, sharePositionOrigin: origin),
    );
  }

  Future<void> _showCreateInviteSheet(BuildContext context) async {
    final user = _currentUser;
    if (user == null) return;
    final l10n = context.l10n;
    var selectedRole = BusinessRole.manager;
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    var saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.teamCreateInviteAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDropdown<BusinessRole>(
                  label: l10n.settingsTeamTitle,
                  value: selectedRole,
                  items: const [
                    BusinessRole.manager,
                    BusinessRole.qcInspector,
                    BusinessRole.accountant,
                  ],
                  itemLabelBuilder: (r) => _roleLabel(ctx, r),
                  onChanged: (r) {
                    if (r != null) setSheetState(() => selectedRole = r);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: phoneCtrl,
                  label: l10n.teamInvitePhoneOptionalLabel,
                  prefixIcon: AppIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: emailCtrl,
                  label: l10n.teamInviteEmailOptionalLabel,
                  prefixIcon: AppIcons.account,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.teamCreateInviteAction,
                  icon: AppIcons.invite,
                  isExpanded: true,
                  isLoading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          setSheetState(() => saving = true);
                          try {
                            final created = await _repo.createInvite(
                              businessId: user.businessId,
                              role: selectedRole,
                              targetPhone: phoneCtrl.text,
                              targetEmail: emailCtrl.text,
                            );
                            if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                            if (!mounted) return;
                            AppFeedback.showSuccess(
                              this.context,
                              l10n.teamInviteCreatedSuccess,
                            );
                            await _load();
                            if (mounted) {
                              await _shareInviteCode(this.context, created);
                            }
                          } catch (e) {
                            if (sheetCtx.mounted) {
                              setSheetState(() => saving = false);
                              AppFeedback.showError(sheetCtx, e.toString());
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      phoneCtrl.dispose();
      emailCtrl.dispose();
    }
  }

  Future<void> _showJoinCodeSheet(BuildContext context) async {
    final l10n = context.l10n;
    final codeCtrl = TextEditingController();
    var saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.teamJoinWorkspaceAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: codeCtrl,
                label: l10n.teamInviteCodeLabel,
                hint: l10n.teamInviteCodeHint,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.teamJoinWorkspaceAction,
                icon: AppIcons.confirm,
                isExpanded: true,
                isLoading: saving,
                onPressed: saving
                    ? null
                    : () async {
                        final raw = codeCtrl.text.trim();
                        if (raw.isEmpty) return;
                        setSheetState(() => saving = true);
                        try {
                          await _repo.redeemInviteCode(raw);
                          if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                          if (mounted) {
                            AppFeedback.showSuccess(
                              this.context,
                              l10n.teamJoinSuccess,
                            );
                            await _load();
                          }
                        } catch (e) {
                          if (sheetCtx.mounted) {
                            setSheetState(() => saving = false);
                            AppFeedback.showError(sheetCtx, e.toString());
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      );
    } finally {
      codeCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final authState = context.watch<AuthCubit?>()?.state;
    final isAuthenticated = authState?.isAuthenticated ?? false;

    return AppScaffold(
      title: l10n.teamHeading,
      constrainMaxWidth: false,
      padding: EdgeInsets.zero,
      actions: [
        if (isAuthenticated)
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
          child: !isAuthenticated
              ? Padding(
                  padding: AppSpacing.screenAll,
                  child: AppCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppText(l10n.teamSignInRequiredSubtitle),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: l10n.authSignInHeading,
                          icon: AppIcons.signIn,
                          isExpanded: true,
                          onPressed: () => context.push(RoutePaths.authLogin),
                        ),
                      ],
                    ),
                  ),
                )
              : _loading
              ? const Padding(
                  padding: AppSpacing.screenAll,
                  child: AppSkeletonList(itemCount: 3),
                )
              : ListView(
                  padding: AppSpacing.screenAll,
                  children: [
                    AppHeading(
                      l10n.teamHeading,
                      level: AppHeadingLevel.h2,
                      subtitle: l10n.settingsTeamSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        PermissionGate(
                          permission: AppPermission.manageTeamAndInvites,
                          child: AppButton(
                            label: l10n.teamCreateInviteAction,
                            icon: AppIcons.invite,
                            onPressed: _busy
                                ? null
                                : () => _showCreateInviteSheet(context),
                          ),
                        ),
                        AppButton(
                          label: l10n.teamJoinWorkspaceAction,
                          icon: AppIcons.team,
                          variant: AppButtonVariant.outlined,
                          onPressed: _busy
                              ? null
                              : () => _showJoinCodeSheet(context),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppStatusBadge(
                        label: _error!,
                        tone: AppStatusTone.damaged,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    // Members Section
                    AppHeading(
                      '${l10n.teamMembersSection} (${_members.length})',
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: _members.isEmpty
                          ? AppText(l10n.teamRoleOwner)
                          : Column(
                              children: [
                                for (var i = 0; i < _members.length; i++) ...[
                                  AppActionRow(
                                    content: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          _members[i].bestLabel,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        if (_members[i].phone != null ||
                                            _members[i].email != null)
                                          AppText(
                                            _members[i].phone ??
                                                _members[i].email!,
                                            variant: AppTextVariant.bodySmall,
                                          ),
                                      ],
                                    ),
                                    actions: [
                                      AppStatusBadge(
                                        label: _roleLabel(
                                          context,
                                          _members[i].role,
                                        ),
                                        tone: _members[i].isActive
                                            ? AppStatusTone.info
                                            : AppStatusTone.damaged,
                                      ),
                                      if (_members[i].role !=
                                              BusinessRole.owner &&
                                          _members[i].isActive)
                                        PermissionGate(
                                          permission:
                                              AppPermission.manageTeamAndInvites,
                                          child: AppButton(
                                            label: l10n.teamRevokeAction,
                                            variant: AppButtonVariant.text,
                                            onPressed: () async {
                                              setState(() => _busy = true);
                                              try {
                                                await _repo.revokeMember(
                                                  businessId:
                                                      _members[i].businessId,
                                                  userId: _members[i].userId,
                                                );
                                                await _load();
                                              } finally {
                                                if (mounted) {
                                                  setState(() => _busy = false);
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (i < _members.length - 1) const Divider(),
                                ],
                              ],
                            ),
                    ),

                    // Invites Section (Owner Only)
                    PermissionGate(
                      permission: AppPermission.manageTeamAndInvites,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          AppHeading(
                            '${l10n.teamInvitesSection} (${_invites.length})',
                            level: AppHeadingLevel.h3,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppCard(
                            child: _invites.isEmpty
                                ? AppText(
                                    l10n.teamNoInvitesEmpty,
                                    variant: AppTextVariant.bodySmall,
                                  )
                                : Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < _invites.length;
                                        i++
                                      ) ...[
                                        AppActionRow(
                                          content: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              AppText(
                                                _invites[i].code,
                                                variant: AppTextVariant.numeric,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              AppText(
                                                '${_roleLabel(context, _invites[i].role)} • '
                                                '${IstDateTimeHelper.formatIstDateTime(_invites[i].expiresAtUtcMillis, locale: localeCode)}',
                                                variant:
                                                    AppTextVariant.bodySmall,
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            AppStatusBadge(
                                              label: _invites[i].status,
                                              tone: _invites[i].isPending
                                                  ? AppStatusTone.pending
                                                  : AppStatusTone.neutral,
                                            ),
                                            if (_invites[i].isPending) ...[
                                              AppIconButton(
                                                icon: AppIcons.copy,
                                                tooltip: l10n.slipCopyTextAction,
                                                onPressed: () async {
                                                  await Clipboard.setData(
                                                    ClipboardData(
                                                      text: _invites[i].code,
                                                    ),
                                                  );
                                                  if (context.mounted) {
                                                    AppFeedback.showSuccess(
                                                      context,
                                                      l10n.slipCopiedMessage,
                                                    );
                                                  }
                                                },
                                              ),
                                              AppIconButton(
                                                icon: AppIcons.share,
                                                tooltip: l10n
                                                    .teamShareInviteWhatsAppAction,
                                                onPressed: () =>
                                                    _shareInviteCode(
                                                      context,
                                                      _invites[i],
                                                    ),
                                              ),
                                              AppButton(
                                                label: l10n.teamRevokeAction,
                                                variant: AppButtonVariant.text,
                                                onPressed: () async {
                                                  await _repo.revokeInvite(
                                                    _invites[i].id,
                                                  );
                                                  await _load();
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (i < _invites.length - 1)
                                          const Divider(),
                                      ],
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
