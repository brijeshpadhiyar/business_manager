import 'dart:io';

import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/features/reports/data/services/android_report_print_channel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> deliverExportedBytes({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
  required Future<void> Function(Future<void> Function() action) runWithPicker,
}) async {
  final baseDir = isFlutterTestEnv
      ? Directory.systemTemp
      : await getTemporaryDirectory();
  final exportDir = Directory(p.join(baseDir.path, 'stitchflow_exports'));
  if (!exportDir.existsSync()) {
    await exportDir.create(recursive: true);
  }
  final outFile = File(p.join(exportDir.path, fileName));
  await outFile.writeAsBytes(bytes, flush: true);

  if (!isFlutterTestEnv) {
    await runWithPicker(
      () => SharePlus.instance.share(
        ShareParams(files: [XFile(outFile.path)], text: fileName),
      ),
    );
  }
  return outFile.path;
}

Future<bool> printReportHtmlPlatform({
  required String jobName,
  required String html,
  required AndroidReportPrintChannel androidPrintChannel,
  required Future<bool> Function(Future<bool> Function() action) runWithPicker,
}) {
  return runWithPicker(
    () => androidPrintChannel.printHtml(jobName: jobName, html: html),
  );
}
