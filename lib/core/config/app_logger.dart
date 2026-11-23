import 'dart:developer' as developer;

import 'package:business_manager/core/config/app_config.dart';
import 'package:injectable/injectable.dart';

/// Centralized logger that is strictly silenced in production builds.
@lazySingleton
final class AppLogger {
  AppLogger(this._config);

  final AppConfig _config;

  bool get isEnabled => _config.enableDebugLogs && _config.isDev;

  void debug(String message, {String name = 'BusinessManager'}) {
    if (!isEnabled) return;
    developer.log(message, name: name, level: 500);
  }

  void info(String message, {String name = 'BusinessManager'}) {
    if (!isEnabled) return;
    developer.log(message, name: name, level: 800);
  }

  void warning(
    String message, {
    String name = 'BusinessManager',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!isEnabled) return;
    developer.log(
      message,
      name: name,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(
    String message, {
    String name = 'BusinessManager',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!isEnabled) return;
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
