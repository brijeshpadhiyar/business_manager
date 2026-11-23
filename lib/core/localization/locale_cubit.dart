import 'package:business_manager/core/localization/locale_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and locally persists the user's selected app language
/// (`System Default`, `English`, or `Gujarati`).
@lazySingleton
final class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit(this._prefs)
    : super(
        LocaleState(
          preference: AppLocalePreference.fromStorageKey(
            _prefs.getString(_localePreferenceKey),
          ),
        ),
      );

  static const String _localePreferenceKey = 'app_locale_preference';

  final SharedPreferences _prefs;

  Future<void> setPreference(AppLocalePreference preference) async {
    await _prefs.setString(_localePreferenceKey, preference.storageKey);
    emit(state.copyWith(preference: preference));
  }
}
