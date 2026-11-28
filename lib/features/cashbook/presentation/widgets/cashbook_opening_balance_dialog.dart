import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Owner-only dialog for setting initial Cash Drawer and Bank/UPI balances.
final class CashbookOpeningBalanceDialog {
  static Future<({int openingCashPaise, int openingBankPaise})?> show(
    BuildContext context, {
    required int initialCashPaise,
    required int initialBankPaise,
  }) async {
    final l10n = context.l10n;
    final cashCtrl = TextEditingController(
      text: MoneyFormatter.formatPaiseForInput(initialCashPaise),
    );
    final bankCtrl = TextEditingController(
      text: MoneyFormatter.formatPaiseForInput(initialBankPaise),
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await AppDialog.showCustom<bool>(
      context,
      builder: (dialogCtx) => AppDialog(
        title: l10n.cashbookOpeningBalanceAction,
        confirmLabel: l10n.actionSave,
        cancelLabel: l10n.actionCancel,
        onConfirm: () {
          if (formKey.currentState?.validate() ?? false) {
            Navigator.of(dialogCtx).pop(true);
          }
        },
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                l10n.cashbookOpeningBalanceHelper,
                variant: AppTextVariant.bodySmall,
              ),
              const AppGap.sm(),
              AppTextField(
                controller: cashCtrl,
                label: l10n.cashbookOpeningCashLabel,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AppInputFormatters.currencyDecimal],
                validator: (v) => ValidationLocalizer.localize(
                  l10n,
                  AppValidators.nonNegativeAmountValidator(v),
                ),
              ),
              const AppGap.sm(),
              AppTextField(
                controller: bankCtrl,
                label: l10n.cashbookOpeningBankLabel,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AppInputFormatters.currencyDecimal],
                validator: (v) => ValidationLocalizer.localize(
                  l10n,
                  AppValidators.nonNegativeAmountValidator(v),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final cash =
        AppValidators.parseRupeesToPaiseExact(
          cashCtrl.text,
          isRequired: false,
          allowZero: true,
        ).paise ??
        0;
    final bank =
        AppValidators.parseRupeesToPaiseExact(
          bankCtrl.text,
          isRequired: false,
          allowZero: true,
        ).paise ??
        0;
    cashCtrl.dispose();
    bankCtrl.dispose();

    if (confirmed != true) return null;
    return (openingCashPaise: cash, openingBankPaise: bank);
  }
}
