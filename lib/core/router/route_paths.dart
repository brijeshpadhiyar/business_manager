abstract final class RoutePaths {
  static const String home = '/';
  static const String showcase = '/showcase';
  static const String lotDetailPattern = '/lots/:id';

  static String lotDetail(String lotId) => '/lots/$lotId';
}
