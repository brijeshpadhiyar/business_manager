import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_state.freezed.dart';

/// Persisted user language preference options.
enum AppLocalePreference {
  system('system'),
  en('en'),
  gu('gu');

  const AppLocalePreference(this.storageKey);

  final String storageKey;

  Locale? get locale => switch (this) {
        AppLocalePreference.system => null,
        AppLocalePreference.en => const Locale('en'),
        AppLocalePreference.gu => const Locale('gu'),
      };

  static AppLocalePreference fromStorageKey(String? raw) {
    return AppLocalePreference.values.firstWhere(
      (value) => value.storageKey == raw,
      orElse: () => AppLocalePreference.system,
    );
  }
}

@freezed
sealed class LocaleState with _$LocaleState {
  const factory LocaleState({
    @Default(AppLocalePreference.system) AppLocalePreference preference,
  }) = _LocaleState;
}
