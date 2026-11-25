bool get isFlutterTestEnv => false;

bool get isAndroidPlatform => false;

bool get isDesktopPlatform => false;

/// Mobile browsers open the camera through the file input.
bool get supportsCameraCapture => true;

Future<bool> openWithDefaultApp(String path) async => false;

Future<T> runComputeIsolate<T>(T Function() computation) async => computation();
