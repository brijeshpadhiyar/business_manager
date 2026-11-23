import 'package:business_manager/features/security/domain/repositories/security_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Controls Android `WindowManager.LayoutParams.FLAG_SECURE` via `MainActivity`.
/// Gracefully no-ops on non-Android platforms and in widget tests.
@LazySingleton(as: WindowSecurityService)
final class MethodChannelWindowSecurityService
    implements WindowSecurityService {
  static const MethodChannel _channel = MethodChannel(
    'com.brijesh.stitchflow/window_security',
  );

  bool? _lastApplied;

  @override
  Future<void> setFlagSecure(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_lastApplied == enabled) return;
    try {
      await _channel.invokeMethod<bool>('setFlagSecure', {'enabled': enabled});
      _lastApplied = enabled;
    } on MissingPluginException {
      // Safe no-op in tests or unsupported runners.
    } on PlatformException {
      // Never crash UI on window flag error.
    }
  }
}
