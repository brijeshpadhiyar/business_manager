import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Thin MethodChannel client for native Android `WebView` + `PrintManager`
/// Gujarati-accurate offline PDF/Print rendering.
@lazySingleton
final class AndroidReportPrintChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.brijesh.stitchflow/report_print',
  );

  Future<bool> printHtml({
    required String jobName,
    required String html,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('printHtml', {
        'jobName': jobName,
        'html': html,
      });
      return ok ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
