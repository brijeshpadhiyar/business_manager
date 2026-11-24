import 'dart:io';
import 'dart:isolate';

bool get isFlutterTestEnv => Platform.environment.containsKey('FLUTTER_TEST');

bool get isAndroidPlatform => Platform.isAndroid;

Future<T> runComputeIsolate<T>(T Function() computation) =>
    Isolate.run(computation);
