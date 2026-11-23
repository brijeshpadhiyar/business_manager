/// Supported runtime environments for the application.
enum AppFlavor {
  dev,
  prod;

  bool get isDev => this == AppFlavor.dev;
  bool get isProd => this == AppFlavor.prod;
}
