import 'dart:typed_data';

import 'package:business_manager/core/platform/web_browser_bridge.dart';
import 'package:business_manager/features/reports/data/services/android_report_print_channel.dart';

Future<String> deliverExportedBytes({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
  required Future<void> Function(Future<void> Function() action) runWithPicker,
}) async {
  downloadBytesInBrowser(Uint8List.fromList(bytes), fileName, mimeType);
  return 'browser://downloads/$fileName';
}

Future<bool> printReportHtmlPlatform({
  required String jobName,
  required String html,
  required AndroidReportPrintChannel androidPrintChannel,
  required Future<bool> Function(Future<bool> Function() action) runWithPicker,
}) async {
  return printHtmlInBrowser(html, jobName);
}
