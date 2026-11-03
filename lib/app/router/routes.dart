abstract final class Routes {
  static const String feed = '/';
  static const String library = '/library';
  static const String gifIdParam = 'id';
  static const String gifDetailsPattern = '/gif/:$gifIdParam';

  static String gifDetails(String id) => '/gif/${Uri.encodeComponent(id)}';
}
