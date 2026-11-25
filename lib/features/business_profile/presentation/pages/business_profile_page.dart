import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/business_profile/presentation/bloc/business_profile_cubit.dart';
import 'package:business_manager/features/business_profile/presentation/bloc/business_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

final class BusinessProfilePage extends StatelessWidget {
  const BusinessProfilePage({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BusinessProfileCubit>(
      create: (_) => getIt<BusinessProfileCubit>()..loadProfile(),
      child: _BusinessProfileView(showAppBar: showAppBar),
    );
  }
}

final class _BusinessProfileView extends StatefulWidget {
  const _BusinessProfileView({required this.showAppBar});

  final bool showAppBar;

  @override
  State<_BusinessProfileView> createState() => _BusinessProfileViewState();
}

final class _BusinessProfileViewState extends State<_BusinessProfileView> {
  final _dirty = AppFormDirtyTracker();
  final _formKey = GlobalKey<FormState>();
  final _nameEnKey = GlobalKey<FormFieldState<String>>();
  final _nameGuKey = GlobalKey<FormFieldState<String>>();
  final _ownerKey = GlobalKey<FormFieldState<String>>();
  final _phoneKey = GlobalKey<FormFieldState<String>>();
  final _addressKey = GlobalKey<FormFieldState<String>>();

  final _nameEnController = TextEditingController();
  final _nameGuController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _nameEnFocus = FocusNode();
  final _nameGuFocus = FocusNode();
  final _ownerFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();

  BillingMode _billingMode = BillingMode.receivedQty;
  bool _hydrated = false;
  bool _submittedOnce = false;

  @override
  void dispose() {
    _dirty.dispose();
    _nameEnController.dispose();
    _nameGuController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nameEnFocus.dispose();
    _nameGuFocus.dispose();
    _ownerFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  void _hydrateFrom(BusinessProfileEntity profile) {
    if (_hydrated) return;
    _nameEnController.text = profile.nameEn;
    _nameGuController.text = profile.nameGu;
    _ownerController.text = profile.ownerName ?? '';
    _phoneController.text = profile.phone ?? '';
    _addressController.text = profile.address ?? '';
    _billingMode = profile.defaultBillingMode;
    _hydrated = true;
    // Loaded values are the saved state; edits from here on are unsaved.
    _dirty.watch([
      _nameEnController,
      _nameGuController,
      _ownerController,
      _phoneController,
      _addressController,
    ]);
  }

  Future<void> _submit() async {
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }
    final valid = FormValidationHelper.validateAndFocusFirstInvalid(
      formKey: _formKey,
      orderedAnchors: [
        ValidatedFieldAnchor(fieldKey: _nameEnKey, focusNode: _nameEnFocus),
        ValidatedFieldAnchor(fieldKey: _nameGuKey, focusNode: _nameGuFocus),
        ValidatedFieldAnchor(fieldKey: _ownerKey, focusNode: _ownerFocus),
        ValidatedFieldAnchor(fieldKey: _phoneKey, focusNode: _phoneFocus),
        ValidatedFieldAnchor(fieldKey: _addressKey, focusNode: _addressFocus),
      ],
    );
    if (!valid) return;
    await context.read<BusinessProfileCubit>().saveProfile(
      nameEn: _nameEnController.text,
      nameGu: _nameGuController.text,
      ownerName: _ownerController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      defaultBillingMode: _billingMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = BlocConsumer<BusinessProfileCubit, BusinessProfileState>(
      listener: (context, state) {
        if (state.profile != null) {
          _hydrateFrom(state.profile!);
        }
        if (state.status == BusinessProfileStatus.saved) {
          _dirty.reset();
          AppFeedback.showSuccess(context, l10n.businessProfileSaved);
        }
      },
      builder: (context, state) {
        if (state.status == BusinessProfileStatus.initial ||
            state.status == BusinessProfileStatus.loading) {
          return const AppLoader();
        }
        if (state.status == BusinessProfileStatus.error &&
            state.profile == null) {
          return AppErrorView(
            title: l10n.errorUnexpected,
            message: state.errorMessage,
            retryLabel: l10n.actionRetry,
            onRetry: () => context.read<BusinessProfileCubit>().loadProfile(),
          );
        }
        if (state.profile != null) {
          _hydrateFrom(state.profile!);
        }

        final isSaving = state.status == BusinessProfileStatus.saving;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizing.maxContentWidth,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _submittedOnce
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: AppSpacing.screenAll,
                children: [
                  if (!widget.showAppBar) ...[
                    AppHeading(
                      l10n.businessProfileHeading,
                      level: AppHeadingLevel.h2,
                      subtitle: l10n.businessProfileSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else ...[
                    AppText(
                      l10n.businessProfileSubtitle,
                      variant: AppTextVariant.bodySmall,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          fieldKey: _nameEnKey,
                          controller: _nameEnController,
                          focusNode: _nameEnFocus,
                          label: l10n.businessNameEnLabel,
                          prefixIcon: Icons.storefront_outlined,
                          textInputAction: TextInputAction.next,
                          maxLength: ValidationLimits.maxPersonNameLength,
                          validator: ValidationLocalizer.wrap(
                            l10n,
                            (v) => AppValidators.nameValidator(
                              v,
                              maxLength: ValidationLimits.maxPersonNameLength,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          fieldKey: _nameGuKey,
                          controller: _nameGuController,
                          focusNode: _nameGuFocus,
                          label: l10n.businessNameGuLabel,
                          prefixIcon: Icons.translate,
                          textInputAction: TextInputAction.next,
                          maxLength: ValidationLimits.maxPersonNameLength,
                          validator: ValidationLocalizer.wrap(
                            l10n,
                            (v) => AppValidators.nameValidator(
                              v,
                              maxLength: ValidationLimits.maxPersonNameLength,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          fieldKey: _ownerKey,
                          controller: _ownerController,
                          focusNode: _ownerFocus,
                          label: l10n.businessOwnerLabel,
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          maxLength: ValidationLimits.maxPersonNameLength,
                          validator: ValidationLocalizer.wrap(
                            l10n,
                            (v) => AppValidators.maxLengthValidator(
                              v,
                              maxLength: ValidationLimits.maxPersonNameLength,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          fieldKey: _phoneKey,
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          label: l10n.businessPhoneLabel,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: ValidationLocalizer.wrap(
                            l10n,
                            (v) => AppValidators.mobileNumberValidator(v),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          fieldKey: _addressKey,
                          controller: _addressController,
                          focusNode: _addressFocus,
                          label: l10n.businessAddressLabel,
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 3,
                          maxLength: ValidationLimits.maxAddressLength,
                          validator: ValidationLocalizer.wrap(
                            l10n,
                            (v) => AppValidators.maxLengthValidator(
                              v,
                              maxLength: ValidationLimits.maxAddressLength,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppText(
                          l10n.businessDefaultBillingLabel,
                          variant: AppTextVariant.label,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppRadio<BillingMode>(
                          groupValue: _billingMode,
                          onChanged: (mode) {
                            _dirty.markDirty();
                            if (mode != null) {
                              setState(() => _billingMode = mode);
                            }
                          },
                          options: [
                            AppRadioOption(
                              value: BillingMode.receivedQty,
                              label: l10n.billingModeReceivedQty,
                              subtitle:
                                  l10n.settingsGlobalBillingExplanationReceived,
                            ),
                            AppRadioOption(
                              value: BillingMode.givenQty,
                              label: l10n.billingModeGivenQty,
                              subtitle:
                                  l10n.settingsGlobalBillingExplanationGiven,
                            ),
                          ],
                        ),
                        if (state.status == BusinessProfileStatus.error &&
                            state.errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppText(
                            ValidationLocalizer.localizeDomainCode(
                              l10n,
                              state.errorMessage!,
                              fallback: state.errorMessage,
                            ),
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: l10n.actionSave,
                          icon: Icons.save_outlined,
                          isLoading: isSaving,
                          isExpanded: true,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.showAppBar) {
      return AppUnsavedChangesGuard.tracked(
        tracker: _dirty,
        child: AppScaffold(
          title: l10n.businessProfileHeading,
          contentWidth: AppContentWidth.narrow,
          padding: EdgeInsets.zero,
          constrainMaxWidth: false,
          body: body,
        ),
      );
    }
    return body;
  }
}
