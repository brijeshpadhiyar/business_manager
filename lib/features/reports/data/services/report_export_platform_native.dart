import 'dart:io';
import 'dart:typed_data';

import 'package:business_manager/core/platform/share_origin.dart';
import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/features/reports/data/services/android_report_print_channel.dart';
import 'package:file_picker/file_picker.dart';
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
    if (isDesktopPlatform) {
      // Desktop: a normal "Save as" dialog instead of a phone share sheet.
      String savedPath = outFile.path;
      await runWithPicker(() async {
        final uri = await FilePicker.saveFile(
          fileName: fileName,
          bytes: Uint8List.fromList(bytes),
          mimeType: mimeType,
        );
        if (uri != null && uri.scheme == 'file') {
          savedPath = uri.toFilePath();
        }
      });
      return savedPath;
    }
    await runWithPicker(
      () => SharePlus.instance.share(
        ShareParams(
          files: [XFile(outFile.path)],
          text: fileName,
          sharePositionOrigin: defaultShareOrigin(),
        ),
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
}) async {
  if (isDesktopPlatform && !isFlutterTestEnv) {
    // Desktop: open the report in the default browser, where Ctrl+P prints
    // it or saves it as PDF.
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'stitchflow_exports'),
    );
    if (!dir.existsSync()) await dir.create(recursive: true);
    final file = File(p.join(dir.path, '$jobName.html'));
    await file.writeAsString(html, flush: true);
    return openWithDefaultApp(file.path);
  }
  return runWithPicker(
    () => androidPrintChannel.printHtml(jobName: jobName, html: html),
  );
}
