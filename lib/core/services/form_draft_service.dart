import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only persistence for unfinished form drafts and remembered workshop
/// defaults (last-used Process ID, Payment Mode, dismissed Setup Checklist).
///
/// Zero database impact and 100% Web/Native compatible via [SharedPreferences].
@lazySingleton
final class FormDraftService {
  FormDraftService(this._prefs);

  final SharedPreferences _prefs;

  static const String _draftPrefix = 'stitchflow_form_draft_v1_';
  static const String _lastProcessKey = 'stitchflow_default_last_process_id';
  static const String _lastPaymentModeKey =
      'stitchflow_default_last_payment_mode';
  static const String _setupDismissedKey =
      'stitchflow_setup_checklist_dismissed';

  Future<void> saveDraft(String formKey, Map<String, Object?> payload) async {
    await _prefs.setString('$_draftPrefix$formKey', jsonEncode(payload));
  }

  Map<String, Object?>? readDraft(String formKey) {
    final raw = _prefs.getString('$_draftPrefix$formKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> clearDraft(String formKey) async {
    await _prefs.remove('$_draftPrefix$formKey');
  }

  String? get lastProcessId => _prefs.getString(_lastProcessKey);

  Future<void> setLastProcessId(String processId) =>
      _prefs.setString(_lastProcessKey, processId);

  String? get lastPaymentMode => _prefs.getString(_lastPaymentModeKey);

  Future<void> setLastPaymentMode(String paymentModeDbValue) =>
      _prefs.setString(_lastPaymentModeKey, paymentModeDbValue);

  bool get isSetupChecklistDismissed =>
      _prefs.getBool(_setupDismissedKey) ?? false;

  Future<void> setSetupChecklistDismissed(bool dismissed) =>
      _prefs.setBool(_setupDismissedKey, dismissed);
}
