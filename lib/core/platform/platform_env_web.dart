bool get isFlutterTestEnv => false;

bool get isAndroidPlatform => false;

Future<T> runComputeIsolate<T>(T Function() computation) async => computation();
