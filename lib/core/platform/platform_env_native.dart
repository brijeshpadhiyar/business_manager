import 'dart:io';
import 'dart:isolate';

bool get isFlutterTestEnv => Platform.environment.containsKey('FLUTTER_TEST');

bool get isAndroidPlatform => Platform.isAndroid;

/// Windows, macOS or Linux desktop build.
bool get isDesktopPlatform =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

/// Whether the image picker can open a camera here. Desktop builds have no
/// camera capture in `image_picker`, so the "Take photo" action is hidden.
bool get supportsCameraCapture => Platform.isAndroid || Platform.isIOS;

/// Opens [path] with the user's default app (e.g. an HTML report in the
/// browser). Desktop only; returns false elsewhere or on failure.
Future<bool> openWithDefaultApp(String path) async {
  try {
    if (Platform.isWindows) {
      await Process.start('explorer.exe', [path]);
      return true;
    }
    if (Platform.isMacOS) {
      await Process.start('open', [path]);
      return true;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [path]);
      return true;
    }
  } catch (_) {
    return false;
  }
  return false;
}

Future<T> runComputeIsolate<T>(T Function() computation) =>
    Isolate.run(computation);
