import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/business_profile/presentation/bloc/business_profile_cubit.dart';
import 'package:business_manager/features/business_profile/presentation/bloc/business_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

final class BusinessProfilePage extends StatelessWidget {
  const BusinessProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BusinessProfileCubit>(
      create: (_) => getIt<BusinessProfileCubit>()..loadProfile(),
      child: const _BusinessProfileView(),
    );
  }
}

final class _BusinessProfileView extends StatefulWidget {
  const _BusinessProfileView();

  @override
  State<_BusinessProfileView> createState() => _BusinessProfileViewState();
}

final class _BusinessProfileViewState extends State<_BusinessProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameGuController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  BillingMode _billingMode = BillingMode.receivedQty;
  bool _hydrated = false;

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameGuController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
    return BlocConsumer<BusinessProfileCubit, BusinessProfileState>(
      listener: (context, state) {
        if (state.profile != null) {
          _hydrateFrom(state.profile!);
        }
        if (state.status == BusinessProfileStatus.saved) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.businessProfileSaved)));
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
              child: ListView(
                padding: AppSpacing.screenAll,
                children: [
                  AppHeading(
                    l10n.businessProfileHeading,
                    level: AppHeadingLevel.h2,
                    subtitle: l10n.businessProfileSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _nameEnController,
                          label: l10n.businessNameEnLabel,
                          prefixIcon: Icons.storefront_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.validationRequired
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _nameGuController,
                          label: l10n.businessNameGuLabel,
                          prefixIcon: Icons.translate,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.validationRequired
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _ownerController,
                          label: l10n.businessOwnerLabel,
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _phoneController,
                          label: l10n.businessPhoneLabel,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _addressController,
                          label: l10n.businessAddressLabel,
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 3,
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
                            if (mode != null) {
                              setState(() => _billingMode = mode);
                            }
                          },
                          options: [
                            AppRadioOption(
                              value: BillingMode.receivedQty,
                              label: l10n.billingModeReceivedQty,
                            ),
                            AppRadioOption(
                              value: BillingMode.givenQty,
                              label: l10n.billingModeGivenQty,
                            ),
                          ],
                        ),
                        if (state.status == BusinessProfileStatus.error &&
                            state.errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppText(
                            state.errorMessage!,
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
  }
}
